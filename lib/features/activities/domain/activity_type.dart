import 'package:equatable/equatable.dart';

class ActivityType extends Equatable {
  final int id;
  final String name;
  final String description;
  final double defaultPrice; // Цена по умолчанию

  const ActivityType({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultPrice,
  });

  @override
  List<Object?> get props => [id, name, description, defaultPrice];

  ActivityType copyWith({
    int? id,
    String? name,
    String? description,
    double? defaultPrice,
  }) {
    return ActivityType(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      defaultPrice: defaultPrice ?? this.defaultPrice,
    );
  }
}
