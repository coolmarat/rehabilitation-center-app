part of '../../../../core/database/app_database.dart';

@DriftAccessor(tables: [Payments, Sessions, Children, ActivityTypes, Employees])
class PaymentDao extends DatabaseAccessor<AppDatabase> with _$PaymentDaoMixin {
  PaymentDao(AppDatabase db) : super(db);

  // Рассчитывает баланс занятий для клиента (ребенка)
  Future<int> getClientSessionBalance(int clientId) async {
    // 1. Считаем общее количество купленных сессий
    final totalPaidSessions = await (select(payments)
      ..where((p) => p.clientId.equals(clientId))).get().then(
      (rows) => rows.fold<int>(0, (sum, row) => sum + row.sessionCount),
    );

    // 2. Считаем общее количество использованных сессий
    final totalUsedSessions = await (select(payments)
      ..where((p) => p.clientId.equals(clientId))).get().then(
      (rows) => rows.fold<int>(0, (sum, row) => sum + row.usedSessions),
    );

    // 3. Считаем количество неоплаченных сессий в расписании
    final unpaidScheduledSessions = await (select(sessions)..where(
      (s) => s.childId.equals(clientId) & s.isPaid.equals(false),
    )).get().then((rows) => rows.length);

    // Итоговый баланс
    final balance =
        totalPaidSessions - totalUsedSessions - unpaidScheduledSessions;
    return balance;
  }

  // Новый метод: рассчитывает баланс для родителя по его ID
  Future<int> getParentSessionBalance(int parentId) async {
    // 1. Получаем всех детей данного родителя
    final childrenQuery = select(children)
      ..where((c) => c.parentId.equals(parentId));
    final childrenList = await childrenQuery.get();

    if (childrenList.isEmpty) {
      print('No children found for parent ID: $parentId');
      return 0; // Если у родителя нет детей, баланс 0
    }

    // 2. Считаем общее количество купленных сессий для родителя
    final totalPaidSessions = await (select(payments)
      ..where((p) => p.clientId.equals(parentId))).get().then(
      (rows) => rows.fold<int>(0, (sum, row) => sum + row.sessionCount),
    );

    // 3. Считаем общее количество использованных сессий для родителя
    final totalUsedSessions = await (select(payments)
      ..where((p) => p.clientId.equals(parentId))).get().then(
      (rows) => rows.fold<int>(0, (sum, row) => sum + row.usedSessions),
    );

    // 4. Считаем количество неоплаченных сессий в расписании для всех детей
    int unpaidScheduledSessions = 0;

    for (final child in childrenList) {
      final childSessions =
          await (select(sessions)..where(
            (s) => s.childId.equals(child.id) & s.isPaid.equals(false),
          )).get();
      unpaidScheduledSessions += childSessions.length;
    }

    // Итоговый баланс родителя
    final balance =
        totalPaidSessions - totalUsedSessions - unpaidScheduledSessions;
    print(
      'Parent balance calculation for ID $parentId: $totalPaidSessions - $totalUsedSessions - $unpaidScheduledSessions = $balance',
    );
    return balance;
  }

  /// Записывает пополнение баланса как Payment-запись.
  Future<int> insertTopUp(int parentId, double amount) {
    return into(payments).insert(
      PaymentsCompanion.insert(
        clientId: parentId,
        paymentDate: DateTime.now(),
        amount: amount,
        type: 'topup',
        sessionCount: 0,
      ),
    );
  }

  /// Обновляет сумму пополнения и пересчитывает баланс родителя.
  Future<void> updateTopUpAmount(
    int paymentId,
    int parentId,
    double oldAmount,
    double newAmount,
  ) async {
    return transaction(() async {
      // 1. Обновляем сумму платежа
      await (update(payments)..where(
        (p) => p.id.equals(paymentId),
      )).write(PaymentsCompanion(amount: Value(newAmount)));

      // 2. Вычисляем разницу
      final difference = newAmount - oldAmount;

      // 3. Обновляем баланс родителя
      // Получаем текущего родителя (используем таблицу parents из AppDatabase)
      final parentQuery = select(db.parents)
        ..where((p) => p.id.equals(parentId));
      final parent = await parentQuery.getSingle();

      final newBalance = parent.balance + difference;
      await (update(db.parents)..where(
        (p) => p.id.equals(parentId),
      )).write(ParentsCompanion(balance: Value(newBalance)));
    });
  }

  /// Возвращает все пополнения (платежи) родителя.
  Future<List<Payment>> getPaymentsForParent(int parentId) =>
      (select(payments)
            ..where((p) => p.clientId.equals(parentId))
            ..orderBy([(p) => OrderingTerm.desc(p.paymentDate)]))
          .get();

  /// Возвращает все занятия для списка детей (по ID) с данными о ребёнке и типе занятия.
  /// Баланс списывается при создании занятия, поэтому возвращаем все.
  Future<List<TypedResult>> getSessionsForParentChildren(
    List<int> childIds,
  ) async {
    if (childIds.isEmpty) return [];
    final query = select(sessions).join([
      innerJoin(children, children.id.equalsExp(sessions.childId)),
      innerJoin(
        activityTypes,
        activityTypes.id.equalsExp(sessions.activityTypeId),
      ),
    ]);
    query
      ..where(sessions.childId.isIn(childIds))
      ..orderBy([OrderingTerm.desc(sessions.sessionDateTime)]);
    return query.get();
  }
}
