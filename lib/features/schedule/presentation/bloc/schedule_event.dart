part of 'schedule_bloc.dart';

abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();

  @override
  List<Object> get props => [];
}

// Событие для загрузки сессий для выбранного дня
class LoadSessionsForDay extends ScheduleEvent {
  final DateTime date;

  const LoadSessionsForDay(this.date);

  @override
  List<Object> get props => [date];
}

// Событие для изменения выбранной даты в календаре
class SelectedDateChanged extends ScheduleEvent {
  final DateTime selectedDate;

  const SelectedDateChanged(this.selectedDate);

  @override
  List<Object> get props => [selectedDate];
}

// Событие для загрузки данных, необходимых для формы добавления сессии
class LoadScheduleFormData extends ScheduleEvent {}

// Событие для добавления новой сессии
class AddNewSession extends ScheduleEvent {
  final DateTime dateTime;
  final int employeeId;
  final int activityTypeId;
  final int childId;
  final double price;
  final int durationMinutes;

  const AddNewSession({
    required this.dateTime,
    required this.employeeId,
    required this.activityTypeId,
    required this.childId,
    required this.price,
    required this.durationMinutes,
  });

  @override
  List<Object> get props => [
    dateTime,
    employeeId,
    activityTypeId,
    childId,
    price,
    durationMinutes,
  ];
}

// Событие для обновления существующей сессии
class UpdateExistingSession extends ScheduleEvent {
  final Session updatedSession;

  const UpdateExistingSession(this.updatedSession);

  @override
  List<Object> get props => [updatedSession];
}

// Событие для удаления сессии
class DeleteExistingSession extends ScheduleEvent {
  final int sessionId;

  const DeleteExistingSession(this.sessionId);

  @override
  List<Object> get props => [sessionId];
}

// Событие для добавления периодических сессий
class AddRecurringSessions extends ScheduleEvent {
  final DateTime startDate;
  final TimeOfDay timeOfDay;
  final int employeeId;
  final int activityTypeId;
  final int childId;
  final double price;
  final int durationMinutes;
  final int numberOfSessions;

  const AddRecurringSessions({
    required this.startDate,
    required this.timeOfDay,
    required this.employeeId,
    required this.activityTypeId,
    required this.childId,
    required this.price,
    required this.durationMinutes,
    required this.numberOfSessions,
  });

  @override
  List<Object> get props => [
    startDate,
    timeOfDay,
    employeeId,
    activityTypeId,
    childId,
    price,
    durationMinutes,
    numberOfSessions,
  ];
}
