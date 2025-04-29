part of '../app_database.dart';

@DataClassName('ActivityTypeEntry')
class ActivityTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text()(); // Описание может быть длинным
  RealColumn get defaultPrice => real()(); // Используем Real для double
  // Add duration in minutes, non-nullable with default
  IntColumn get durationInMinutes => integer().withDefault(const Constant(0))(); 

  // Дополнительные настройки таблицы, если нужны
}
