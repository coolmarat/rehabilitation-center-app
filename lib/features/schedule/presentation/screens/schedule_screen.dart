// Экран расписания

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Для форматирования дат
import 'package:rehabilitation_center_app/features/activity_types/domain/activity_type.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/entities/session_details.dart'; // Добавляем импорт
import 'package:rehabilitation_center_app/features/schedule/presentation/bloc/schedule_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../domain/session_model.dart'; // Added back import

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Загрузка сессий для начального дня (уже делается в main.dart при создании Bloc)
    // BlocProvider.of<ScheduleBloc>(context).add(LoadSessionsForDay(_focusedDay));
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
      body: Column(
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
                  state is ScheduleLoaded ? state.selectedDate : _selectedDay;
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
                      _focusedDay = focusedDay; // Update focused day as well
                    });
                    // Trigger loading sessions for the newly selected day
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
              );
            },
          ),
          const Divider(), // Separator between calendar and list
          // Session List Area
          Expanded(
            // Use Expanded to take remaining space
            child: BlocBuilder<ScheduleBloc, ScheduleState>(
              builder: (context, state) {
                if (state is ScheduleLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ScheduleLoaded) {
                  if (state.sessions.isEmpty) {
                    return const Center(
                      child: Text('Нет записей на выбранный день.'),
                    );
                  }
                  // Build the list of sessions
                  return ListView.builder(
                    itemCount: state.sessions.length,
                    itemBuilder: (context, index) {
                      final session = state.sessions[index];
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
                } else if (state is ScheduleError) {
                  return Center(
                    child: Text('Ошибка загрузки: ${state.message}'),
                  );
                } else {
                  // Initial state or other unhandled states
                  return const Center(
                    child: Text('Выберите день для просмотра расписания.'),
                  );
                }
              },
            ),
          ),
        ],
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

  @override
  void initState() {
    super.initState();
    // Устанавливаем начальное время (например, 9:00)
    _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  }

  @override
  void dispose() {
    _priceController.dispose();
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
              final formData = state.formData;

              // Устанавливаем цену по умолчанию при первой загрузке данных,
              // если услуга выбрана и поле цены пустое.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted &&
                    _priceController.text.isEmpty &&
                    _selectedActivityTypeId != null) {
                  try {
                    final selectedActivity = formData.activityTypes.firstWhere(
                      (a) => a.id == _selectedActivityTypeId,
                    );
                    _priceController.text = selectedActivity.defaultPrice
                        .toStringAsFixed(2); // Форматируем до 2 знаков
                  } catch (e) {
                    print('Error finding default price for activity type: $e');
                    _priceController.clear(); // Очищаем, если не нашли
                  }
                }
              });

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

                    // Выпадающий список Сотрудников
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
                    const SizedBox(height: 8),
                    // Выпадающий список Услуг (Типов занятий)
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
                    const SizedBox(height: 8),
                    // Выпадающий список Детей
                    DropdownButtonFormField<int>(
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
                    ),
                    const SizedBox(height: 8),
                    // Поле для Цены
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
                            // Собираем дату и время
                            final sessionDateTime = DateTime(
                              widget.selectedDate.year,
                              widget.selectedDate.month,
                              widget.selectedDate.day,
                              _selectedTime!.hour,
                              _selectedTime!.minute,
                            );

                            // Отправляем событие добавления
                            final formData = currentState.formData;
                            final selectedActivity = formData.activityTypes
                                .firstWhere(
                                  (a) => a.id == _selectedActivityTypeId,
                                );
                            BlocProvider.of<ScheduleBloc>(context).add(
                              AddNewSession(
                                dateTime: sessionDateTime,
                                employeeId: _selectedEmployeeId!,
                                activityTypeId: _selectedActivityTypeId!,
                                childId: _selectedChildId!,
                                price: price,
                                durationMinutes:
                                    selectedActivity.durationInMinutes,
                              ),
                            );
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
  int? _selectedEmployeeId;
  int? _selectedActivityTypeId;
  int? _selectedChildId;
  TimeOfDay? _selectedTime;
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Предзаполняем поля данными из редактируемой сессии
    _selectedTime = TimeOfDay.fromDateTime(widget.session.dateTime);
    _selectedEmployeeId = widget.session.employeeId;
    _selectedActivityTypeId = widget.session.activityTypeId;
    _selectedChildId = widget.session.childId;
    _priceController.text = widget.session.price.toStringAsFixed(2);
    _durationController.text = widget.session.duration.inMinutes.toString();
    _notesController.text = widget.session.notes ?? '';

    // Загружаем данные для формы, если они еще не загружены
    final currentState = BlocProvider.of<ScheduleBloc>(context).state;
    if (currentState is! ScheduleFormDataLoaded &&
        currentState is! ScheduleFormDataLoading) {
      BlocProvider.of<ScheduleBloc>(context).add(LoadScheduleFormData());
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    _durationController.dispose();
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
    // Используем BlocConsumer для управления состоянием диалога
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

  // Метод для построения содержимого формы (идентичен диалогу добавления, можно вынести в общий виджет)
  Widget _buildFormContent(BuildContext context, ScheduleState state) {
    if (state is ScheduleFormDataLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (state is ScheduleFormDataLoaded) {
      final formData = state.formData;
      // НЕ нужно устанавливать цену по умолчанию при редактировании
      // WidgetsBinding.instance.addPostFrameCallback((_) { ... });

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
            DropdownButtonFormField<int>(
              value: _selectedEmployeeId,
              hint: const Text('Сотрудник'),
              items:
                  formData.employees
                      .map(
                        (employee) => DropdownMenuItem(
                          value: employee.id,
                          child: Text(employee.fullName),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _selectedEmployeeId = value),
              validator:
                  (value) => value == null ? 'Выберите сотрудника' : null,
              isExpanded: true,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedActivityTypeId,
              hint: const Text('Услуга'),
              items:
                  formData.activityTypes
                      .map(
                        (activity) => DropdownMenuItem(
                          value: activity.id,
                          child: Text(activity.name),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedActivityTypeId = value;
                  // Обновляем цену и длительность при смене услуги (опционально для редактирования)
                  _updatePriceFromActivity(formData.activityTypes);
                  _updateDurationFromActivity(formData.activityTypes);
                });
              },
              validator: (value) => value == null ? 'Выберите услугу' : null,
              isExpanded: true,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedChildId,
              hint: const Text('Ребенок'),
              items:
                  formData.children
                      .map(
                        (child) => DropdownMenuItem(
                          value: child.id,
                          child: Text(child.fullName),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _selectedChildId = value),
              validator: (value) => value == null ? 'Выберите ребенка' : null,
              isExpanded: true,
            ),
            const SizedBox(height: 8),
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
  void _updatePriceFromActivity(List<ActivityType> activities) {
    if (_selectedActivityTypeId != null) {
      try {
        final selectedActivity = activities.firstWhere(
          (a) => a.id == _selectedActivityTypeId,
        );
        _priceController.text = selectedActivity.defaultPrice.toStringAsFixed(
          2,
        );
      } catch (e) {
        print('Error finding price for activity type: $e');
        _priceController.clear();
      }
    } else {
      _priceController.clear();
    }
  }

  void _updateDurationFromActivity(List<ActivityType> activities) {
    if (_selectedActivityTypeId != null) {
      try {
        final selectedActivity = activities.firstWhere(
          (a) => a.id == _selectedActivityTypeId,
        );
        _durationController.text =
            selectedActivity.durationInMinutes.toString(); // Correct field name
      } catch (e) {
        print('Error finding duration for activity type: $e');
      }
    }
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

      // Создаем обновленный объект Session, используя ID исходной сессии
      final updatedSession = Session(
        // Use Session directly
        id: widget.session.sessionId, // Используем ID из редактируемой сессии!
        activityTypeId: _selectedActivityTypeId!,
        employeeId: _selectedEmployeeId!,
        childId: _selectedChildId!,
        dateTime: dateTime,
        duration: duration,
        price: price,
        // Статус isCompleted пока не редактируем здесь
        isCompleted: widget.session.isCompleted,
        notes: notes,
      );

      // Отправляем событие обновления в Bloc
      BlocProvider.of<ScheduleBloc>(
        context,
      ).add(UpdateExistingSession(updatedSession));
    }
  }
}
