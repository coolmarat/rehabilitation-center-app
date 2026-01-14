part of '../app_database.dart';

@DataClassName('Session')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Каскадное удаление при удалении ребенка
  IntColumn get childId =>
      integer().references(Children, #id, onDelete: KeyAction.cascade)();
  // Каскадное удаление при удалении сотрудника
  IntColumn get employeeId =>
      integer().references(Employees, #id, onDelete: KeyAction.cascade)();
  // Каскадное удаление при удалении типа занятия
  IntColumn get activityTypeId =>
      integer().references(ActivityTypes, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get sessionDateTime => dateTime()();
  TextColumn get notes => text().nullable()();
  RealColumn get price => real()();
  IntColumn get durationMinutes => integer().withDefault(const Constant(60))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  // Новые поля для учета оплат
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  IntColumn get paymentId => integer().nullable().references(Payments, #id)();
}
