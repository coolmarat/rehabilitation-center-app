import 'package:equatable/equatable.dart';

class Child extends Equatable {
  final int id;
  final int parentId; // Внешний ключ для связи с Parent
  final String fullName;
  final DateTime dateOfBirth;
  final String? diagnosis; // Опциональное поле

  const Child({
    required this.id,
    required this.parentId,
    required this.fullName,
    required this.dateOfBirth,
    this.diagnosis,
  });

  @override
  List<Object?> get props => [id, parentId, fullName, dateOfBirth, diagnosis];

  Child copyWith({
    int? id,
    int? parentId,
    String? fullName,
    DateTime? dateOfBirth,
    String? diagnosis,
  }) {
    return Child(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      diagnosis: diagnosis ?? this.diagnosis,
    );
  }
}
