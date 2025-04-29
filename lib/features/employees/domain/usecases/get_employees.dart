import 'package:rehabilitation_center_app/features/employees/domain/employee.dart';
import 'package:rehabilitation_center_app/features/employees/domain/repositories/employee_repository.dart';

class GetEmployees {
  final EmployeeRepository repository;

  GetEmployees(this.repository);

  Future<List<Employee>> call() async {
    // В будущем здесь может быть дополнительная бизнес-логика
    return await repository.getEmployees();
  }
}
