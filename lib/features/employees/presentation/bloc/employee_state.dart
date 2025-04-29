part of 'employee_bloc.dart';

abstract class EmployeeState extends Equatable {
  const EmployeeState();

  @override
  List<Object> get props => [];
}

// Начальное состояние
class EmployeeInitial extends EmployeeState {}

// Состояние загрузки
class EmployeeLoading extends EmployeeState {}

// Состояние успешной загрузки списка сотрудников
class EmployeeLoaded extends EmployeeState {
  final List<Employee> employees;

  const EmployeeLoaded(this.employees);

  @override
  List<Object> get props => [employees];
}

// Состояние успешного выполнения операции (добавление/обновление/удаление)
class EmployeeOperationSuccess extends EmployeeState {
  final String message; // Опциональное сообщение для пользователя
  
  const EmployeeOperationSuccess({this.message = 'Операция выполнена успешно'});

  @override
  List<Object> get props => [message];
}

// Состояние ошибки
class EmployeeError extends EmployeeState {
  final String message;

  const EmployeeError(this.message);

  @override
  List<Object> get props => [message];
}
