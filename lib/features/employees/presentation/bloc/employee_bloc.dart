import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rehabilitation_center_app/features/employees/domain/employee.dart';
import 'package:rehabilitation_center_app/features/employees/domain/usecases/get_employees.dart';
import 'package:rehabilitation_center_app/features/employees/domain/usecases/add_employee.dart';
import 'package:rehabilitation_center_app/features/employees/domain/usecases/update_employee.dart';
import 'package:rehabilitation_center_app/features/employees/domain/usecases/delete_employee.dart';

part 'employee_event.dart';
part 'employee_state.dart';

class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  final GetEmployees getEmployees;
  final AddEmployee addEmployee;
  final UpdateEmployee updateEmployee;
  final DeleteEmployee deleteEmployee;

  EmployeeBloc({
    required this.getEmployees,
    required this.addEmployee,
    required this.updateEmployee,
    required this.deleteEmployee,
  }) : super(EmployeeInitial()) {
    on<LoadEmployees>(_onLoadEmployees);
    on<AddEmployeeEvent>(_onAddEmployee);
    on<UpdateEmployeeEvent>(_onUpdateEmployee);
    on<DeleteEmployeeEvent>(_onDeleteEmployee);
  }

  Future<void> _onLoadEmployees(
    LoadEmployees event,
    Emitter<EmployeeState> emit,
  ) async {
    emit(EmployeeLoading());
    try {
      final employees = await getEmployees();
      emit(EmployeeLoaded(employees));
    } catch (e) {
      emit(EmployeeError('Не удалось загрузить сотрудников: ${e.toString()}'));
    }
  }

  Future<void> _onAddEmployee(
    AddEmployeeEvent event,
    Emitter<EmployeeState> emit,
  ) async {
    // Можно показать индикатор загрузки, если операция долгая
    // emit(EmployeeLoading()); 
    try {
      await addEmployee(event.employee);
      emit(const EmployeeOperationSuccess(message: 'Сотрудник добавлен'));
      // После успешного добавления, снова загружаем список
      add(LoadEmployees()); 
    } catch (e) {
      emit(EmployeeError('Не удалось добавить сотрудника: ${e.toString()}'));
      // Если предыдущее состояние было EmployeeLoaded, можно вернуться к нему
      // или просто оставить ошибку
    }
  }

  Future<void> _onUpdateEmployee(
    UpdateEmployeeEvent event,
    Emitter<EmployeeState> emit,
  ) async {
    try {
      await updateEmployee(event.employee);
      emit(const EmployeeOperationSuccess(message: 'Данные сотрудника обновлены'));
      add(LoadEmployees()); // Перезагружаем список
    } catch (e) {
      emit(EmployeeError('Не удалось обновить сотрудника: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteEmployee(
    DeleteEmployeeEvent event,
    Emitter<EmployeeState> emit,
  ) async {
    try {
      await deleteEmployee(event.id);
      emit(const EmployeeOperationSuccess(message: 'Сотрудник удален'));
      add(LoadEmployees()); // Перезагружаем список
    } catch (e) {
      emit(EmployeeError('Не удалось удалить сотрудника: ${e.toString()}'));
    }
  }
}
