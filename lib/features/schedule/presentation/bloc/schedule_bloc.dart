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
    emit(ScheduleLoading());
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
        ),
      );
    } catch (e) {
      emit(ScheduleError('Ошибка загрузки сессий: ${e.toString()}'));
    }
  }

  Future<void> _onLoadScheduleFormData(
    LoadScheduleFormData event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleFormDataLoading());
    try {
      final formData = await _getScheduleFormData.call();
      emit(ScheduleFormDataLoaded(formData: formData));
    } catch (e) {
      emit(ScheduleError('Ошибка загрузки данных для формы: ${e.toString()}'));
    }
  }

  Future<void> _onAddNewSession(
    AddNewSession event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleAdding());
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
        final parentId = await _getParentIdByChildId(event.childId);
        await _updateParentBalance(
            UpdateParentBalanceParams(parentId: parentId, amount: event.price));
      }

      emit(ScheduleAddSuccess());
      add(LoadSessionsForDay(_selectedDate));
    } catch (e) {
      emit(ScheduleError('Ошибка добавления сессии и списания баланса: ${e.toString()}'));
      // Перезагружаем сессии, чтобы пользователь видел актуальное состояние, даже если списание не удалось
      add(LoadSessionsForDay(_selectedDate));
    }
  }

  Future<void> _onUpdateExistingSession(
    UpdateExistingSession event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleUpdating());
    try {
      await _updateSession(event.updatedSession);
      emit(ScheduleUpdateSuccess());
      add(LoadSessionsForDay(_selectedDate));
    } catch (e) {
      emit(ScheduleError('Ошибка обновления сессии: ${e.toString()}'));
      add(LoadSessionsForDay(_selectedDate));
    }
  }

  Future<void> _onDeleteExistingSession(
    DeleteExistingSession event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleDeleting());
    try {
      await _deleteSession(event.sessionId);
      emit(ScheduleDeleteSuccess());
      add(LoadSessionsForDay(_selectedDate));
    } catch (e) {
      emit(ScheduleError('Ошибка удаления сессии: ${e.toString()}'));
      add(LoadSessionsForDay(_selectedDate));
    }
  }

  Future<void> _onAddRecurringSessions(
    AddRecurringSessions event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleAdding());
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
        emit(ScheduleRecurringConflict(conflictingDates));
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
        emit(ScheduleAddSuccess());
        add(LoadSessionsForDay(_selectedDate));
      }
    } catch (e) {
      emit(ScheduleError(e.toString()));
    }
  }

  Future<void> _onGetClientSessionBalance(
    GetClientSessionBalance event,
    Emitter<ScheduleState> emit,
  ) async {
    if (state is ScheduleFormDataLoaded) {
      final currentState = state as ScheduleFormDataLoaded;
      emit(currentState.copyWith(isBalanceLoading: true, clientSessionBalance: null));
      try {
        final balance = await _getClientSessionBalance(event.clientId);
        if (state is ScheduleFormDataLoaded) {
          emit((state as ScheduleFormDataLoaded).copyWith(
            clientSessionBalance: balance,
            isBalanceLoading: false,
          ));
        }
      } catch (e) {
        if (state is ScheduleFormDataLoaded) {
          emit((state as ScheduleFormDataLoaded).copyWith(isBalanceLoading: false));
        }
      }
    }
  }
}
