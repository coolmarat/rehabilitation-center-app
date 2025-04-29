import 'package:rehabilitation_center_app/core/database/app_database.dart';

// Абстрактный класс для источника данных
abstract class EmployeeLocalDataSource {
  Future<List<EmployeeEntry>> getEmployees();
  Future<EmployeeEntry?> getEmployeeById(int id);
  Future<int> addEmployee(EmployeesCompanion employeeData); // Возвращает ID добавленной записи
  Future<bool> updateEmployee(EmployeeEntry employeeData); // Возвращает true если успешно
  Future<int> deleteEmployee(int id); // Возвращает кол-во удаленных строк
}

// Реализация источника данных с использованием Drift
class EmployeeLocalDataSourceImpl implements EmployeeLocalDataSource {
  final AppDatabase database;

  EmployeeLocalDataSourceImpl({required this.database});

  @override
  Future<List<EmployeeEntry>> getEmployees() async {
    return await database.select(database.employees).get();
  }

  @override
  Future<EmployeeEntry?> getEmployeeById(int id) async {
    return await (database.select(database.employees)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<int> addEmployee(EmployeesCompanion employeeData) async {
    // Drift автоматически обработает autoIncrement id
    return await database.into(database.employees).insert(employeeData);
  }

  @override
  Future<bool> updateEmployee(EmployeeEntry employeeData) async {
    return await database.update(database.employees).replace(employeeData);
  }

  @override
  Future<int> deleteEmployee(int id) async {
    return await (database.delete(database.employees)..where((tbl) => tbl.id.equals(id))).go();
  }
}
