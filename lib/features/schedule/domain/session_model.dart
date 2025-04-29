import 'package:equatable/equatable.dart';

class Session extends Equatable {
  final int id;
  final int activityTypeId;
  final int employeeId;
  final int childId;
  final DateTime dateTime; // Дата и время начала занятия
  final Duration duration; // Продолжительность занятия (например, 45 минут)
  final double price; // Фактическая цена занятия
  final bool isCompleted; // Статус: проведено или запланировано
  final String? notes; // Дополнительные заметки

  const Session({
    required this.id,
    required this.activityTypeId,
    required this.employeeId,
    required this.childId,
    required this.dateTime,
    required this.duration,
    required this.price,
    this.isCompleted = false,
    this.notes,
  });

  // Рассчитываем время окончания занятия
  DateTime get endDateTime => dateTime.add(duration);

  @override
  List<Object?> get props => [
        id,
        activityTypeId,
        employeeId,
        childId,
        dateTime,
        duration,
        price,
        isCompleted,
        notes,
      ];

  Session copyWith({
    int? id,
    int? activityTypeId,
    int? employeeId,
    int? childId,
    DateTime? dateTime,
    Duration? duration,
    double? price,
    bool? isCompleted,
    String? notes,
    bool clearNotes = false, // Флаг для очистки заметок
  }) {
    return Session(
      id: id ?? this.id,
      activityTypeId: activityTypeId ?? this.activityTypeId,
      employeeId: employeeId ?? this.employeeId,
      childId: childId ?? this.childId,
      dateTime: dateTime ?? this.dateTime,
      duration: duration ?? this.duration,
      price: price ?? this.price,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: clearNotes ? null : notes ?? this.notes,
    );
  }
}
