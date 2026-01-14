import 'package:equatable/equatable.dart';

import '../../../activity_types/domain/activity_type.dart';
import '../../../clients/domain/child.dart';
import '../../../clients/domain/parent.dart';
import '../../../employees/domain/employee.dart';

// Модель для хранения данных, необходимых для формы (списки)
class ScheduleFormData extends Equatable {
  final List<Employee> employees;
  final List<ActivityType> activityTypes;
  final List<Child> children;
  final List<Parent> parents;

  const ScheduleFormData({
    required this.employees,
    required this.activityTypes,
    required this.children,
    required this.parents,
  });

  @override
  List<Object?> get props => [employees, activityTypes, children, parents];

  // Можно добавить isEmpty getter для удобства
  bool get isEmpty =>
      employees.isEmpty || activityTypes.isEmpty || children.isEmpty;

  // Получить детей для конкретного родителя
  List<Child> getChildrenForParent(int parentId) {
    return children.where((child) => child.parentId == parentId).toList();
  }
}
