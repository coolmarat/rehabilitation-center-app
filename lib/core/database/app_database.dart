import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part '../../features/clients/data/datasources/client_dao.dart';
part '../../features/payments/data/datasources/payment_dao.dart';
part '../../features/schedule/data/datasources/schedule_dao.dart';
part 'app_database.g.dart';
part 'tables/activity_types.dart';
part 'tables/children.dart';
part 'tables/employees.dart';
part 'tables/parents.dart';
part 'tables/payments.dart';
part 'tables/sessions.dart';

// Класс для хранения результатов финансового отчета
class FinanceReportResult {
  final String employeeName;
  final double totalAmount;

  FinanceReportResult({required this.employeeName, required this.totalAmount});
}

@DriftDatabase(
  tables: [Children, Parents, Employees, ActivityTypes, Sessions, Payments],
  daos: [ScheduleDao, ClientDao, PaymentDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Эти миграции основаны на предыдущей структуре проекта
          await m.addColumn(parents, parents.address);
        }
        if (from < 3) {
          await m.addColumn(children, children.diagnosis);
        }
        if (from < 4) {
          await m.addColumn(activityTypes, activityTypes.durationInMinutes);
        }
        if (from < 5) {
          await m.createTable(payments);
          await m.addColumn(sessions, sessions.isPaid);
          await m.addColumn(sessions, sessions.paymentId);
        }
        if (from < 6) {
          await m.addColumn(parents, parents.balance);
        }
        if (from < 7) {
          // Миграция для добавления каскадного удаления
          // SQLite не поддерживает ALTER CONSTRAINT, поэтому пересоздаем таблицы
          await _migrateForCascadeDelete(m);
        }
      },
      beforeOpen: (details) async {
        // Включаем поддержку внешних ключей (по умолчанию отключена в SQLite)
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Миграция для пересоздания таблиц с каскадным удалением
  Future<void> _migrateForCascadeDelete(Migrator m) async {
    // 1. Пересоздаем таблицу payments с правильной ссылкой на parents
    await customStatement('''
      CREATE TABLE payments_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL REFERENCES parents(id) ON DELETE CASCADE,
        payment_date INTEGER NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        session_count INTEGER NOT NULL,
        used_sessions INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await customStatement('''
      INSERT INTO payments_new (id, client_id, payment_date, amount, type, session_count, used_sessions)
      SELECT id, client_id, payment_date, amount, type, session_count, used_sessions FROM payments
    ''');
    await customStatement('DROP TABLE payments');
    await customStatement('ALTER TABLE payments_new RENAME TO payments');

    // 2. Пересоздаем таблицу sessions с каскадным удалением
    await customStatement('''
      CREATE TABLE sessions_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        child_id INTEGER NOT NULL REFERENCES children(id) ON DELETE CASCADE,
        employee_id INTEGER NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
        activity_type_id INTEGER NOT NULL REFERENCES activity_types(id) ON DELETE CASCADE,
        session_date_time INTEGER NOT NULL,
        notes TEXT,
        price REAL NOT NULL,
        duration_minutes INTEGER NOT NULL DEFAULT 60,
        is_completed INTEGER NOT NULL DEFAULT 0,
        is_paid INTEGER NOT NULL DEFAULT 0,
        payment_id INTEGER REFERENCES payments(id)
      )
    ''');
    await customStatement('''
      INSERT INTO sessions_new (id, child_id, employee_id, activity_type_id, session_date_time, notes, price, duration_minutes, is_completed, is_paid, payment_id)
      SELECT id, child_id, employee_id, activity_type_id, session_date_time, notes, price, duration_minutes, is_completed, is_paid, payment_id FROM sessions
    ''');
    await customStatement('DROP TABLE sessions');
    await customStatement('ALTER TABLE sessions_new RENAME TO sessions');

    // 3. Пересоздаем таблицу children с каскадным удалением
    await customStatement('''
      CREATE TABLE children_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        date_of_birth INTEGER NOT NULL,
        parent_id INTEGER NOT NULL REFERENCES parents(id) ON DELETE CASCADE,
        diagnosis TEXT
      )
    ''');
    await customStatement('''
      INSERT INTO children_new (id, full_name, date_of_birth, parent_id, diagnosis)
      SELECT id, full_name, date_of_birth, parent_id, diagnosis FROM children
    ''');
    await customStatement('DROP TABLE children');
    await customStatement('ALTER TABLE children_new RENAME TO children');
  }

  // --- Методы для получения данных ---

  Future<List<EmployeeEntry>> getAllEmployees() => select(employees).get();

  Future<List<FinanceReportResult>> getFinanceReport({
    required DateTime start,
    required DateTime end,
    int? employeeId,
  }) {
    final query = select(
      sessions,
    ).join([innerJoin(employees, employees.id.equalsExp(sessions.employeeId))]);

    query.where(sessions.sessionDateTime.isBetweenValues(start, end));

    if (employeeId != null) {
      query.where(sessions.employeeId.equals(employeeId));
    }

    final employeeName = employees.fullName;
    final totalAmount = sessions.price.sum();

    query
      ..groupBy([employees.id])
      ..addColumns([employeeName, totalAmount]);

    return query.map((row) {
      return FinanceReportResult(
        employeeName: row.read(employeeName)!,
        totalAmount: row.read(totalAmount) ?? 0.0,
      );
    }).get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
