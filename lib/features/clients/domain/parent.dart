import 'package:equatable/equatable.dart';

class Parent extends Equatable {
  final int id;
  final String fullName;
  final String phoneNumber;
  final String? email; // Опциональное поле
  final String? address; // Опциональное поле

  const Parent({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    this.address,
  });

  // Equatable для сравнения объектов
  @override
  List<Object?> get props => [id, fullName, phoneNumber, email, address];

  // Метод copyWith для удобного создания копий с измененными полями
  Parent copyWith({
    int? id,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? address,
  }) {
    return Parent(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
    );
  }
}
