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

// Событие для получения баланса занятий клиента
class GetClientSessionBalance extends ScheduleEvent {
  final int clientId;

  const GetClientSessionBalance(this.clientId);

  @override
  List<Object> get props => [clientId];
}

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

// Событие для обновления баланса родителя при оплате сессии
class DeductPaymentFromBalance extends ScheduleEvent {
  final int childId;
  final double amount;

  const DeductPaymentFromBalance({
    required this.childId,
    required this.amount,
  });

  @override
  List<Object> get props => [childId, amount];
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

// Событие для фильтрации сеансов по дате, сотруднику и клиенту
class FilterSessionsForDay extends ScheduleEvent {
  final DateTime day;
  final int? employeeId;
  final int? childId;

  const FilterSessionsForDay({
    required this.day,
    this.employeeId,
    this.childId,
  });

  @override
  List<Object> get props => [day];

  // This is not overriding anything, just adding extra functionality
  List<Object?> get propList => [day, employeeId, childId];
}

// Событие для получения родительских данных по идентификатору ребенка
class GetParentForChild extends ScheduleEvent {
  final int childId;

  const GetParentForChild(this.childId);

  @override
  List<Object> get props => [childId];
}

// Событие для обновления полей сессии на основе выбранного типа активности
class UpdateSessionFieldsFromActivity extends ScheduleEvent {
  final int activityTypeId;

  const UpdateSessionFieldsFromActivity(this.activityTypeId);

  @override
  List<Object> get props => [activityTypeId];
}

// Событие для обработки подтверждения оплаты
class ProcessPaymentConfirmation extends ScheduleEvent {
  final int childId;
  final double sessionPrice;
  
  const ProcessPaymentConfirmation({
    required this.childId,
    required this.sessionPrice,
  });

  @override
  List<Object> get props => [childId, sessionPrice];
}
