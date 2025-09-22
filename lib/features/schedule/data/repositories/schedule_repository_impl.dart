import 'package:drift/drift.dart';
import 'package:rehabilitation_center_app/core/database/app_database.dart'
    as db;
import 'package:rehabilitation_center_app/features/activity_types/domain/activity_type.dart'
    as domain_activity_type;
import 'package:rehabilitation_center_app/features/clients/domain/child.dart'
    as domain_child;
import 'package:rehabilitation_center_app/features/employees/domain/employee.dart'
    as domain_employee;
import 'package:rehabilitation_center_app/features/schedule/domain/entities/schedule_form_data.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/entities/session_details.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/session_model.dart'; // Import Session model

// Реализация репозитория для расписания
class ScheduleRepositoryImpl implements ScheduleRepository {
  final db.AppDatabase _database;

  ScheduleRepositoryImpl(this._database);

  @override
  Future<void> addSession(Session session) async {
    final companion = db.SessionsCompanion.insert(
      // Map Session model to SessionsCompanion
      activityTypeId: session.activityTypeId,
      employeeId: session.employeeId,
      childId: session.childId,
      sessionDateTime: session.dateTime, // Use raw value for non-nullable
      durationMinutes: Value<int>(
        session.duration.inMinutes,
      ), // Use raw value for non-nullable
      price: session.price, // Use raw value for non-nullable
      isCompleted: Value(
        session.isCompleted,
      ), // Use Value() for field with default
      isPaid: Value(
        session.isPaid,
      ), // Use Value() for payment field
      notes:
          session.notes == null
              ? const Value.absent()
              : Value(session.notes!), // Handle nullable
    );
    await _database.into(_database.sessions).insert(companion);
  }

  @override
  Future<ScheduleFormData> getScheduleFormData() async {
    // Получаем все данные одним махом для выпадающих списков
    final employeesFuture = _database.select(_database.employees).get();
    final activityTypesFuture = _database.select(_database.activityTypes).get();
    final childrenFuture = _database.select(_database.children).get();

    final results = await Future.wait([
      employeesFuture,
      activityTypesFuture,
      childrenFuture,
    ]);

    // Преобразуем данные Drift в доменные модели
    // Используем db.EmployeeEntry и правильные поля конструктора
    final employees =
        (results[0] as List<db.EmployeeEntry>)
            .map(
              (e) => domain_employee.Employee(
                id: e.id,
                fullName: e.fullName, // Правильное поле
                position: e.position,
                // Убираем phoneNumber и hireDate, т.к. их нет в доменной модели Employee
              ),
            )
            .toList();

    // Используем db.ActivityTypeEntry и правильные поля конструктора
    final activityTypes =
        (results[1] as List<db.ActivityTypeEntry>)
            .map(
              (at) => domain_activity_type.ActivityType(
                id: at.id,
                name: at.name,
                description: at.description, // Поле description есть
                defaultPrice: at.defaultPrice,
                durationInMinutes: at.durationInMinutes, // Add duration mapping
              ),
            )
            .toList();

    // Используем db.ChildEntry и правильные поля конструктора
    final children =
        (results[2] as List<db.ChildEntry>)
            .map(
              (c) => domain_child.Child(
                id: c.id,
                parentId: c.parentId,
                fullName: c.fullName, // Правильное поле
                dateOfBirth: c.dateOfBirth,
                diagnosis: c.diagnosis, // nullable поле
              ),
            )
            .toList();

    return ScheduleFormData(
      employees: employees,
      activityTypes: activityTypes,
      children: children,
    );
  }

  @override
  Future<int> getClientSessionBalance(int clientId) async {
    // Напрямую вызываем метод из DAO, так как репозиторий имеет доступ к базе данных
    return await _database.paymentDao.getClientSessionBalance(clientId);
  }
  
  @override
  Future<int> getParentSessionBalance(int parentId) async {
    // Используем новый метод из DAO для получения баланса родителя
    return await _database.paymentDao.getParentSessionBalance(parentId);
  }

