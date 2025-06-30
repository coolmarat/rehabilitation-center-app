import 'package:equatable/equatable.dart';

// Модель для представления сессии с деталями (имена, названия)
class SessionDetails extends Equatable {
  final int sessionId;
  final DateTime dateTime;
  final String employeeName;
  final String activityTypeName;
  final String childName;
  final double price;
  final int employeeId;
  final int activityTypeId;
  final int childId;
  final Duration duration;
  final String? notes;
  final bool isCompleted;
  final bool isPaid;

  const SessionDetails({
    required this.sessionId,
    required this.dateTime,
    required this.employeeName,
    required this.activityTypeName,
    required this.childName,
    required this.price,
    required this.employeeId,
    required this.activityTypeId,
    required this.childId,
    required this.duration,
    required this.notes,
    required this.isCompleted,
    required this.isPaid,
  });

  @override
  List<Object?> get props => [
        sessionId,
        dateTime,
        employeeName,
        activityTypeName,
        childName,
        price,
        employeeId,
        activityTypeId,
        childId,
        duration,
        notes,
        isCompleted,
        isPaid,
      ];
}
