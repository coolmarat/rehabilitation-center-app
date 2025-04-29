import 'package:rehabilitation_center_app/core/database/app_database.dart';
import 'package:rehabilitation_center_app/features/employees/data/datasources/employee_local_data_source.dart';
import 'package:rehabilitation_center_app/features/employees/domain/employee.dart';
import 'package:rehabilitation_center_app/features/employees/domain/repositories/employee_repository.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  final EmployeeLocalDataSource localDataSource;

  EmployeeRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Employee>> getEmployees() async {
    final employeeEntries = await localDataSource.getEmployees();
    // Преобразуем EmployeeEntry (Drift) в Employee (Domain)
    return employeeEntries.map((entry) => 
      Employee(id: entry.id, fullName: entry.fullName, position: entry.position)
    ).toList();
  }

  @override
  Future<Employee?> getEmployeeById(int id) async {
    final entry = await localDataSource.getEmployeeById(id);
    if (entry != null) {
      return Employee(id: entry.id, fullName: entry.fullName, position: entry.position);
    } 
    return null;
  }

  @override
  Future<void> addEmployee(Employee employee) async {
    // Преобразуем Employee (Domain) в EmployeesCompanion (Drift для вставки)
    final companion = EmployeesCompanion.insert(
      fullName: employee.fullName,
      position: employee.position,
      // id не указываем, он autoIncrement
    );
    await localDataSource.addEmployee(companion);
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    // Преобразуем Employee (Domain) в EmployeeEntry (Drift для обновления)
    final entry = EmployeeEntry(
      id: employee.id,
      fullName: employee.fullName,
      position: employee.position,
    );
    await localDataSource.updateEmployee(entry);
  }

  @override
  Future<void> deleteEmployee(int id) async {
    await localDataSource.deleteEmployee(id);
  }
}
