import 'package:rehabilitation_center_app/features/employees/domain/repositories/employee_repository.dart';

class DeleteEmployee {
  final EmployeeRepository repository;

  DeleteEmployee(this.repository);

  Future<void> call(int id) async {
    // В будущем здесь может быть проверка прав доступа или другая логика
    if (id <= 0) {
      throw ArgumentError('Employee ID must be valid for delete.');
    }
    return await repository.deleteEmployee(id);
  }
}
