part of '../../../../core/database/app_database.dart';

@DriftAccessor(tables: [Payments, Sessions, Children])
class PaymentDao extends DatabaseAccessor<AppDatabase> with _$PaymentDaoMixin {
  PaymentDao(AppDatabase db) : super(db);

  // Рассчитывает баланс занятий для клиента (ребенка)
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
  
  // Новый метод: рассчитывает баланс для родителя по его ID
  Future<int> getParentSessionBalance(int parentId) async {
    // 1. Получаем всех детей данного родителя
    final childrenQuery = select(children)..where((c) => c.parentId.equals(parentId));
    final childrenList = await childrenQuery.get();
    
    if (childrenList.isEmpty) {
      print('No children found for parent ID: $parentId');
      return 0; // Если у родителя нет детей, баланс 0
    }
    
    // 2. Считаем общее количество купленных сессий для родителя
    final totalPaidSessions = await (select(payments)
          ..where((p) => p.clientId.equals(parentId)))
        .get()
        .then((rows) => rows.fold<int>(0, (sum, row) => sum + row.sessionCount));

    // 3. Считаем общее количество использованных сессий для родителя
    final totalUsedSessions = await (select(payments)
          ..where((p) => p.clientId.equals(parentId)))
        .get()
        .then((rows) => rows.fold<int>(0, (sum, row) => sum + row.usedSessions));

    // 4. Считаем количество неоплаченных сессий в расписании для всех детей
    int unpaidScheduledSessions = 0;
    
    for (final child in childrenList) {
      final childSessions = await (select(sessions)
            ..where((s) => s.childId.equals(child.id) & s.isPaid.equals(false)))
          .get();
      unpaidScheduledSessions += childSessions.length;
    }

    // Итоговый баланс родителя
    final balance = totalPaidSessions - totalUsedSessions - unpaidScheduledSessions;
    print('Parent balance calculation for ID $parentId: $totalPaidSessions - $totalUsedSessions - $unpaidScheduledSessions = $balance');
    return balance;
  }
}
