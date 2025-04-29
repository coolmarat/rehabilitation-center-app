part of 'employee_bloc.dart';

abstract class EmployeeEvent extends Equatable {
  const EmployeeEvent();

  @override
  List<Object> get props => [];
}

// Событие для запроса списка сотрудников
class LoadEmployees extends EmployeeEvent {}

// Событие для добавления сотрудника
class AddEmployeeEvent extends EmployeeEvent {
  final Employee employee;

  const AddEmployeeEvent(this.employee);

  @override
  List<Object> get props => [employee];
}

// Событие для обновления сотрудника
class UpdateEmployeeEvent extends EmployeeEvent {
  final Employee employee;

  const UpdateEmployeeEvent(this.employee);

  @override
  List<Object> get props => [employee];
}

// Событие для удаления сотрудника
class DeleteEmployeeEvent extends EmployeeEvent {
  final int id;

  const DeleteEmployeeEvent(this.id);

  @override
  List<Object> get props => [id];
}
