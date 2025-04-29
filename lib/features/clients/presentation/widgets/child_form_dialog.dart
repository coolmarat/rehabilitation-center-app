import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rehabilitation_center_app/features/clients/domain/child.dart';
import 'package:rehabilitation_center_app/features/clients/presentation/bloc/client_bloc.dart';

class ChildFormDialog extends StatefulWidget {
  final int parentId; // ID родителя, к которому добавляем/редактируем ребенка
  final Child? child; // null для добавления, не null для редактирования

  const ChildFormDialog({Key? key, required this.parentId, this.child})
      : super(key: key);

  @override
  State<ChildFormDialog> createState() => _ChildFormDialogState();
}

class _ChildFormDialogState extends State<ChildFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dobController; // Для отображения даты
  late TextEditingController _diagnosisController;
  DateTime? _selectedDate;

  bool get _isEditing => widget.child != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child?.fullName ?? '');
    _selectedDate = widget.child?.dateOfBirth;
    _dobController = TextEditingController(
        text: _selectedDate != null
            ? DateFormat('dd.MM.yyyy').format(_selectedDate!)
            : '');
    _diagnosisController =
        TextEditingController(text: widget.child?.diagnosis ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _diagnosisController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('ru', 'RU'), // Установка русской локали для пикера
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd.MM.yyyy').format(_selectedDate!);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        // Показываем ошибку, если дата не выбрана
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пожалуйста, выберите дату рождения')),
        );
        return;
      }

      final childData = Child(
        id: widget.child?.id ?? 0, // 0 для нового ребенка
        parentId: widget.parentId,
        fullName: _nameController.text,
        dateOfBirth: _selectedDate!,
        diagnosis: _diagnosisController.text.isNotEmpty
            ? _diagnosisController.text
            : null,
      );

      if (_isEditing) {
        context.read<ClientBloc>().add(UpdateChildRequested(childData));
      } else {
        context.read<ClientBloc>().add(AddChildRequested(childData));
      }
      Navigator.of(context).pop(); // Закрыть диалог
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Редактировать ребенка' : 'Добавить ребенка'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'ФИО *'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите ФИО';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(
                  labelText: 'Дата рождения *',
                  hintText: 'Выберите дату',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true, // Запрещаем ручной ввод
                onTap: () => _selectDate(context), // Показываем DatePicker по тапу
                validator: (value) {
                  if (_selectedDate == null) {
                    return 'Пожалуйста, выберите дату';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _diagnosisController,
                decoration: const InputDecoration(labelText: 'Диагноз (опционально)'),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Отмена'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text(_isEditing ? 'Сохранить' : 'Добавить'),
          onPressed: _submitForm,
        ),
      ],
    );
  }
}

// Вспомогательная функция для показа диалога
Future<void> showChildFormDialog(BuildContext context,
    {required int parentId, Child? child}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      // Передаем ClientBloc из родительского контекста
      return BlocProvider.value(
        value: BlocProvider.of<ClientBloc>(context),
        child: ChildFormDialog(parentId: parentId, child: child),
      );
    },
  );
}
