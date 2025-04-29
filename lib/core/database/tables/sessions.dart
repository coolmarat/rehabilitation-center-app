part of '../app_database.dart';

@DataClassName('SessionEntry')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Renamed from dateTime to sessionDateTime to avoid conflict with Table.dateTime
  DateTimeColumn get sessionDateTime => dateTime()(); 
  IntColumn get durationMinutes => integer()(); // Храним длительность в минутах
  RealColumn get price => real()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))(); // Restored withDefault
  TextColumn get notes => text().nullable()();

  // Внешние ключи (Restored onDelete clauses)
  IntColumn get activityTypeId => integer().references(ActivityTypes, #id,
      onDelete: KeyAction.restrict)(); 
  IntColumn get employeeId => integer().references(Employees, #id,
      onDelete: KeyAction.restrict)(); 
  IntColumn get childId => integer().references(Children, #id,
      onDelete: KeyAction.cascade)(); 
}
