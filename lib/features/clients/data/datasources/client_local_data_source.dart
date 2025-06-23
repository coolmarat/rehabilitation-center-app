import 'package:rehabilitation_center_app/core/database/app_database.dart';

// Абстрактный класс для источника данных клиентов (родители и дети)
abstract class ClientLocalDataSource {
  Future<List<ParentEntry>> getParents();
  Future<ParentEntry> getParentById(int id);
  Future<int> addParent(ParentsCompanion parent);
  Future<bool> updateParent(ParentsCompanion parent);
  Future<int> deleteParent(int id);
  Future<void> updateParentBalance(int parentId, double newBalance);
  Future<int> getParentIdByChildId(int childId);

  Future<List<ChildEntry>> getChildrenForParent(int parentId);
  Future<int> addChild(ChildrenCompanion child);
  Future<bool> updateChild(ChildrenCompanion child);
  Future<int> deleteChild(int id);
}

class ClientLocalDataSourceImpl implements ClientLocalDataSource {
  final ClientDao clientDao;

  ClientLocalDataSourceImpl({required this.clientDao});

  @override
  Future<List<ParentEntry>> getParents() => clientDao.getAllParents();

  @override
  Future<ParentEntry> getParentById(int id) => clientDao.getParentById(id);

  @override
  Future<int> addParent(ParentsCompanion parent) => clientDao.addParent(parent);

  @override
  Future<bool> updateParent(ParentsCompanion parent) => clientDao.updateParent(parent);

  @override
  Future<int> deleteParent(int id) => clientDao.deleteParent(id);

  @override
  Future<void> updateParentBalance(int parentId, double newBalance) =>
      clientDao.updateParentBalance(parentId, newBalance);

  @override
  Future<int> getParentIdByChildId(int childId) => clientDao.getParentIdByChildId(childId);

  @override
  Future<List<ChildEntry>> getChildrenForParent(int parentId) =>
      clientDao.getChildrenForParent(parentId);

  @override
  Future<int> addChild(ChildrenCompanion child) => clientDao.addChild(child);

  @override
  Future<bool> updateChild(ChildrenCompanion child) => clientDao.updateChild(child);

  @override
  Future<int> deleteChild(int id) => clientDao.deleteChild(id);
}


