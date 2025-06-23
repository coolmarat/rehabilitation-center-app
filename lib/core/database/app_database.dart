import 'package:drift/drift.dart';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'tables/children.dart';
part 'tables/employees.dart';
part 'tables/activity_types.dart';
part 'tables/sessions.dart';
part 'tables/payments.dart';
part 'tables/parents.dart';

part '../../features/schedule/data/datasources/schedule_dao.dart';
part '../../features/clients/data/datasources/client_dao.dart';
part '../../features/payments/data/datasources/payment_dao.dart';
part 'app_database.g.dart';

// Класс для хранения результатов финансового отчета
class FinanceReportResult {
  final String employeeName;
  final double totalAmount;

  FinanceReportResult({required this.employeeName, required this.totalAmount});
}

@DriftDatabase(tables: [
  Children,
  Parents,
  Employees,
  ActivityTypes,
  Sessions,
  Payments
], daos: [
  ScheduleDao,
  ClientDao,
  PaymentDao
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

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
      },
    );
  }

  // --- Методы для получения данных ---

  Future<List<EmployeeEntry>> getAllEmployees() => select(employees).get();

  Future<List<FinanceReportResult>> getFinanceReport({
    required DateTime start,
    required DateTime end,
    int? employeeId,
  }) {
    final query = select(sessions).join([
      innerJoin(employees, employees.id.equalsExp(sessions.employeeId)),
    ]);

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
