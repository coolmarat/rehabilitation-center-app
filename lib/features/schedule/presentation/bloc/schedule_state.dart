part of 'schedule_bloc.dart';

// Состояния для ScheduleBloc
abstract class ScheduleState extends Equatable {
  // Теперь все состояния могут хранить сгруппированные сессии
  final Map<DateTime, List<SessionDetails>> groupedSessions;

  const ScheduleState({this.groupedSessions = const {}});

  @override
  List<Object?> get props => [groupedSessions];
}

class ScheduleInitial extends ScheduleState {
  const ScheduleInitial() : super(groupedSessions: const {});
}

class ScheduleLoading extends ScheduleState {
  // Конструктор, чтобы принимать предыдущие сессии и отображать их во время загрузки
  const ScheduleLoading({super.groupedSessions});
}

// Состояние, когда РАСПИСАНИЕ УСПЕШНО ЗАГРУЖЕНО
class ScheduleLoaded extends ScheduleState {
  final DateTime selectedDate;
  final List<SessionDetails> sessions;
  final List<SessionDetails> allSessionsInView;

  const ScheduleLoaded({
    required this.selectedDate,
    required this.sessions,
    required this.allSessionsInView,
    required super.groupedSessions,
  });

  @override
  List<Object?> get props => [selectedDate, sessions, allSessionsInView, groupedSessions];
}

// Состояния для загрузки данных для ФОРМЫ (клиенты, сотрудники и т.д.)
class ScheduleFormDataLoading extends ScheduleState {
  // Сохраняем сессии во время загрузки данных для формы
  const ScheduleFormDataLoading({super.groupedSessions});
}

class ScheduleFormDataLoaded extends ScheduleState {
  final ScheduleFormData formData;
  final int? clientSessionBalance;
  final bool isBalanceLoading;

  const ScheduleFormDataLoaded({
    required this.formData,
    this.clientSessionBalance,
    this.isBalanceLoading = false,
    required super.groupedSessions, // Требуем сессии при создании этого состояния
  });

  ScheduleFormDataLoaded copyWith({
    ScheduleFormData? formData,
    int? clientSessionBalance,
    bool? isBalanceLoading,
  }) {
    return ScheduleFormDataLoaded(
      formData: formData ?? this.formData,
      clientSessionBalance: clientSessionBalance ?? this.clientSessionBalance,
      isBalanceLoading: isBalanceLoading ?? this.isBalanceLoading,
      groupedSessions: groupedSessions,
    );
  }

  @override
  List<Object?> get props => [formData, clientSessionBalance, isBalanceLoading, groupedSessions];
}

// Состояние процесса добавления сессии
class ScheduleAdding extends ScheduleState {
  const ScheduleAdding({super.groupedSessions});
}

// Состояние успешного добавления сессии
class ScheduleAddSuccess extends ScheduleState {
  const ScheduleAddSuccess({super.groupedSessions});
}

// Состояние процесса обновления сессии
class ScheduleUpdating extends ScheduleState {
  const ScheduleUpdating({super.groupedSessions});
}

// Состояние успешного обновления сессии
class ScheduleUpdateSuccess extends ScheduleState {
  const ScheduleUpdateSuccess({super.groupedSessions});
}

// Состояние процесса удаления сессии
class ScheduleDeleting extends ScheduleState {
  const ScheduleDeleting({super.groupedSessions});
}

// Состояние успешного удаления сессии
class ScheduleDeleteSuccess extends ScheduleState {
  const ScheduleDeleteSuccess({super.groupedSessions});
}

// Состояние ошибки
class ScheduleError extends ScheduleState {
  final String message;

  // Ошибки также не должны "терять" уже загруженные сессии
  const ScheduleError({required this.message, super.groupedSessions});

  @override
  List<Object?> get props => [message, groupedSessions];
}

// Состояние конфликта при добавлении периодических сессий
class ScheduleRecurringConflict extends ScheduleState {
  final List<DateTime> conflictingDates;

  const ScheduleRecurringConflict({
    required this.conflictingDates,
    super.groupedSessions,
  });

  @override
  List<Object?> get props => [conflictingDates, groupedSessions];
}

// Состояние, связанное с родителями
class ParentDataLoading extends ScheduleState {
  const ParentDataLoading({super.groupedSessions});
}

class ParentDataLoaded extends ScheduleState {
  final int parentId;
  final double parentBalance;

  const ParentDataLoaded({
    required this.parentId,
    required this.parentBalance,
    super.groupedSessions,
  });

  @override
  List<Object?> get props => [parentId, parentBalance, groupedSessions];
}

// Состояние обработки оплаты
class PaymentProcessing extends ScheduleState {
  const PaymentProcessing({super.groupedSessions});
}

class PaymentConfirmationState extends ScheduleState {
  final int childId;
  final double currentBalance;
  final double sessionPrice;
  final double newBalance;
  
  const PaymentConfirmationState({
    required this.childId,
    required this.currentBalance,
    required this.sessionPrice,
    required this.newBalance,
    super.groupedSessions,
  });
  
  @override
  List<Object?> get props => [childId, currentBalance, sessionPrice, newBalance, groupedSessions];
}

// Состояние обновления полей на основе типа активности
class ActivityFieldsState extends ScheduleState {
  final double price;
  final int durationMinutes;
  
  const ActivityFieldsState({
    required this.price,
    required this.durationMinutes,
    super.groupedSessions,
  });
  
  @override
  List<Object?> get props => [price, durationMinutes, groupedSessions];
}

// Состояние отфильтрованных сеансов
class FilteredSessionsState extends ScheduleState {
  final DateTime day;
  final List<SessionDetails> sessions;
  final int? filteredEmployeeId;
  final int? filteredChildId;
  
  const FilteredSessionsState({
    required this.day,
    required this.sessions,
    this.filteredEmployeeId,
    this.filteredChildId,
    super.groupedSessions,
  });
  
  @override
  List<Object?> get props => [day, sessions, filteredEmployeeId, filteredChildId, groupedSessions];
}
