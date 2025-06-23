part of '../../../../core/database/app_database.dart';

@DriftAccessor(tables: [Children, Parents])
class ClientDao extends DatabaseAccessor<AppDatabase> with _$ClientDaoMixin {
  final AppDatabase db;

  ClientDao(this.db) : super(db);

  // --- Parents ---

  Future<List<ParentEntry>> getAllParents() => select(parents).get();

  Future<ParentEntry> getParentById(int id) =>
      (select(parents)..where((p) => p.id.equals(id))).getSingle();

  Future<int> addParent(ParentsCompanion entry) => into(parents).insert(entry);

  Future<bool> updateParent(ParentsCompanion entry) =>
      update(parents).replace(entry);

  Future<int> deleteParent(int id) =>
      (delete(parents)..where((p) => p.id.equals(id))).go();

  // Новый метод для обновления баланса
  Future<void> updateParentBalance(int parentId, double newBalance) {
    return (update(parents)..where((p) => p.id.equals(parentId)))
        .write(ParentsCompanion(balance: Value(newBalance)));
  }

  // --- Children ---

  Future<List<ChildEntry>> getChildrenForParent(int parentId) =>
      (select(children)..where((c) => c.parentId.equals(parentId))).get();

  Future<int> addChild(ChildrenCompanion entry) => into(children).insert(entry);

  Future<bool> updateChild(ChildrenCompanion entry) =>
      update(children).replace(entry);

  Future<int> deleteChild(int id) =>
      (delete(children)..where((c) => c.id.equals(id))).go();

  Future<int> getParentIdByChildId(int childId) async {
    final query = select(children)..where((c) => c.id.equals(childId));
    final child = await query.getSingleOrNull();
    return child?.parentId ?? -1; // Возвращаем -1 если ребенок не найден
  }
}
