part of '../app_database.dart';

@DataClassName('Payment')
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get clientId =>
      integer().customConstraint('REFERENCES children(id)')();
  DateTimeColumn get paymentDate => dateTime()();
  RealColumn get amount => real()();

  /// Тип платежа: 'single' для разового, 'subscription' для абонемента.
  TextColumn get type => text()();

  /// Количество занятий в абонементе (для разовых будет 1).
  IntColumn get sessionCount => integer()();

  /// Количество уже использованных занятий из абонемента.
  IntColumn get usedSessions => integer().withDefault(const Constant(0))();
}
