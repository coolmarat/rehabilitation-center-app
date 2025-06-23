part of '../app_database.dart';

@DataClassName('Session')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get childId => integer().customConstraint('REFERENCES children(id)')();
  IntColumn get employeeId =>
      integer().customConstraint('REFERENCES employees(id)')();
  IntColumn get activityTypeId =>
      integer().customConstraint('REFERENCES activity_types(id)')();
  DateTimeColumn get sessionDateTime => dateTime()();
  TextColumn get notes => text().nullable()();
  RealColumn get price => real()();
  IntColumn get durationMinutes => integer().withDefault(const Constant(60))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  // Новые поля для учета оплат
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  IntColumn get paymentId =>
      integer().nullable().customConstraint('NULLABLE REFERENCES payments(id)')();
}

