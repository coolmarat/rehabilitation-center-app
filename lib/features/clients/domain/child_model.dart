import 'package:equatable/equatable.dart';

class Child extends Equatable {
  final int id;
  final String fullName;
  final DateTime dateOfBirth; // Дата рождения
  final int parentId; // Ссылка на родителя
  // Можно добавить другие поля, например, особенности развития

  const Child({
    required this.id,
    required this.fullName,
    required this.dateOfBirth,
    required this.parentId,
  });

  @override
  List<Object?> get props => [id, fullName, dateOfBirth, parentId];

  Child copyWith({
    int? id,
    String? fullName,
    DateTime? dateOfBirth,
    int? parentId,
  }) {
    return Child(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      parentId: parentId ?? this.parentId,
    );
  }
}
