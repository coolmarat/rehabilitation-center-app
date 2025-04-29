import 'package:equatable/equatable.dart';

class ActivityType extends Equatable {
  final int id;
  final String name;
  final String description;
  final double defaultPrice;
  final int durationInMinutes;

  const ActivityType({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultPrice,
    required this.durationInMinutes,
  });

  // Если нам нужен экземпляр без ID (для создания нового типа)
  const ActivityType.noId({
    required this.name,
    required this.description,
    required this.defaultPrice,
    required this.durationInMinutes,
  }) : id = 0; // Используем 0 или другое значение, указывающее на отсутствие ID

  @override
  List<Object?> get props => [id, name, description, defaultPrice, durationInMinutes];

  // Метод copyWith для удобного обновления
  ActivityType copyWith({
    int? id,
    String? name,
    String? description,
    double? defaultPrice,
    int? durationInMinutes,
  }) {
    return ActivityType(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      defaultPrice: defaultPrice ?? this.defaultPrice,
      durationInMinutes: durationInMinutes ?? this.durationInMinutes,
    );
  }
}
