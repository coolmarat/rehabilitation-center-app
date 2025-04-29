import 'package:equatable/equatable.dart';

class Employee extends Equatable {
  final int id;
  final String fullName;
  final String position;

  const Employee({
    required this.id,
    required this.fullName,
    required this.position,
  });

  @override
  List<Object?> get props => [id, fullName, position];

  // Добавим метод copyWith для удобства обновления
  Employee copyWith({
    int? id,
    String? fullName,
    String? position,
  }) {
    return Employee(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      position: position ?? this.position,
    );
  }
}
