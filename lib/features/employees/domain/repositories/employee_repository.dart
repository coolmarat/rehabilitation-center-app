import 'package:rehabilitation_center_app/features/employees/domain/employee.dart';

abstract class EmployeeRepository {
  // Получить список всех сотрудников
  Future<List<Employee>> getEmployees();

  // Получить сотрудника по ID (может понадобиться позже)
  Future<Employee?> getEmployeeById(int id);

  // Добавить нового сотрудника
  Future<void> addEmployee(Employee employee); 

  // Обновить существующего сотрудника
  Future<void> updateEmployee(Employee employee);

  // Удалить сотрудника
  Future<void> deleteEmployee(int id);
}
