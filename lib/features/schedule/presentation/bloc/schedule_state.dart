part of 'schedule_bloc.dart';

// Состояния для ScheduleBloc
abstract class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object?> get props => [];
}

// Начальное состояние
class ScheduleInitial extends ScheduleState {}

// Состояние загрузки (например, при смене дня)
class ScheduleLoading extends ScheduleState {}

// Состояние успешной загрузки сессий для дня
class ScheduleLoaded extends ScheduleState {
  final DateTime selectedDate;
  final List<SessionDetails> sessions;

  const ScheduleLoaded({required this.selectedDate, required this.sessions});

  @override
  List<Object?> get props => [selectedDate, sessions];
}

// Состояние загрузки данных для формы
class ScheduleFormDataLoading extends ScheduleState {}

// Состояние успешной загрузки данных для формы
class ScheduleFormDataLoaded extends ScheduleState {
  final ScheduleFormData formData;

  const ScheduleFormDataLoaded(this.formData);

  @override
  List<Object?> get props => [formData];
}

// Состояние процесса добавления сессии
class ScheduleAdding extends ScheduleState {}

// Состояние успешного добавления сессии
class ScheduleAddSuccess extends ScheduleState {}

// Состояние процесса обновления сессии
class ScheduleUpdating extends ScheduleState {}

// Состояние успешного обновления сессии
class ScheduleUpdateSuccess extends ScheduleState {}

// Состояние процесса удаления сессии
class ScheduleDeleting extends ScheduleState {}

// Состояние успешного удаления сессии
class ScheduleDeleteSuccess extends ScheduleState {}

// Состояние ошибки
class ScheduleError extends ScheduleState {
  final String message;

  const ScheduleError(this.message);

  @override
  List<Object?> get props => [message];
}

// Состояние конфликта при добавлении периодических сессий
class ScheduleRecurringConflict extends ScheduleState {
  final List<DateTime> conflictingDates;

  const ScheduleRecurringConflict(this.conflictingDates);

  @override
  List<Object?> get props => [conflictingDates];
}
