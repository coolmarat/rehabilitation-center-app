import 'package:equatable/equatable.dart';

class Parent extends Equatable {
  final int id;
  final String fullName;
  // Можно добавить другие поля, например, контакты
  final String? phoneNumber;
  final String? email;

  const Parent({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    this.email,
  });

  @override
  List<Object?> get props => [id, fullName, phoneNumber, email];

  Parent copyWith({
    int? id,
    String? fullName,
    String? phoneNumber,
    String? email,
  }) {
    return Parent(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
    );
  }
}
