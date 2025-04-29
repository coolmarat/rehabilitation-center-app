import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart'; // Assuming you use Provider for state management/DI
import 'package:csv/csv.dart'; // For CSV generation
import 'package:file_picker/file_picker.dart'; // For save file dialog
import 'dart:io'; // For File operations

import '../../../core/database/app_database.dart';

class FinanceReportScreen extends StatefulWidget {
  const FinanceReportScreen({super.key});

  @override
  State<FinanceReportScreen> createState() => _FinanceReportScreenState();
}

class _FinanceReportScreenState extends State<FinanceReportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  EmployeeEntry? _selectedEmployee;
  List<EmployeeEntry> _employees = [];
  List<FinanceReportResult> _reportResults = [];
  bool _isLoading = false;
  bool _isLoadingEmployees = true; // Loading state for employees
  final EmployeeEntry _allEmployeesOption = EmployeeEntry(id: -1, fullName: 'Все', position: ''); // Dummy entry for 'All'

  late AppDatabase _db;

  @override
  void initState() {
    super.initState();
    // Assuming AppDatabase is accessible via Provider
    _db = Provider.of<AppDatabase>(context, listen: false);
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final fetchedEmployees = await _db.getAllEmployees();
      setState(() {
        _employees = [_allEmployeesOption, ...fetchedEmployees]; // Add 'All' option
        _selectedEmployee = _allEmployeesOption; // Default to 'All'
        _isLoadingEmployees = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEmployees = false;
      });
      // Handle error loading employees (e.g., show a snackbar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки сотрудников: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          // Set endDate to the very end of the selected day
          _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  Future<void> _generateReport() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите даты начала и окончания.')),
      );
      return;
    }
    if (_startDate!.isAfter(_endDate!)) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Дата начала не может быть позже даты окончания.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _reportResults = []; // Clear previous results
    });

    try {
      final results = await _db.getFinanceReport(
        start: _startDate!,
        end: _endDate!,
        // Pass null if 'All' is selected, otherwise pass the employee ID
        employeeId: _selectedEmployee?.id == _allEmployeesOption.id ? null : _selectedEmployee?.id,
      );
      setState(() {
        _reportResults = results;
      });
    } catch (e) {
      // Handle error generating report
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка генерации отчета: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportToCsv() async {
    if (_reportResults.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет данных для экспорта.')),
      );
      return;
    }

    List<List<dynamic>> rows = [];
    // Add header row
    rows.add(['Сотрудник', 'Сумма (руб.)']);
    // Add data rows
    for (var result in _reportResults) {
      rows.add([result.employeeName, result.totalAmount]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    try {
      // Suggest a filename
      final DateFormat formatter = DateFormat('yyyyMMdd');
      final String startDateStr = _startDate != null ? formatter.format(_startDate!) : 'nodate';
      final String endDateStr = _endDate != null ? formatter.format(_endDate!) : 'nodate';
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить отчет как CSV',
        fileName: 'finance_report_${startDateStr}_to_$endDateStr.csv',
        allowedExtensions: ['csv'],
        type: FileType.custom,
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(csvData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Отчет успешно сохранен в $outputFile')),
        );
      } else {
        // User canceled the picker
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Экспорт отменен.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка экспорта в CSV: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format dates for display, handle nulls
    final DateFormat formatter = DateFormat('dd.MM.yyyy');
    final String startDateText = _startDate == null ? 'Не выбрана' : formatter.format(_startDate!);
    final String endDateText = _endDate == null ? 'Не выбрана' : formatter.format(_endDate!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Финансовый отчет'),
        actions: [
          // Add Export Button here
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Экспорт в CSV',
            // Disable button if there are no results or currently loading
            onPressed: _reportResults.isNotEmpty && !_isLoading ? _exportToCsv : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Pickers
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Дата начала',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(startDateText),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Дата окончания',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(endDateText),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Employee Dropdown
            if (_isLoadingEmployees)
              const Center(child: CircularProgressIndicator())
            else if (_employees.isNotEmpty)
              DropdownButtonFormField<EmployeeEntry>(
                value: _selectedEmployee,
                decoration: const InputDecoration(
                  labelText: 'Сотрудник',
                  border: OutlineInputBorder(),
                ),
                items: _employees.map((EmployeeEntry employee) {
                  return DropdownMenuItem<EmployeeEntry>(
                    value: employee,
                    child: Text(employee.fullName),
                  );
                }).toList(),
                onChanged: (EmployeeEntry? newValue) {
                  setState(() {
                    _selectedEmployee = newValue;
                  });
                },
                // Handle potential null value if list is somehow empty after loading
                // Although the logic tries to prevent this
                isExpanded: true,
              )
            else
              const Text('Нет доступных сотрудников.'), // Or some other placeholder

            const SizedBox(height: 20),

            // Generate Button
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateReport,
                child: _isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Сформировать отчет'),
              ),
            ),
            const SizedBox(height: 20),

            // Report Results
            const Text('Результаты:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _reportResults.isEmpty
                      ? const Center(child: Text('Нет данных для отображения.'))
                      : ListView.builder(
                          itemCount: _reportResults.length,
                          itemBuilder: (context, index) {
                            final result = _reportResults[index];
                            return ListTile(
                              title: Text(result.employeeName),
                              trailing: Text('${result.totalAmount.toStringAsFixed(2)} руб.'),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
