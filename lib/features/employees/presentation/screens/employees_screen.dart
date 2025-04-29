import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rehabilitation_center_app/features/employees/presentation/bloc/employee_bloc.dart';
import 'package:rehabilitation_center_app/features/employees/domain/employee.dart';

// TODO: Импортировать сервис локатор или провайдеры для зависимостей
// import 'package:rehabilitation_center_app/injection_container.dart'; 

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сотрудники'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить сотрудника',
            onPressed: () {
              // Показываем диалог добавления
              _showAddEmployeeDialog(context);
            },
          ),
        ],
      ),
      body: BlocConsumer<EmployeeBloc, EmployeeState>(
        listener: (context, state) {
          if (state is EmployeeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка: ${state.message}')),
            );
          }
          if (state is EmployeeOperationSuccess) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is EmployeeInitial) {
             // Запрашиваем загрузку данных
            context.read<EmployeeBloc>().add(LoadEmployees());
             // Показываем индикатор, пока идет переход к EmployeeLoading
             return const Center(child: CircularProgressIndicator());
           }
          if (state is EmployeeLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is EmployeeLoaded) {
            if (state.employees.isEmpty) {
              return const Center(child: Text('Нет сотрудников для отображения.'));
            }
            return ListView.builder(
              itemCount: state.employees.length,
              itemBuilder: (context, index) {
                final employee = state.employees[index];
                return ListTile(
                  title: Text(employee.fullName),
                  subtitle: Text(employee.position),
                  // TODO: Добавить кнопки редактирования и удаления
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Редактировать',
                        onPressed: () {
                          // Вызываем тот же диалог, но передаем текущего сотрудника
                          _showAddEmployeeDialog(context, employee: employee);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Удалить',
                        onPressed: () async { // Делаем обработчик асинхронным
                          // Показываем диалог подтверждения
                          final confirm = await _showDeleteConfirmationDialog(context, employee);
                          if (confirm == true) {
                             // Если подтверждено, отправляем событие на удаление
                             context.read<EmployeeBloc>().add(DeleteEmployeeEvent(employee.id));
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                     // TODO: Возможно, переход на детальную карточку сотрудника
                     print('Tapped on employee: ${employee.id}');
                  },
                );
              },
            );
          }
          // Состояние EmployeeError обрабатывается в listener, но можно показать и здесь
          // if (state is EmployeeError) {
          //   return Center(child: Text('Ошибка: ${state.message}'));
          // }
          return const Center(child: Text('Неизвестное состояние')); // Или EmployeeInitial
        },
      ),
    );
  }

  // Функция для показа диалога добавления/редактирования сотрудника
  Future<void> _showAddEmployeeDialog(BuildContext context, {Employee? employee}) async { // Добавляем необязательный параметр
    final bloc = context.read<EmployeeBloc>(); // Получаем BLoC
    final formKey = GlobalKey<FormState>();
    // Определяем, это добавление или редактирование
    final bool isEditing = employee != null;

    final fullNameController = TextEditingController();
    final positionController = TextEditingController();

    // Если редактируем, инициализируем контроллеры
    if (isEditing) { 
      fullNameController.text = employee.fullName;
      positionController.text = employee.position;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Диалог нужно закрывать кнопками
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Редактировать сотрудника' : 'Добавить сотрудника'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    controller: fullNameController,
                    decoration: const InputDecoration(labelText: 'ФИО'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Пожалуйста, введите ФИО';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: positionController,
                    decoration: const InputDecoration(labelText: 'Должность'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Пожалуйста, введите должность';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Закрыть диалог
              },
            ),
            TextButton(
              child: Text(isEditing ? 'Обновить' : 'Сохранить'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  if (isEditing) {
                    // Обновляем существующего сотрудника
                    final updatedEmployee = Employee(
                      id: employee.id, // Используем существующий ID
                      fullName: fullNameController.text.trim(),
                      position: positionController.text.trim(),
                    );
                    bloc.add(UpdateEmployeeEvent(updatedEmployee));
                  } else {
                    // Создаем нового сотрудника
                    final newEmployee = Employee(
                      id: 0, // id не важен при добавлении
                      fullName: fullNameController.text.trim(),
                      position: positionController.text.trim(),
                    );
                    bloc.add(AddEmployeeEvent(newEmployee));
                  }
                  Navigator.of(dialogContext).pop(); // Закрыть диалог
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Диалог подтверждения удаления
  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, Employee employee) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Подтверждение удаления'),
          content: Text('Вы уверены, что хотите удалить сотрудника "${employee.fullName}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // Возвращаем false при отмене
              },
            ),
            TextButton(
              // Стилизуем кнопку для акцента
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Удалить'),
              onPressed: () {
                 Navigator.of(dialogContext).pop(true); // Возвращаем true при подтверждении
              },
            ),
          ],
        );
      },
    );
  }
}