  @override
  Future<List<SessionDetails>> getSessionsForDay(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // Получаем сессии за указанный день
    final query =
        _database.select(_database.sessions).join([
            innerJoin(
              _database.children,
              _database.children.id.equalsExp(_database.sessions.childId),
            ),
            innerJoin(
              _database.employees,
              _database.employees.id.equalsExp(_database.sessions.employeeId),
            ),
            innerJoin(
              _database.activityTypes,
              _database.activityTypes.id.equalsExp(
                _database.sessions.activityTypeId,
              ),
            ),
          ])
          ..where(
            _database.sessions.sessionDateTime.isBetweenValues(
              dayStart,
              dayEnd,
            ),
          )
          ..orderBy([
            OrderingTerm(expression: _database.sessions.sessionDateTime),
          ]);

    final results = await query.get();

    // Преобразуем результат в список SessionDetails
    return results.map((row) {
      final sessionEntry = row.readTable(_database.sessions);
      final childEntry = row.readTable(_database.children);
      final employeeEntry = row.readTable(_database.employees);
      final activityTypeEntry = row.readTable(_database.activityTypes);

      return SessionDetails(
        sessionId: sessionEntry.id,
        dateTime: sessionEntry.sessionDateTime,
        duration: Duration(minutes: sessionEntry.durationMinutes),
        employeeName: employeeEntry.fullName,
        activityTypeName: activityTypeEntry.name,
        childName: childEntry.fullName,
        price: sessionEntry.price,
        employeeId: sessionEntry.employeeId,
        activityTypeId: sessionEntry.activityTypeId,
        childId: sessionEntry.childId,
        notes: sessionEntry.notes,
        isCompleted: sessionEntry.isCompleted,
        isPaid: sessionEntry.isPaid,
      );
    }).toList();
  }

  @override
  Future<void> updateSession(Session session) async {
    final companion = db.SessionsCompanion(
      id: Value(session.id), // Important: Identify which session to update
      activityTypeId: Value(session.activityTypeId),
      employeeId: Value(session.employeeId),
      childId: Value(session.childId),
      sessionDateTime: Value(session.dateTime),
      durationMinutes: Value(session.duration.inMinutes),
      price: Value(session.price),
      isCompleted: Value(session.isCompleted),
      isPaid: Value(session.isPaid),
      notes:
          session.notes == null
              ? const Value.absent()
              : Value(session.notes!), // Handle nullable
    );
    await (_database.update(_database.sessions)
      ..where((tbl) => tbl.id.equals(session.id))).write(companion);
  }

  @override
  Future<int> deleteSession(int sessionId) async {
    return await (_database.delete(_database.sessions)
      ..where((tbl) => tbl.id.equals(sessionId))).go();
  }

  @override
  Future<List<DateTime>> checkRecurringSessionConflicts(
    List<DateTime> sessionDates,
    int employeeId,
    int childId,
    int durationMinutes,
  ) async {
    final List<DateTime> conflictingDates = [];
    final duration = Duration(minutes: durationMinutes);

    for (final date in sessionDates) {
      final sessionStart = DateTime(
        date.year,
        date.month,
        date.day,
        date.hour,
        date.minute,
      );
      final sessionEnd = sessionStart.add(duration);

      // Check for conflicts for the employee OR the child
      final query = _database.select(_database.sessions)..where(
        (tbl) =>
            (tbl.employeeId.equals(employeeId) | tbl.childId.equals(childId)) &
            // Check for overlap: existing session starts before new ends AND existing session ends after new starts
            // Check for overlap using timestamps: existing session starts before new ends AND existing session ends after new starts
            // Check for overlap using timestamps (seconds since epoch)
            CustomExpression<int>(
              "CAST(strftime('%s', T1.session_date_time) AS INTEGER)",
            ).isSmallerThanValue(sessionEnd.millisecondsSinceEpoch ~/ 1000) &
            CustomExpression<int>(
              "CAST(strftime('%s', datetime(T1.session_date_time, '+' || T1.duration_minutes || ' minutes')) AS INTEGER)",
            ).isBiggerThanValue(sessionStart.millisecondsSinceEpoch ~/ 1000),
      );

      final conflicts = await query.get();

      if (conflicts.isNotEmpty) {
        conflictingDates.add(date);
      }
    }

    return conflictingDates;
  }

  @override
  Future<void> addMultipleSessions(List<Session> sessions) async {
    await _database.batch((batch) {
      for (final session in sessions) {
        final companion = db.SessionsCompanion.insert(
          activityTypeId: session.activityTypeId,
          employeeId: session.employeeId,
          childId: session.childId,
          sessionDateTime: session.dateTime,
          durationMinutes: Value<int>(session.duration.inMinutes),
          price: session.price,
          isCompleted: Value(session.isCompleted),
          isPaid: Value(session.isPaid),
          notes:
              session.notes == null
                  ? const Value.absent()
                  : Value(session.notes!),
        );
        batch.insert(_database.sessions, companion);
      }
    });
  }
}
