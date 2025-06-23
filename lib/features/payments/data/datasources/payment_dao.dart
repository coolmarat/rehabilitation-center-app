part of '../../../../core/database/app_database.dart';

@DriftAccessor(tables: [Payments, Sessions])
class PaymentDao extends DatabaseAccessor<AppDatabase> with _$PaymentDaoMixin {
  PaymentDao(AppDatabase db) : super(db);

  // Рассчитывает баланс занятий для клиента
  Future<int> getClientSessionBalance(int clientId) async {
    // 1. Считаем общее количество купленных сессий
    final totalPaidSessions = await (select(payments)
          ..where((p) => p.clientId.equals(clientId)))
        .get()
        .then((rows) => rows.fold<int>(0, (sum, row) => sum + row.sessionCount));

    // 2. Считаем общее количество использованных сессий
    final totalUsedSessions = await (select(payments)
          ..where((p) => p.clientId.equals(clientId)))
        .get()
        .then((rows) => rows.fold<int>(0, (sum, row) => sum + row.usedSessions));

    // 3. Считаем количество неоплаченных сессий в расписании
    final unpaidScheduledSessions = await (select(sessions)
          ..where((s) => s.childId.equals(clientId) & s.isPaid.equals(false)))
        .get()
        .then((rows) => rows.length);

    // Итоговый баланс
    final balance = totalPaidSessions - totalUsedSessions - unpaidScheduledSessions;
    return balance;
  }
}
