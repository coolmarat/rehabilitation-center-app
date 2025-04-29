import 'package:rehabilitation_center_app/core/database/app_database.dart';

// Абстрактный класс для источника данных клиентов (родители и дети)
abstract class ClientLocalDataSource {
  Future<List<ParentEntry>> getParents();
  Future<ParentEntry> getParentById(int id);
  Future<List<ChildEntry>> getChildrenForParent(int parentId);
  // Добавляем метод получения ребенка по ID
  Future<ChildEntry> getChildById(int id);
  Future<int> addParent(ParentsCompanion parent);
  Future<bool> updateParent(ParentEntry parent);
  Future<int> deleteParent(int id);
  Future<int> addChild(ChildrenCompanion child);
  Future<bool> updateChild(ChildEntry child);
  Future<int> deleteChild(int id);
}

// Реализация с использованием Drift
class ClientLocalDataSourceImpl implements ClientLocalDataSource {
  final AppDatabase database;

  ClientLocalDataSourceImpl({required this.database});

  @override
  Future<List<ParentEntry>> getParents() async {
    return await database.select(database.parents).get();
  }

  @override
  Future<ParentEntry> getParentById(int id) async {
    return await (database.select(database.parents)..where((p) => p.id.equals(id))).getSingle();
  }

  @override
  Future<List<ChildEntry>> getChildrenForParent(int parentId) async {
    return await (database.select(database.children)..where((c) => c.parentId.equals(parentId))).get();
  }

  @override
  Future<ChildEntry> getChildById(int id) async {
    return await (database.select(database.children)..where((c) => c.id.equals(id))).getSingle();
  }

  @override
  Future<int> addParent(ParentsCompanion parent) async {
    // Drift автоматически создает Companion для вставки/обновления
    return await database.into(database.parents).insert(parent);
  }

  @override
  Future<bool> updateParent(ParentEntry parent) async {
    return await database.update(database.parents).replace(parent);
  }

  @override
  Future<int> deleteParent(int id) async {
    // Drift автоматически удалит связанных детей благодаря onDelete: KeyAction.cascade
    return await (database.delete(database.parents)..where((p) => p.id.equals(id))).go();
  }

  @override
  Future<int> addChild(ChildrenCompanion child) async {
    return await database.into(database.children).insert(child);
  }

  @override
  Future<bool> updateChild(ChildEntry child) async {
    return await database.update(database.children).replace(child);
  }

  @override
  Future<int> deleteChild(int id) async {
    return await (database.delete(database.children)..where((c) => c.id.equals(id))).go();
  }
}
