// Реализация ScheduleBloc

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // Import material.dart for TimeOfDay
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

part 'schedule_event.dart';
part 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final GetSessionsForDay _getSessionsForDay;
  final GetScheduleFormData _getScheduleFormData;
  final AddSession _addSession;
  final UpdateSession _updateSession;
  final DeleteSession _deleteSession;
  final CheckRecurringSessionConflicts
  _checkRecurringSessionConflicts; // Add new use case
  final AddMultipleSessions _addMultipleSessions; // Add new use case

  // Храним текущую выбранную дату
  DateTime _selectedDate = DateTime.now();

  ScheduleBloc({
    required GetSessionsForDay getSessionsForDay,
    required GetScheduleFormData getScheduleFormData,
    required AddSession addSession,
    required UpdateSession updateSession,
    required DeleteSession deleteSession,
    required CheckRecurringSessionConflicts
    checkRecurringSessionConflicts, // Add to constructor
    required AddMultipleSessions addMultipleSessions, // Add to constructor
  }) : _getSessionsForDay = getSessionsForDay,
       _getScheduleFormData = getScheduleFormData,
       _addSession = addSession,
       _updateSession = updateSession,
       _deleteSession = deleteSession,
       _checkRecurringSessionConflicts =
           checkRecurringSessionConflicts, // Assign
       _addMultipleSessions = addMultipleSessions, // Assign
       super(ScheduleInitial()) {
    on<SelectedDateChanged>(_onSelectedDateChanged);
    on<LoadSessionsForDay>(_onLoadSessionsForDay);
    on<LoadScheduleFormData>(_onLoadScheduleFormData);
    on<AddNewSession>(_onAddNewSession);
    on<UpdateExistingSession>(_onUpdateExistingSession);
    on<DeleteExistingSession>(_onDeleteExistingSession);
    on<AddRecurringSessions>(_onAddRecurringSessions); // Add new listener
  }

  // Handler for recurring sessions
  Future<void> _onAddRecurringSessions(
    AddRecurringSessions event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleAdding()); // Indicate loading

    try {
      final List<DateTime> sessionDates = [];
      for (int i = 0; i < event.numberOfSessions; i++) {
        // Calculate the date for each recurring session (add i weeks)
        final recurringDate = event.startDate.add(Duration(days: 7 * i));
        // Combine date with selected time of day
        final sessionDateTime = DateTime(
          recurringDate.year,
          recurringDate.month,
          recurringDate.day,
          event.timeOfDay.hour,
          event.timeOfDay.minute,
        );
        sessionDates.add(sessionDateTime);
      }

      // Check for conflicts using the use case
      final List<DateTime> conflictingDates =
          await _checkRecurringSessionConflicts(
            sessionDates,
            event.employeeId,
            event.childId,
            event.durationMinutes,
          );

      if (conflictingDates.isNotEmpty) {
        // Emit a state indicating conflicts and the list of conflicting dates
        emit(ScheduleRecurringConflict(conflictingDates));
        // Do NOT reload sessions here, the dialog will handle user action
      } else {
        // No conflicts, proceed to add sessions
        final List<Session> newSessions =
            sessionDates.map((dateTime) {
              return Session(
                id: 0, // Placeholder ID
                dateTime: dateTime,
                employeeId: event.employeeId,
                activityTypeId: event.activityTypeId,
                childId: event.childId,
                price: event.price,
                duration: Duration(minutes: event.durationMinutes),
              );
            }).toList();

        // Add multiple sessions using the use case
        await _addMultipleSessions(newSessions);

        emit(ScheduleAddSuccess()); // Indicate success
        add(LoadSessionsForDay(_selectedDate)); // Reload sessions
      }
    } catch (e) {
      emit(
        ScheduleError(
          'Ошибка при добавлении периодических сессий: ${e.toString()}',
        ),
      );
      add(LoadSessionsForDay(_selectedDate)); // Reload sessions
    }
  }

  Future<void> _onSelectedDateChanged(
    SelectedDateChanged event,
    Emitter<ScheduleState> emit,
  ) async {
    _selectedDate = event.selectedDate;
    // Загружаем сессии для новой выбранной даты
    add(LoadSessionsForDay(_selectedDate));
  }

  Future<void> _onLoadSessionsForDay(
    LoadSessionsForDay event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleLoading());
    try {
      final sessions = await _getSessionsForDay(event.date);
      emit(ScheduleLoaded(selectedDate: event.date, sessions: sessions));
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
      final formData = await _getScheduleFormData();
      emit(ScheduleFormDataLoaded(formData));
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
      // Create Session domain object instead of Companion
      final newSession = Session(
        id: 0, // Placeholder ID, DB will assign the real one
        dateTime: event.dateTime,
        employeeId: event.employeeId,
        activityTypeId: event.activityTypeId,
        childId: event.childId,
        price: event.price,
        duration: Duration(minutes: event.durationMinutes), // Create Duration
        // isCompleted defaults to false in the model
        // notes are null by default
      );
      await _addSession(newSession); // Pass Session object
      emit(ScheduleAddSuccess());
      // После успешного добавления перезагружаем сессии для текущего дня
      add(LoadSessionsForDay(_selectedDate));
    } catch (e) {
      emit(ScheduleError('Ошибка добавления сессии: ${e.toString()}'));
      // Важно: после ошибки вернуть пользователя в состояние с загруженными сессиями
      // чтобы UI не оставался в состоянии ScheduleAdding или ScheduleError навсегда
      add(LoadSessionsForDay(_selectedDate));
    }
  }

  // Handler for updating a session
  Future<void> _onUpdateExistingSession(
    UpdateExistingSession event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleUpdating());
    try {
      await _updateSession(event.updatedSession);
      emit(ScheduleUpdateSuccess());
      // Reload sessions for the current day
      add(LoadSessionsForDay(_selectedDate));
    } catch (e) {
      emit(ScheduleError('Ошибка обновления сессии: ${e.toString()}'));
      // Reload sessions even after error to reflect current state
      add(LoadSessionsForDay(_selectedDate));
    }
  }

  // Handler for deleting a session
  Future<void> _onDeleteExistingSession(
    DeleteExistingSession event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleDeleting());
    try {
      await _deleteSession(event.sessionId);
      emit(ScheduleDeleteSuccess());
      // Reload sessions for the current day
      add(LoadSessionsForDay(_selectedDate));
    } catch (e) {
      emit(ScheduleError('Ошибка удаления сессии: ${e.toString()}'));
      // Reload sessions even after error to reflect current state
      add(LoadSessionsForDay(_selectedDate));
    }
  }
}
