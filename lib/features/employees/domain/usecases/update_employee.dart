import 'package:rehabilitation_center_app/features/employees/domain/employee.dart';
import 'package:rehabilitation_center_app/features/employees/domain/repositories/employee_repository.dart';

class UpdateEmployee {
  final EmployeeRepository repository;

  UpdateEmployee(this.repository);

  Future<void> call(Employee employee) async {
    // В будущем здесь может быть валидация или другая логика
    // Убедиться, что у employee есть валидный id
    if (employee.id <= 0) {
      throw ArgumentError('Employee ID must be valid for update.');
    }
    return await repository.updateEmployee(employee);
  }
}
