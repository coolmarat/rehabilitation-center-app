// Экран расписания

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Для форматирования дат
// Use the correct path for ActivityType

import 'package:rehabilitation_center_app/features/activity_types/domain/activity_type.dart';
import 'package:rehabilitation_center_app/features/clients/domain/child.dart';
import 'package:rehabilitation_center_app/features/employees/domain/employee.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/session_model.dart'; // <-- Re-import domain Session
// Example imports for BLoCs - replace with your actual BLoC paths and names
import 'package:rehabilitation_center_app/features/employees/presentation/bloc/employee_bloc.dart';
import 'package:rehabilitation_center_app/features/clients/presentation/bloc/client_bloc.dart';
import 'package:table_calendar/table_calendar.dart'; // <-- Correct import
import 'package:rehabilitation_center_app/shared_widgets/filterable_dropdown.dart'; // For filter dropdowns

// import '../../../../core/models/models.dart'; // <-- Removed, use specific domain models
import '../../domain/entities/session_details.dart'; // For SessionDetails
import '../bloc/schedule_bloc.dart'; // <-- Keep only main BLoC import

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<SessionDetails> _sessions =
      []; // Добавляем переменную для хранения сессий

  // Filter state variables
  Employee? _selectedEmployee;
  Child? _selectedChild;
  List<Employee> _allEmployees = [];
  List<Child> _allChildren = [];
  bool _isLoadingEmployees = true;
  bool _isLoadingClients = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Загрузка сессий для начального дня (уже делается в main.dart при создании Bloc)
    // BlocProvider.of<ScheduleBloc>(context).add(LoadSessionsForDay(_focusedDay));

    // Fetch data for filters
    // Ensure EmployeesBloc and ClientsBloc are provided above this widget in the tree
    // And that they have appropriate events (e.g., LoadAllEmployeesEvent, LoadAllClientsEvent)
    // and states (e.g., EmployeesLoaded, ClientsLoaded)
    context.read<EmployeeBloc>().add(LoadEmployees()); // Replace with your actual event
    context.read<ClientBloc>().add(LoadClients());       // Replace with your actual event
  }

  // Метод для получения сессий для конкретного дня
  List<SessionDetails> _getSessionsForDay(DateTime day) {
    final state = BlocProvider.of<ScheduleBloc>(context).state;
    if (state is ScheduleLoaded) {
      List<SessionDetails> sessionsForDay = state.allSessionsInView.where((session) {
        return isSameDay(session.dateTime, day);
      }).toList();

      // Apply employee filter if an employee is selected
      if (_selectedEmployee != null) {
        sessionsForDay = sessionsForDay.where((session) {
          return session.employeeId == _selectedEmployee!.id; // Ensure your SessionDetails has employeeId and Employee has id
        }).toList();
      }

      // Apply child filter if a child is selected
      if (_selectedChild != null) {
        sessionsForDay = sessionsForDay.where((session) {
          return session.childId == _selectedChild!.id; // Ensure your SessionDetails has childId and Child has id
        }).toList();
      }
      
      return sessionsForDay;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Расписание'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить сессию',
            onPressed: () {
              _showAddSessionDialog(context, _selectedDay ?? DateTime.now());
            },
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<EmployeeBloc, EmployeeState>(
            listener: (context, state) {
              if (state is EmployeeLoading) {
                setState(() {
                  _isLoadingEmployees = true;
                });
              } else if (state is EmployeeLoaded) {
                setState(() {
                  _isLoadingEmployees = false;
                  _allEmployees = state.employees;
                });
              } else if (state is EmployeeError) {
                setState(() {
                  _isLoadingEmployees = false;
                  // Optionally, show an error message to the user
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                });
              }
            },
          ),
          BlocListener<ClientBloc, ClientState>(
            listener: (context, state) {
              if (state.status == ClientStatus.loading) {
                setState(() {
                  _isLoadingClients = true;
                });
              } else if (state.status == ClientStatus.success) {
                setState(() {
                  _isLoadingClients = false;
                  _allChildren = state.parentsWithChildren.values.expand((children) => children).toList();
                });
              } else if (state.status == ClientStatus.failure) {
                setState(() {
                  _isLoadingClients = false;
                  // Optionally, show an error message to the user
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.errorMessage ?? 'Неизвестная ошибка при загрузке клиентов')),
                  );
                });
              }
            },
          ),
        ],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
          children: [
            // Left Column: Calendar and Filters
            Expanded(
              child: Column(
                children: [
                  // Calendar Widget
                  BlocBuilder<ScheduleBloc, ScheduleState>(
                    // Build the calendar only once, it doesn't need to rebuild on every state change
                    // unless the selected/focused day logic depends heavily on the state itself.
                    // For now, let's keep it simple.
                    buildWhen:
                        (previous, current) =>
                            previous.runtimeType !=
                            current
                                .runtimeType, // Rebuild only on state type change if needed
                    builder: (context, state) {
                      // Use state.selectedDate if available, otherwise fallback to local state
                      final currentSelectedDay =
                          state is ScheduleLoaded
                              ? state.selectedDate
                              : _selectedDay;
                      final currentFocusedDay =
                          state is ScheduleLoaded
                              ? state.selectedDate
                              : _focusedDay; // Or keep _focusedDay

                      return TableCalendar(
                        locale: 'ru_RU', // Set locale if needed
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay:
                            currentFocusedDay, // Use state's date or local _focusedDay
                        selectedDayPredicate: (day) {
                          // Use `isSameDay` to ignore time portion for selection
                          return isSameDay(currentSelectedDay, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          if (!isSameDay(_selectedDay, selectedDay)) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                              // Update _sessions immediately for the new day with current filters
                              _sessions = _getSessionsForDay(selectedDay);
                            });
                            // Trigger loading sessions for the newly selected day from the source
                            BlocProvider.of<ScheduleBloc>(
                              context,
                            ).add(LoadSessionsForDay(selectedDay));
                          }
                        },
                        calendarFormat: CalendarFormat.month, // Or week, twoWeeks
                        onPageChanged: (focusedDay) {
                          // No need to call `setState()` here, `focusedDay` is handled internally
                          // You might want to load data if your logic requires pre-fetching for pages
                          _focusedDay =
                              focusedDay; // Keep track of focused day if needed elsewhere
                        },
                        // Add other customizations as needed (header style, day builders, etc.)
                        headerStyle: HeaderStyle(
                          formatButtonVisible:
                              false, // Hide format button if you only want month view
                          titleCentered: true,
                        ),
                        calendarStyle: CalendarStyle(
                          // Highlight today's date
                          todayDecoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          // Highlight selected date
                          selectedDecoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Add markers for sessions
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, day, events) {
                            // 'events' here is the list of sessions for the day
                            if (events.isNotEmpty) {
                              return Positioned(
                                right: 1,
                                bottom: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                  width: 16.0,
                                  height: 16.0,
                                  child: Center(
                                    child: Text(
                                      '${events.length}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall!.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSecondary,
                                        fontSize: 10.0,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                        eventLoader:
                            _getSessionsForDay, // Use the new method here
                      );
                    },
                  ),
                  const Divider(), // Separator between calendar and filters
                  // Filters Area
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Фильтры:', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12.0),
                        // Employee Filter
                        Text('Специалист:', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8.0),
                        _isLoadingEmployees
                            ? const Center(child: CircularProgressIndicator())
                            : FilterableDropdown<Employee>(
                              hintText: 'Выберите специалиста',
                              items: _allEmployees,
                              initialItem: _selectedEmployee,
                              getName: (Employee employee) => employee.fullName,
                              getId: (Employee employee) => employee.id,
                              handleSelected: (Employee selectedEmployee) {
                                setState(() {
                                  _selectedEmployee = selectedEmployee;
                                  if (_selectedDay != null) {
                                    _sessions = _getSessionsForDay(_selectedDay!);
                                  }
                                });
                              },
                              onClearSelected: () {
                                setState(() {
                                  _selectedEmployee = null;
                                  if (_selectedDay != null) {
                                    _sessions = _getSessionsForDay(_selectedDay!);
                                  }
                                });
                              },
                            ),
                        // Child Filter
                        Text('Клиент (ребенок):', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8.0),
                        _isLoadingClients
                            ? const Center(child: CircularProgressIndicator())
                            : FilterableDropdown<Child>(
                              hintText: 'Выберите ребенка',
                              items: _allChildren,
                              initialItem: _selectedChild,
                              getName: (Child child) => child.fullName,
                              getId: (Child child) => child.id,
                              handleSelected: (Child selectedChild) {
                                setState(() {
                                  _selectedChild = selectedChild;
                                  if (_selectedDay != null) {
                                    _sessions = _getSessionsForDay(_selectedDay!);
                                  }
                                });
                              },
                              onClearSelected: () {
                                setState(() {
                                  _selectedChild = null;
                                  if (_selectedDay != null) {
                                    _sessions = _getSessionsForDay(_selectedDay!);
                                  }
                                });
                              },
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1), // Separator between columns
            // Right Column: Session List Area
            Expanded(
              // Use Expanded to take remaining space
              child: BlocBuilder<ScheduleBloc, ScheduleState>(
                builder: (context, state) {
                  // _sessions is now managed by _onDaySelected and filter changes.
                  // This BlocBuilder ensures UI rebuilds on ScheduleBloc state changes.

                  if (state is ScheduleLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (_sessions.isEmpty) {
                    // Если сохраненный список сессий пуст (и не в состоянии загрузки)
                    return const Center(
                      child: Text('Нет записей на выбранный день.'),
                    );
                  }
                  // Build the list of sessions using the saved list
                  return ListView.builder(
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      // TODO: Replace with a proper SessionListTile widget
                      return ListTile(
                        title: Text(
                          '${DateFormat('HH:mm').format(session.dateTime)} - ${session.activityTypeName}',
                        ),
                        subtitle: Text(
                          'Клиент: ${session.childName}, Специалист: ${session.employeeName}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${session.duration.inMinutes} мин'),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              tooltip: 'Удалить сессию',
                              onPressed: () {
                                _showDeleteConfirmationDialog(
                                  context,
                                  session.sessionId,
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          // Add null check for _selectedDay
                          if (_selectedDay != null) {
                            _showEditSessionDialog(
                              context,
                              session,
                              _selectedDay!,
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Метод для показа диалога добавления сессии
  void _showAddSessionDialog(BuildContext context, DateTime selectedDate) {
    // Важно! Получаем Bloc из исходного context перед вызовом showDialog
    final scheduleBloc = BlocProvider.of<ScheduleBloc>(context);
    // Загружаем данные для формы перед показом диалога
    scheduleBloc.add(LoadScheduleFormData());

    showDialog(
      context: context,
      // Не позволяем закрыть диалог нажатием вне его во время загрузки/добавления
      barrierDismissible: false, // Начнем с false, будем обновлять в listener
      builder: (_) {
        // Используем новый context для builder
        // Передаем существующий Bloc в поддерево диалога
        return BlocProvider.value(
          value: scheduleBloc,
          // Используем BlocListener для обработки состояний (успех/ошибка добавления)
          child: BlocListener<ScheduleBloc, ScheduleState>(
            listener: (dialogContext, state) {
              if (state is ScheduleAddSuccess) {
                Navigator.of(
                  dialogContext,
                ).pop(); // Закрываем диалог при успехе
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Сессия успешно добавлена!'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Список сессий обновится автоматически т.к. ScheduleBloc перейдет в ScheduleLoaded
              } else if (state is ScheduleError &&
                  state.message.contains('добавления')) {
                // Показываем ошибку только если она связана с добавлением
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка добавления: ${state.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
                // Оставляем диалог открытым, чтобы пользователь мог исправить данные
              } else if (state is ScheduleRecurringConflict) {
                // Показываем диалог с конфликтами
                Navigator.of(
                  dialogContext,
                ).pop(); // Close the add session dialog
                _showConflictDialog(
                  context,
                  state.conflictingDates,
                ); // Show conflict dialog
              }
              // TODO: Можно добавить обновление barrierDismissible здесь, если нужно
            },
            // Передаем выбранную дату в сам виджет диалога
            child: _AddSessionDialogContent(selectedDate: selectedDate),
          ),
        );
      },
    );
  }

  // Метод для показа диалога с конфликтами
  void _showConflictDialog(
    BuildContext context,
    List<DateTime> conflictingDates,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Найдены пересечения в расписании'),
          content: SingleChildScrollView(
            child: ListBody(
              children:
                  conflictingDates
                      .map(
                        (date) =>
                            Text(DateFormat('dd.MM.yyyy HH:mm').format(date)),
                      )
                      .toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ОК'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Закрыть диалог
              },
            ),
          ],
        );
      },
    );
  }

  // Метод для показа диалога подтверждения удаления
  void _showDeleteConfirmationDialog(BuildContext context, int sessionId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Подтвердить удаление'),
          content: const Text('Вы уверены, что хотите удалить эту сессию?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Закрыть диалог
              },
            ),
            TextButton(
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
              onPressed: () {
                // Отправляем событие удаления в Bloc
                BlocProvider.of<ScheduleBloc>(
                  context,
                ).add(DeleteExistingSession(sessionId));
                Navigator.of(dialogContext).pop(); // Закрыть диалог
              },
            ),
          ],
        );
      },
    );
  }

  // Метод для показа диалога/экрана редактирования сессии
  void _showEditSessionDialog(
    BuildContext context,
    SessionDetails session,
    DateTime selectedDate,
  ) {
    final scheduleBloc = BlocProvider.of<ScheduleBloc>(context);
    // Загружаем данные для формы, если они еще не загружены
    // (Обычно для редактирования они уже есть из ScheduleLoaded, но на всякий случай)
    if (scheduleBloc.state is! ScheduleFormDataLoaded &&
        scheduleBloc.state is! ScheduleFormDataLoading) {
      scheduleBloc.add(LoadScheduleFormData());
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Начнем с false
      builder: (_) {
        // Используем новый context для builder
        // Передаем существующий Bloc в поддерево диалога
        return BlocProvider.value(
          value: scheduleBloc,
          child: BlocListener<ScheduleBloc, ScheduleState>(
            listener: (dialogContext, state) {
              if (state is ScheduleUpdateSuccess) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Сессия успешно обновлена!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is ScheduleError &&
                  state.message.contains('обновления')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка обновления: ${state.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              // Можно добавить обновление barrierDismissible здесь, если нужно
            },
            // Передаем данные редактируемой сессии и выбранную дату
            child: _EditSessionDialogContent(
              session: session,
              selectedDate: selectedDate,
            ),
          ),
        );
      },
    );
  }
}

// <<<=== Диалог ДОБАВЛЕНИЯ сессии ===>>>

// Виджет для содержимого диалога добавления сессии
class _AddSessionDialogContent extends StatefulWidget {
  final DateTime selectedDate;

  const _AddSessionDialogContent({required this.selectedDate});

  @override
  State<_AddSessionDialogContent> createState() =>
      _AddSessionDialogContentState();
}

class _AddSessionDialogContentState extends State<_AddSessionDialogContent> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedEmployeeId;
  int? _selectedActivityTypeId;
  int? _selectedChildId;
  TimeOfDay? _selectedTime;
  final _priceController = TextEditingController();
  bool _isRecurring = false; // Добавляем флаг периодического занятия
  final _numberOfSessionsController =
      TextEditingController(); // Контроллер для количества занятий

  @override
  void initState() {
    super.initState();
    // Устанавливаем начальное время (например, 9:00)
    _selectedTime = const TimeOfDay(hour: 9, minute: 0);
    _numberOfSessionsController.text = '1'; // Значение по умолчанию
  }

  @override
  void dispose() {
    _priceController.dispose();
    _numberOfSessionsController.dispose(); // Освобождаем контроллер
    super.dispose();
  }

  // Метод для выбора времени
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить сессию'),
      // Делаем контент прокручиваемым на случай маленьких экранов
      content: SingleChildScrollView(
        child: BlocBuilder<ScheduleBloc, ScheduleState>(
          builder: (context, state) {
            // Показываем индикатор загрузки, пока грузятся данные формы или идет добавление
            if (state is ScheduleFormDataLoading || state is ScheduleAdding) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0), // Добавим отступ
                child: Center(child: CircularProgressIndicator()),
              );
            }
            // Если данные формы загружены, показываем форму
            else if (state is ScheduleFormDataLoaded) {
              // Remove unused formData variable:
              // final formData = state.formData;

              return Form(
                key: _formKey, // Привязываем ключ к форме
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // Чтобы диалог не растягивался
                  children: [
                    ListTile(
                      title: Text(
                        'Время: ${_selectedTime?.format(context) ?? 'Не выбрано'}',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: _pickTime, // Вызываем метод выбора времени
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),

                    // --- Employee Dropdown ---
                    FilterableDropdown<Employee>(
                      items: state.formData.employees,
                      getName: (employee) => employee.fullName,
                      getId: (employee) => employee.id,
                      handleSelected: (employee) {
                        setState(() {
                          _selectedEmployeeId = employee.id;
                        });
                      },
                      hintText: 'Сотрудник',
                      // TODO: Add validation equivalent if needed
                    ),
                    // Выпадающий список Сотрудников (OLD)
                    /*
                    DropdownButtonFormField<int>(
                      value: _selectedEmployeeId,
                      hint: const Text('Сотрудник'),
                      items:
                          formData.employees.map((employee) {
                            return DropdownMenuItem(
                              value: employee.id,
                              child: Text(employee.fullName),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedEmployeeId = value;
                        });
                      },
                      validator:
                          (value) =>
                              value == null ? 'Выберите сотрудника' : null,
                      isExpanded: true,
                    ),
                    */
                    const SizedBox(height: 8),
                    // --- Activity Type Dropdown ---
                    FilterableDropdown<ActivityType>(
                      items: state.formData.activityTypes,
                      getName: (activity) => activity.name,
                      getId: (activity) => activity.id,
                      handleSelected: (activity) {
                        setState(() {
                          _selectedActivityTypeId = activity.id;
                          // Обновляем цену при смене услуги
                          _priceController.text = activity.defaultPrice
                              .toStringAsFixed(2);
                        });
                      },
                      hintText: 'Услуга',
                      // TODO: Add validation equivalent if needed
                    ),
                    // Выпадающий список Услуг (Типов занятий) (OLD)
                    /*
                    DropdownButtonFormField<int>(
                      value: _selectedActivityTypeId,
                      hint: const Text('Услуга'),
                      items:
                          formData.activityTypes.map((activity) {
                            return DropdownMenuItem(
                              value: activity.id,
                              child: Text(activity.name),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedActivityTypeId = value;
                          // Обновляем цену при смене услуги
                          if (value != null) {
                            try {
                              final selectedActivity = formData.activityTypes
                                  .firstWhere((a) => a.id == value);
                              _priceController.text = selectedActivity
                                  .defaultPrice
                                  .toStringAsFixed(2);
                            } catch (e) {
                              print(
                                'Error finding price for activity type: $e',
                              );
                              _priceController.clear();
                            }
                          } else {
                            _priceController.clear();
                          }
                        });
                      },
                      validator:
                          (value) => value == null ? 'Выберите услугу' : null,
                      isExpanded: true,
                    ),
                    */
                    const SizedBox(height: 8),
                    // --- Child Dropdown ---
                    FilterableDropdown<Child>(
                      items: state.formData.children,
                      getName: (child) => child.fullName,
                      getId: (child) => child.id,
                      handleSelected: (child) {
                        setState(() {
                          _selectedChildId = child.id;
                        });
                        context
                            .read<ScheduleBloc>()
                            .add(GetClientSessionBalance(child.id));
                      },
                      onClearSelected: () {
                        setState(() {
                          _selectedChildId = null;
                        });
                      },
                      hintText: 'Ребенок',
                      // TODO: Add validation equivalent if needed
                    ),
                    if (_selectedChildId != null)
                      BlocBuilder<ScheduleBloc, ScheduleState>(
                        buildWhen: (previous, current) {
                          if (previous is ScheduleFormDataLoaded &&
                              current is ScheduleFormDataLoaded) {
                            return previous.isBalanceLoading !=
                                    current.isBalanceLoading ||
                                previous.clientSessionBalance !=
                                    current.clientSessionBalance;
                          }
                          return previous.runtimeType != current.runtimeType;
                        },
                        builder: (context, state) {
                          if (state is ScheduleFormDataLoaded) {
                            if (state.isBalanceLoading) {
                              return const Center(
                                  child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ));
                            }

                            if (state.clientSessionBalance != null) {
                              final balance = state.clientSessionBalance!;
                              final color = balance < 0 ? Colors.red : Colors.green;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'Баланс сессий клиента: $balance',
                                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                                ),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    // Выпадающий список Детей (OLD)
                    /* DropdownButtonFormField<int>(
                      value: _selectedChildId,
                      hint: const Text('Ребенок'),
                      items:
                          formData.children.map((child) {
                            return DropdownMenuItem(
                              value: child.id,
                              child: Text(child.fullName),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedChildId = value;
                        });
                      },
                      validator:
                          (value) => value == null ? 'Выберите ребенка' : null,
                      isExpanded: true,
                    ), */
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Цена (₽)'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите цену';
                        }
                        // Заменяем запятую на точку для double.tryParse
                        final formattedValue = value.replaceAll(',', '.');
                        if (double.tryParse(formattedValue) == null) {
                          return 'Некорректное число';
                        }
                        if (double.parse(formattedValue) < 0) {
                          return 'Цена не может быть отрицательной';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Периодическое занятие'),
                      value: _isRecurring,
                      onChanged: (bool? value) {
                        setState(() {
                          _isRecurring = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_isRecurring)
                      TextFormField(
                        controller: _numberOfSessionsController,
                        decoration: const InputDecoration(
                          labelText: 'Количество занятий (каждую неделю)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_isRecurring) {
                            if (value == null || value.isEmpty) {
                              return 'Укажите количество занятий';
                            }
                            if (int.tryParse(value) == null ||
                                int.parse(value) <= 0) {
                              return 'Некорректное значение';
                            }
                          }
                          return null;
                        },
                      ),
                  ],
                ),
              );
            }
            // Если произошла ошибка при загрузке данных формы
            else if (state is ScheduleError) {
              // Показываем ошибку только если она не связана с добавлением
              if (!state.message.contains('добавления')) {
                return Center(
                  child: Text('Ошибка загрузки данных формы: ${state.message}'),
                );
              } else {
                // Если ошибка добавления, BlocListener выше покажет SnackBar,
                // а здесь можно показать пустой контейнер или заглушку
                return const SizedBox.shrink();
              }
            }
            // Другие состояния (например, ScheduleInitial, ScheduleLoaded после ошибки)
            else {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(child: Text('Загрузка данных формы...')),
              );
            }
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Отмена'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        // Используем BlocBuilder для состояния кнопки "Добавить"
        BlocBuilder<ScheduleBloc, ScheduleState>(
          builder: (context, state) {
            // Блокируем кнопку во время загрузки данных или добавления сессии
            final bool isLoading =
                state is ScheduleFormDataLoading || state is ScheduleAdding;
            return TextButton(
              onPressed:
                  isLoading
                      ? null
                      : () {
                        // Отключаем кнопку при загрузке
                        // Проверяем, что данные формы загружены перед добавлением
                        final currentState =
                            BlocProvider.of<ScheduleBloc>(context).state;
                        if (currentState is ScheduleFormDataLoaded) {
                          // Валидируем форму и проверяем выбор времени
                          bool isFormValid =
                              _formKey.currentState?.validate() ?? false;
                          bool isTimeSelected = _selectedTime != null;

                          if (isFormValid && isTimeSelected) {
                            final priceString = _priceController.text
                                .replaceAll(',', '.');
                            final price = double.parse(priceString);
                            final formData = currentState.formData;
                            final selectedActivity = formData.activityTypes
                                .firstWhere(
                                  (a) => a.id == _selectedActivityTypeId,
                                );
                            final durationMinutes =
                                selectedActivity.durationInMinutes;

                            if (_isRecurring) {
                              // Логика для добавления периодических занятий
                              final numberOfSessions =
                                  int.tryParse(
                                    _numberOfSessionsController.text,
                                  ) ??
                                  0;
                              if (numberOfSessions > 0) {
                                // TODO: Implement recurring session creation and conflict check
                                print(
                                  'Adding $numberOfSessions recurring sessions starting from ${widget.selectedDate} at ${_selectedTime!.format(context)}',
                                );
                                // Dispatch the new AddRecurringSessions event
                                BlocProvider.of<ScheduleBloc>(context).add(
                                  AddRecurringSessions(
                                    startDate: widget.selectedDate,
                                    timeOfDay: _selectedTime!,
                                    employeeId: _selectedEmployeeId!,
                                    activityTypeId: _selectedActivityTypeId!,
                                    childId: _selectedChildId!,
                                    price: price,
                                    durationMinutes: durationMinutes,
                                    numberOfSessions: numberOfSessions,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Укажите корректное количество занятий для периодического добавления.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } else {
                              // Логика для добавления одиночного занятия
                              final sessionDateTime = DateTime(
                                widget.selectedDate.year,
                                widget.selectedDate.month,
                                widget.selectedDate.day,
                                _selectedTime!.hour,
                                _selectedTime!.minute,
                              );

                              // Отправляем событие добавления одиночной сессии
                              BlocProvider.of<ScheduleBloc>(context).add(
                                AddNewSession(
                                  dateTime: sessionDateTime,
                                  employeeId: _selectedEmployeeId!,
                                  activityTypeId: _selectedActivityTypeId!,
                                  childId: _selectedChildId!,
                                  price: price,
                                  durationMinutes: durationMinutes,
                                ),
                              );
                            }
                          } else if (!isTimeSelected) {
                            // Информируем пользователя, если время не выбрано
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Пожалуйста, выберите время сессии.',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          } else {
                            // Если форма невалидна, валидация покажет ошибки в полях
                          }
                        }
                      },
              child:
                  isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Добавить'),
            );
          },
        ),
      ],
    );
  }
}

// <<<=== Диалог РЕДАКТИРОВАНИЯ сессии ===>>>

// Виджет для содержимого диалога РЕДАКТИРОВАНИЯ сессии
class _EditSessionDialogContent extends StatefulWidget {
  final SessionDetails session; // Добавляем редактируемую сессию
  final DateTime selectedDate; // Дата нужна для DateTime Picker

  const _EditSessionDialogContent({
    required this.session,
    required this.selectedDate,
  });

  @override
  State<_EditSessionDialogContent> createState() =>
      _EditSessionDialogContentState();
}

class _EditSessionDialogContentState extends State<_EditSessionDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  late TextEditingController _notesController;
  TimeOfDay? _selectedTime;
  int? _selectedEmployeeId;
  int? _selectedActivityTypeId;
  int? _selectedChildId;
  bool _isPaid = false;

  // Helper function to find initial item by ID
  T? _findItemById<T>(List<T> items, int? id, int Function(T item) getId) {
    if (id == null) return null;
    try {
      return items.firstWhere((item) => getId(item) == id);
    } catch (e) {
      return null; // Not found
    }
  }

  @override
  void initState() {
    super.initState();
    // Предзаполняем поля данными из редактируемой сессии
    _selectedTime = TimeOfDay.fromDateTime(widget.session.dateTime);
    _selectedEmployeeId = widget.session.employeeId;
    _selectedActivityTypeId = widget.session.activityTypeId;
    _selectedChildId = widget.session.childId;
    _priceController = TextEditingController(
      text: widget.session.price.toStringAsFixed(2),
    );
    _durationController = TextEditingController(
      text: widget.session.duration.inMinutes.toString(),
    );
    _isPaid = widget.session.isCompleted;
    _notesController = TextEditingController(text: widget.session.notes ?? '');

    // Загружаем данные для формы, если они еще не загружены
    final currentState = BlocProvider.of<ScheduleBloc>(context).state;
    if (currentState is! ScheduleFormDataLoaded &&
        currentState is! ScheduleFormDataLoading) {
      BlocProvider.of<ScheduleBloc>(context).add(LoadScheduleFormData());
    }
    // Запрашиваем баланс для изначально выбранного клиента
    if (_selectedChildId != null) {
      context.read<ScheduleBloc>().add(GetClientSessionBalance(_selectedChildId!));
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Метод для выбора времени
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScheduleBloc, ScheduleState>(
      listener: (context, state) {
        // Логика для закрытия диалога или показа SnackBar перенесена
        // в _showEditSessionDialog в BlocListener
      },
      builder: (context, state) {
        bool isLoading =
            state is ScheduleFormDataLoading ||
            state is ScheduleUpdating; // Используем ScheduleUpdating
        bool canDismiss = !isLoading;

        return PopScope(
          canPop: canDismiss,
          onPopInvoked: (didPop) {
            if (!didPop) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Пожалуйста, подождите завершения операции.'),
                ),
              );
            }
          },
          child: AlertDialog(
            title: const Text('Редактировать сессию'), // Меняем заголовок
            content: SingleChildScrollView(
              child: _buildFormContent(context, state),
            ),
            actions: <Widget>[
              TextButton(
                onPressed:
                    canDismiss ? () => Navigator.of(context).pop() : null,
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed:
                    (state is ScheduleFormDataLoaded && !isLoading)
                        ? _submitEditForm
                        : null,
                child:
                    isLoading && state is ScheduleUpdating
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Сохранить'), // Вызываем _submitEditForm
              ),
            ],
          ),
        );
      },
    );
  }

  // Метод для построения содержимого формы (идентичен диалогу добавления)
  Widget _buildFormContent(BuildContext context, ScheduleState state) {
    if (state is ScheduleFormDataLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (state is ScheduleFormDataLoaded) {
      // Remove unused formData variable:
      // final formData = state.formData;

      return Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Время: ${_selectedTime?.format(context) ?? 'Не выбрано'}',
              ),
              trailing: const Icon(Icons.access_time),
              onTap: _pickTime,
              contentPadding: EdgeInsets.zero,
            ),
            if (_selectedTime == null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Выберите время',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // --- Employee Dropdown ---
            FilterableDropdown<Employee>(
              items: state.formData.employees,
              getName: (employee) => employee.fullName,
              getId: (employee) => employee.id,
              handleSelected: (employee) {
                setState(() {
                  _selectedEmployeeId = employee.id;
                });
              },
              hintText: 'Сотрудник',
              initialItem: _findItemById(
                state.formData.employees,
                _selectedEmployeeId,
                (e) => e.id,
              ),
              // TODO: Add validation equivalent if needed
            ),
            // Выпадающий список Сотрудников (OLD)
            /*
            DropdownButtonFormField<int>(
              value: _selectedEmployeeId,
              hint: const Text('Сотрудник'),
              items: state.formData.employees.map((employee) {
                return DropdownMenuItem(
                  value: employee.id,
                  child: Text(employee.fullName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedEmployeeId = value;
                });
              },
              validator: (value) => value == null ? 'Выберите сотрудника' : null,
              isExpanded: true,
            ),
            */
            const SizedBox(height: 8),
            // --- Activity Type Dropdown ---
            FilterableDropdown<ActivityType>(
              items: state.formData.activityTypes,
              getName: (activity) => activity.name,
              getId: (activity) => activity.id,
              handleSelected: (activity) {
                setState(() {
                  _selectedActivityTypeId = activity.id;
                  _updatePriceFromActivity(
                    state.formData.activityTypes,
                    activity,
                  );
                  _updateDurationFromActivity(
                    state.formData.activityTypes,
                    activity,
                  );
                });
              },
              hintText: 'Услуга',
              initialItem: _findItemById(
                state.formData.activityTypes,
                _selectedActivityTypeId,
                (a) => a.id,
              ),
              // TODO: Add validation equivalent if needed
            ),
            // Выпадающий список Услуг (Типов занятий) (OLD)
            /*
            DropdownButtonFormField<int>(
              value: _selectedActivityTypeId,
              hint: const Text('Услуга'),
              items: state.formData.activityTypes.map((activity) {
                return DropdownMenuItem(
                  value: activity.id,
                  child: Text(activity.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedActivityTypeId = value;
                  _updatePriceFromActivity(state.formData.activityTypes);
                   _updateDurationFromActivity(state.formData.activityTypes);
                });
              },
              validator: (value) => value == null ? 'Выберите услугу' : null,
              isExpanded: true,
            ),
            */
            const SizedBox(height: 8),
            // --- Child Dropdown ---
            FilterableDropdown<Child>(
              items: state.formData.children,
              getName: (child) => child.fullName,
              getId: (child) => child.id,
              handleSelected: (child) {
                setState(() {
                  _selectedChildId = child.id;
                });
                // Запрашиваем баланс при смене клиента
                context
                    .read<ScheduleBloc>()
                    .add(GetClientSessionBalance(child.id));
              },
              onClearSelected: () {
                setState(() {
                  _selectedChildId = null;
                });
              },
              hintText: 'Ребенок',
              initialItem: _findItemById(
                state.formData.children,
                _selectedChildId,
                (c) => c.id,
              ),
              // TODO: Add validation equivalent if needed
            ),
            // Выпадающий список Детей (OLD)
            /*
            DropdownButtonFormField<int>(
              value: _selectedChildId,
              hint: const Text('Ребенок'),
              items: state.formData.children.map((child) {
                return DropdownMenuItem(
                  value: child.id,
                  child: Text(child.fullName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedChildId = value;
                });
              },
              validator: (value) => value == null ? 'Выберите ребенка' : null,
              isExpanded: true,
            ),
            */
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Длительность (мин)',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Укажите длительность';
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Некорректное значение';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Цена (₽)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Введите цену';
                final formattedValue = value.replaceAll(',', '.');
                if (double.tryParse(formattedValue) == null ||
                    double.parse(formattedValue) < 0) {
                  return 'Некорректная цена';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Заметки',
                alignLabelWithHint: true,
              ),
              keyboardType: TextInputType.multiline,
              maxLines: 3,
            ),
          ],
        ),
      );
    } else if (state is ScheduleError) {
      return Center(child: Text('Ошибка загрузки данных: ${state.message}'));
    } else {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(child: Text('Инициализация...')),
      );
    }
  }

  // Вспомогательные методы для обновления цены и длительности (идентичны диалогу добавления)
  void _updatePriceFromActivity(
    List<ActivityType> activities,
    ActivityType? selectedActivity, // Pass the selected activity directly
  ) {
    if (selectedActivity != null) {
      _priceController.text = selectedActivity.defaultPrice.toStringAsFixed(2);
    } else {
      _priceController.clear();
    }
    /* if (_selectedActivityTypeId != null) {
      try {
        final selectedActivity =
            activities.firstWhere((a) => a.id == _selectedActivityTypeId);
        _priceController.text = selectedActivity.defaultPrice.toStringAsFixed(2);
      } catch (e) {
        print('Error finding price for activity type: $e');
        _priceController.clear();
      }
    } else {
      _priceController.clear();
    } */
  }

  void _updateDurationFromActivity(
    List<ActivityType> activities,
    ActivityType? selectedActivity, // Pass the selected activity directly
  ) {
    if (selectedActivity != null) {
      _durationController.text =
          selectedActivity.durationInMinutes
              .toString(); // <-- Use correct field name
    } else {
      _durationController.clear();
    }

    /* if (_selectedActivityTypeId != null) {
      try {
        final selectedActivity =
            activities.firstWhere((a) => a.id == _selectedActivityTypeId);
        _durationController.text = selectedActivity.defaultDurationMinutes.toString();
      } catch (e) {
        print('Error finding duration for activity type: $e');
        _durationController.clear();
      }
    } else {
      _durationController.clear();
    } */
  }

  // Метод для отправки ИЗМЕНЕННОЙ формы
  void _submitEditForm() {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите время сессии.'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {});
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Используем дату из исходной сессии или выбранную в календаре?
      // Логичнее использовать дату из календаря (_selectedDay), если пользователь
      // хочет перенести сессию на другой день через редактирование.
      // Но у нас нет доступа к _selectedDay здесь.
      // Пока оставим исходную дату сессии.
      // TODO: Пересмотреть, если нужна возможность переноса даты через редактирование.
      final selectedDate =
          widget.session.dateTime; // ИЛИ использовать widget.selectedDate?

      final dateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      final duration = Duration(minutes: int.parse(_durationController.text));
      final price = double.parse(_priceController.text.replaceAll(',', '.'));
      final notes =
          _notesController.text.isNotEmpty ? _notesController.text : null;

      // Создаем доменную модель Session напрямую
      final updatedDomainSession = Session(
        id: widget.session.sessionId, // Используем ID из редактируемой сессии!
        dateTime: dateTime,
        duration: duration,
        price: price,
        isCompleted: _isPaid,
        notes: notes,
        activityTypeId: _selectedActivityTypeId!,
        employeeId: _selectedEmployeeId!,
        childId: _selectedChildId!,
      );

      // Отправляем событие обновления в Bloc с Domain Session
      BlocProvider.of<ScheduleBloc>(context).add(
        UpdateExistingSession(updatedDomainSession),
      ); // <-- Pass domain Session
    }
  }
}
