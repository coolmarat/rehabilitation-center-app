import 'package:rehabilitation_center_app/features/employees/domain/employee.dart';
import 'package:rehabilitation_center_app/features/employees/domain/repositories/employee_repository.dart';

class AddEmployee {
  final EmployeeRepository repository;

  AddEmployee(this.repository);

  Future<void> call(Employee employee) async {
    // В будущем здесь может быть валидация или другая логика
    // При добавлении, id обычно игнорируется или равен 0, 
    // база данных присвоит реальный id.
    // Возможно, стоит передавать не весь Employee, а данные для его создания.
    return await repository.addEmployee(employee);
  }
}
