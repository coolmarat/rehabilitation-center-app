// Реализация ScheduleBloc

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // Import material.dart for TimeOfDay
import 'package:table_calendar/table_calendar.dart'; // Import table_calendar for isSameDay
// Keep these imports here as they are used in the 'part' files
import 'package:rehabilitation_center_app/features/schedule/domain/entities/schedule_form_data.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/session_model.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/entities/session_details.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/usecases/add_session.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/usecases/get_schedule_form_data.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/usecases/get_sessions_for_day.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/usecases/update_session.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/usecases/delete_session.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/usecases/check_recurring_session_conflicts.dart'; // Import new use case
import 'package:rehabilitation_center_app/features/schedule/domain/usecases/add_multiple_sessions.dart'; // Import new use case
import 'package:rehabilitation_center_app/features/clients/domain/usecases/get_parent_id_by_child_id.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/update_parent_balance.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/usecases/get_client_session_balance.dart' as gcsb;

part 'schedule_event.dart';
part 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final GetSessionsForDay _getSessionsForDay;
  final GetScheduleFormData _getScheduleFormData;
  final AddSession _addSession;
  final UpdateSession _updateSession;
  final DeleteSession _deleteSession;
  final CheckRecurringSessionConflicts _checkRecurringSessionConflicts;
  final AddMultipleSessions _addMultipleSessions;
  final gcsb.GetClientSessionBalance _getClientSessionBalance;
  final GetParentIdByChildId _getParentIdByChildId;
  final UpdateParentBalance _updateParentBalance;

  DateTime _selectedDate = DateTime.now();

  ScheduleBloc({
    required GetSessionsForDay getSessionsForDay,
    required GetScheduleFormData getScheduleFormData,
    required AddSession addSession,
    required UpdateSession updateSession,
    required DeleteSession deleteSession,
    required CheckRecurringSessionConflicts checkRecurringSessionConflicts,
    required AddMultipleSessions addMultipleSessions,
    required gcsb.GetClientSessionBalance getClientSessionBalance,
    required GetParentIdByChildId getParentIdByChildId,
    required UpdateParentBalance updateParentBalance,
  })  : _getSessionsForDay = getSessionsForDay,
        _getScheduleFormData = getScheduleFormData,
        _addSession = addSession,
        _updateSession = updateSession,
        _deleteSession = deleteSession,
        _checkRecurringSessionConflicts = checkRecurringSessionConflicts,
        _addMultipleSessions = addMultipleSessions,
        _getClientSessionBalance = getClientSessionBalance,
        _getParentIdByChildId = getParentIdByChildId,
        _updateParentBalance = updateParentBalance,
        super(ScheduleInitial()) {
    on<SelectedDateChanged>(_onSelectedDateChanged);
    on<LoadSessionsForDay>(_onLoadSessionsForDay);
    on<LoadScheduleFormData>(_onLoadScheduleFormData);
    on<AddNewSession>(_onAddNewSession);
    on<UpdateExistingSession>(_onUpdateExistingSession);
    on<DeleteExistingSession>(_onDeleteExistingSession);
    on<AddRecurringSessions>(_onAddRecurringSessions);
    on<GetClientSessionBalance>(_onGetClientSessionBalance);
    on<DeductPaymentFromBalance>(_onDeductPaymentFromBalance);
    
    // New event handlers for business logic moved from screen
    on<FilterSessionsForDay>(_onFilterSessionsForDay);
    on<GetParentForChild>(_onGetParentForChild);
    on<UpdateSessionFieldsFromActivity>(_onUpdateSessionFieldsFromActivity);
    on<ProcessPaymentConfirmation>(_onProcessPaymentConfirmation);
  }

  Future<void> _onSelectedDateChanged(
    SelectedDateChanged event,
    Emitter<ScheduleState> emit,
  ) async {
    _selectedDate = event.selectedDate;
    add(LoadSessionsForDay(_selectedDate));
  }

  Future<void> _onLoadSessionsForDay(
    LoadSessionsForDay event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleLoading(groupedSessions: state.groupedSessions));
    try {
      final startOfMonth = DateTime(event.date.year, event.date.month, 1);
      final endOfMonth = DateTime(event.date.year, event.date.month + 1, 0);
      final datesInMonth = List.generate(
        endOfMonth.difference(startOfMonth).inDays + 1,
        (index) => startOfMonth.add(Duration(days: index)),
      );
      final List<List<SessionDetails>> sessionsForDates = await Future.wait(
        datesInMonth.map((date) => _getSessionsForDay(date)),
      );
      final allSessionsInView = sessionsForDates.expand((list) => list).toList();
      final sessionsForSelectedDay = allSessionsInView.where((session) {
        return isSameDay(session.dateTime, event.date);
      }).toList();
      emit(
        ScheduleLoaded(
          selectedDate: event.date,
          sessions: sessionsForSelectedDay,
          allSessionsInView: allSessionsInView,
          groupedSessions: _groupSessionsByDay(allSessionsInView),
        ),
      );
    } catch (e) {
      emit(ScheduleError(
        message: 'Ошибка загрузки сессий: ${e.toString()}',
        groupedSessions: state.groupedSessions,
      ));
    }
  }

  Future<void> _onLoadScheduleFormData(
    LoadScheduleFormData event,
    Emitter<ScheduleState> emit,
  ) async {
    // Уже загружено, но нужно убедиться, что сессии не потеряны
    if (state is ScheduleFormDataLoaded) {
      // Если сессии есть, просто выходим
      if (state.groupedSessions.isNotEmpty) return;
      // Если сессий нет, перезагружаем с ними
    }

    emit(ScheduleFormDataLoading(groupedSessions: state.groupedSessions));
    try {
      final formData = await _getScheduleFormData.call();
      emit(ScheduleFormDataLoaded(
        formData: formData,
        groupedSessions: state.groupedSessions, // Передаем сессии дальше
      ));
    } catch (e) {
      emit(ScheduleError(
        message: 'Ошибка загрузки данных для формы: ${e.toString()}',
        groupedSessions: state.groupedSessions, // Сохраняем сессии при ошибке
      ));
    }
  }

  Future<void> _onAddNewSession(
    AddNewSession event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleAdding(groupedSessions: state.groupedSessions));
    try {
      final newSession = Session(
        id: 0,
        dateTime: event.dateTime,
        employeeId: event.employeeId,
        activityTypeId: event.activityTypeId,
        childId: event.childId,
        price: event.price,
        duration: Duration(minutes: event.durationMinutes),
      );
      await _addSession(newSession);

      // Списываем баланс, если цена больше нуля
      if (event.price > 0) {
        final parentIdEither = await _getParentIdByChildId(event.childId);

        await parentIdEither.fold(
          (failure) => throw Exception('Не удалось найти родителя для списания баланса.'),
          (parentId) async {
            final result = await _updateParentBalance(
              UpdateParentBalanceParams(parentId: parentId, amount: -event.price), // Передаем отрицательное значение для списания
            );
            result.fold(
              (failure) => throw Exception('Не удалось списать средства с баланса.'),
              (_) => null, // Успех
            );
          },
        );
      }

      emit(ScheduleAddSuccess(groupedSessions: state.groupedSessions));
      add(LoadSessionsForDay(_selectedDate));
    } catch (e) {
      emit(ScheduleError(
        message: 'Ошибка добавления сессии и списания баланса: ${e.toString()}',
        groupedSessions: state.groupedSessions,
      ));
      // Перезагружаем сессии, чтобы пользователь видел актуальное состояние, даже если списание не удалось
      add(LoadSessionsForDay(_selectedDate));
    }
  }

  Future<void> _onUpdateExistingSession(
    UpdateExistingSession event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleUpdating(groupedSessions: state.groupedSessions));
    try {
      await _updateSession(event.updatedSession);
      emit(ScheduleUpdateSuccess(groupedSessions: state.groupedSessions));
      add(LoadSessionsForDay(_selectedDate));
    } catch (e) {
      emit(ScheduleError(
        message: 'Ошибка обновления сессии: ${e.toString()}',
        groupedSessions: state.groupedSessions,
      ));
      add(LoadSessionsForDay(_selectedDate));
    }
  }

  Future<void> _onDeleteExistingSession(
    DeleteExistingSession event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleDeleting(groupedSessions: state.groupedSessions));
    try {
      await _deleteSession(event.sessionId);
      emit(ScheduleDeleteSuccess(groupedSessions: state.groupedSessions));
      add(LoadSessionsForDay(_selectedDate));
    } catch (e) {
      emit(ScheduleError(
        message: 'Ошибка удаления сессии: ${e.toString()}',
        groupedSessions: state.groupedSessions,
      ));
      add(LoadSessionsForDay(_selectedDate));
    }
  }

  Future<void> _onAddRecurringSessions(
    AddRecurringSessions event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleAdding(groupedSessions: state.groupedSessions));
    try {
      final List<DateTime> sessionDates = [];
      for (int i = 0; i < event.numberOfSessions; i++) {
        final recurringDate = event.startDate.add(Duration(days: 7 * i));
        final sessionDateTime = DateTime(
          recurringDate.year,
          recurringDate.month,
          recurringDate.day,
          event.timeOfDay.hour,
          event.timeOfDay.minute,
        );
        sessionDates.add(sessionDateTime);
      }
      final List<DateTime> conflictingDates = await _checkRecurringSessionConflicts(
        sessionDates,
        event.employeeId,
        event.childId,
        event.durationMinutes,
      );
      if (conflictingDates.isNotEmpty) {
        emit(ScheduleRecurringConflict(
          conflictingDates: conflictingDates,
          groupedSessions: state.groupedSessions,
        ));
      } else {
        final List<Session> newSessions = sessionDates.map((dateTime) {
          return Session(
            id: 0,
            activityTypeId: event.activityTypeId,
            employeeId: event.employeeId,
            childId: event.childId,
            dateTime: dateTime,
            duration: Duration(minutes: event.durationMinutes),
            price: event.price,
            isCompleted: false,
          );
        }).toList();
        await _addMultipleSessions(newSessions);
        emit(ScheduleAddSuccess(groupedSessions: state.groupedSessions));
        add(LoadSessionsForDay(_selectedDate));
      }
    } catch (e) {
      emit(ScheduleError(
        message: 'Ошибка добавления сессий: ${e.toString()}',
        groupedSessions: state.groupedSessions,
      ));
    }
  }

  Future<void> _onGetClientSessionBalance(
    GetClientSessionBalance event,
    Emitter<ScheduleState> emit,
  ) async {
    try {
      // Сохраняем текущее состояние, чтобы не потерять данные формы
      if (state is ScheduleFormDataLoaded) {
        final currentState = state as ScheduleFormDataLoaded;
        emit(currentState.copyWith(isBalanceLoading: true));
        
        final balance = await _getClientSessionBalance(event.clientId);
        emit(currentState.copyWith(
          clientSessionBalance: balance,
          isBalanceLoading: false,
        ));
      }
    } catch (e) {
      if (state is ScheduleFormDataLoaded) {
        final currentState = state as ScheduleFormDataLoaded;
        emit(currentState.copyWith(isBalanceLoading: false));
      } else {
        emit(ScheduleError(
          message: 'Ошибка загрузки баланса: ${e.toString()}',
          groupedSessions: state.groupedSessions,
        ));
      }
    }
  }
  
  Future<void> _onDeductPaymentFromBalance(
    DeductPaymentFromBalance event,
    Emitter<ScheduleState> emit,
  ) async {
    try {
      final parentIdEither = await _getParentIdByChildId(event.childId);

      await parentIdEither.fold(
        (failure) async {
          emit(ScheduleError(
            message: 'Не удалось найти родителя для списания баланса.',
            groupedSessions: state.groupedSessions,
          ));
        },
        (parentId) async {
          // Вычитаем сумму из баланса родителя (передаем отрицательное значение для списания)
          final result = await _updateParentBalance(
            UpdateParentBalanceParams(
              parentId: parentId,
              amount: -event.amount, // Отрицательное значение для списания
            ),
          );

          await result.fold(
            (failure) async {
              emit(ScheduleError(
                message: 'Ошибка обновления баланса: $failure',
                groupedSessions: state.groupedSessions,
              ));
            },
            (_) async {
              // Обновляем баланс в интерфейсе
              if (state is ScheduleFormDataLoaded && emit.isDone == false) {
                final currentState = state as ScheduleFormDataLoaded;
                // Запрашиваем актуальный баланс после обновления
                final newBalance = await _getClientSessionBalance(event.childId);
                if (!emit.isDone) {
                  emit(currentState.copyWith(clientSessionBalance: newBalance));
                }
              }
            },
          );
        },
      );
    } catch (e) {
      if (!emit.isDone) {
        emit(ScheduleError(
          message: 'Ошибка обновления баланса: ${e.toString()}',
          groupedSessions: state.groupedSessions,
        ));
      }
    }
  }

  // Фильтрация сессий для конкретного дня с учетом выбранного сотрудника и ребенка
  Future<void> _onFilterSessionsForDay(
    FilterSessionsForDay event,
    Emitter<ScheduleState> emit,
  ) async {
    try {
      // Получаем текущее состояние, чтобы иметь доступ к списку всех сессий
      if (state is ScheduleLoaded) {
        final currentState = state as ScheduleLoaded;
        List<SessionDetails> sessionsForDay = currentState.allSessionsInView
            .where((session) => isSameDay(session.dateTime, event.day))
            .toList();

        // Применяем фильтр по сотруднику, если выбран
        if (event.employeeId != null) {
          sessionsForDay = sessionsForDay
              .where((session) => session.employeeId == event.employeeId)
              .toList();
        }

        // Применяем фильтр по ребенку, если выбран
        if (event.childId != null) {
          sessionsForDay = sessionsForDay
              .where((session) => session.childId == event.childId)
              .toList();
        }

        // Отправляем отфильтрованные сессии
        emit(FilteredSessionsState(
          day: event.day,
          sessions: sessionsForDay,
          filteredEmployeeId: event.employeeId,
          filteredChildId: event.childId,
          groupedSessions: state.groupedSessions,
        ));
      }
    } catch (e) {
      emit(ScheduleError(
        message: 'Ошибка фильтрации сессий: ${e.toString()}',
        groupedSessions: state.groupedSessions,
      ));
    }
  }

  // Получение данных о родителе по ID ребенка
  Future<void> _onGetParentForChild(
    GetParentForChild event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ParentDataLoading(groupedSessions: state.groupedSessions));
    try {
      // Получаем ID родителя по ID ребенка
      final parentIdEither = await _getParentIdByChildId(event.childId);

      await parentIdEither.fold(
        (failure) {
          emit(ScheduleError(
            message: 'Не удалось найти родителя: $failure',
            groupedSessions: state.groupedSessions,
          ));
        },
        (parentId) async {
          // Здесь бы получать данные о родителе, включая баланс
          // Пока просто возвращаем ID
          final balance = await _getClientSessionBalance(event.childId);
          emit(ParentDataLoaded(
            parentId: parentId,
            parentBalance: balance.toDouble(),
            groupedSessions: state.groupedSessions,
          ));
        },
      );
    } catch (e) {
      emit(ScheduleError(
        message: 'Ошибка получения данных родителя: ${e.toString()}',
        groupedSessions: state.groupedSessions,
      ));
    }
  }

  // Обновление полей цены и длительности на основе выбранного типа активности
  Future<void> _onUpdateSessionFieldsFromActivity(
    UpdateSessionFieldsFromActivity event,
    Emitter<ScheduleState> emit,
  ) async {
    try {
      if (state is ScheduleFormDataLoaded) {
        final currentState = state as ScheduleFormDataLoaded;
        final selectedActivity = currentState.formData.activityTypes.firstWhere(
          (activity) => activity.id == event.activityTypeId,
        );

        emit(ActivityFieldsState(
          price: selectedActivity.defaultPrice,
          durationMinutes: selectedActivity.durationInMinutes,
          groupedSessions: state.groupedSessions,
        ));

        // Возвращаем состояние формы для дальнейшей работы
        emit(currentState);
      } else {
        emit(ScheduleError(
          message: 'Данные формы не загружены',
          groupedSessions: state.groupedSessions,
        ));
      }
    } catch (e) {
      emit(ScheduleError(
        message: 'Ошибка обновления полей: ${e.toString()}',
        groupedSessions: state.groupedSessions,
      ));
    }
  }

  // Обработка подтверждения оплаты
  Future<void> _onProcessPaymentConfirmation(
    ProcessPaymentConfirmation event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(PaymentProcessing(groupedSessions: state.groupedSessions));
    try {
      final parentIdEither = await _getParentIdByChildId(event.childId);

      await parentIdEither.fold(
        (failure) {
          emit(ScheduleError(
            message: 'Не удалось найти родителя для подтверждения оплаты: $failure',
            groupedSessions: state.groupedSessions,
          ));
        },
        (parentId) async {
          // Запрашиваем актуальный баланс
          final currentBalance = await _getClientSessionBalance(event.childId);
          final newBalance = currentBalance - event.sessionPrice;

          emit(PaymentConfirmationState(
            childId: event.childId,
            currentBalance: currentBalance.toDouble(),
            sessionPrice: event.sessionPrice,
            newBalance: newBalance.toDouble(),
            groupedSessions: state.groupedSessions,
          ));
        },
      );
    } catch (e) {
      emit(ScheduleError(
        message: 'Ошибка обработки подтверждения оплаты: ${e.toString()}',
        groupedSessions: state.groupedSessions,
      ));
    }
  }

  Map<DateTime, List<SessionDetails>> _groupSessionsByDay(List<SessionDetails> sessions) {
    final Map<DateTime, List<SessionDetails>> data = {};
    for (final session in sessions) {
      final date = DateTime(session.dateTime.year, session.dateTime.month, session.dateTime.day);
      if (data[date] == null) {
        data[date] = [];
      }
      data[date]!.add(session);
    }
    return data;
  }
}
