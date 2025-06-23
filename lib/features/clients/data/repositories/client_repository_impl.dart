import 'package:drift/drift.dart' show Value;
import 'package:rehabilitation_center_app/core/database/app_database.dart';
import 'package:rehabilitation_center_app/features/clients/data/datasources/client_local_data_source.dart';
import 'package:rehabilitation_center_app/features/clients/domain/child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class ClientRepositoryImpl implements ClientRepository {
  final ClientLocalDataSource localDataSource;

  ClientRepositoryImpl({required this.localDataSource});

  // --- Мапперы --- 
  Parent _mapParentEntryToParent(ParentEntry entry) {
    return Parent(
      id: entry.id,
      fullName: entry.fullName,
      phoneNumber: entry.phoneNumber,
      email: entry.email,
      address: entry.address,
      balance: entry.balance,
    );
  }

  ParentsCompanion _mapParentToCompanion(Parent parent) {
    return ParentsCompanion(
      id: parent.id == 0 ? const Value.absent() : Value(parent.id), // ID не передаем при создании
      fullName: Value(parent.fullName),
      phoneNumber: Value(parent.phoneNumber),
      email: Value(parent.email),
      address: Value(parent.address),
      balance: Value(parent.balance),
    );
  }

  Child _mapChildEntryToChild(ChildEntry entry) {
    return Child(
      id: entry.id,
      parentId: entry.parentId,
      fullName: entry.fullName,
      dateOfBirth: entry.dateOfBirth,
      diagnosis: entry.diagnosis,
    );
  }

  ChildrenCompanion _mapChildToCompanion(Child child) {
    return ChildrenCompanion(
      id: child.id == 0 ? const Value.absent() : Value(child.id),
      parentId: Value(child.parentId),
      fullName: Value(child.fullName),
      dateOfBirth: Value(child.dateOfBirth),
      diagnosis: Value(child.diagnosis),
    );
  }

  // --- Методы репозитория --- 

  @override
  Future<List<Parent>> getParents() async {
    final entries = await localDataSource.getParents();
    return entries.map(_mapParentEntryToParent).toList();
  }

  @override
  Future<Parent> getParentById(int id) async {
    final entry = await localDataSource.getParentById(id);
    return _mapParentEntryToParent(entry);
  }

  @override
  Future<List<Child>> getChildrenForParent(int parentId) async {
    final entries = await localDataSource.getChildrenForParent(parentId);
    return entries.map(_mapChildEntryToChild).toList();
  }

  @override
  Future<Parent> addParent(Parent parent) async {
    final companion = _mapParentToCompanion(parent);
    final newId = await localDataSource.addParent(companion);
    return parent.copyWith(id: newId); // Возвращаем родителя с присвоенным ID
  }

  @override
  Future<void> updateParent(Parent parent) async {
    final companion = _mapParentToCompanion(parent);
    await localDataSource.updateParent(companion);
  }

  @override
  Future<void> deleteParent(int id) async {
    await localDataSource.deleteParent(id);
  }

  @override
  Future<Child> addChild(Child child) async {
    final companion = _mapChildToCompanion(child);
    final newId = await localDataSource.addChild(companion);
    return child.copyWith(id: newId);
  }

  @override
  Future<void> updateChild(Child child) async {
    final companion = _mapChildToCompanion(child);
    await localDataSource.updateChild(companion);
  }

  @override
  Future<void> deleteChild(int id) async {
    await localDataSource.deleteChild(id);
  }

  @override
  Future<Map<Parent, List<Child>>> getAllParentsWithChildren() async {
    final parents = await getParents();
    final Map<Parent, List<Child>> result = {};
    for (final parent in parents) {
      final children = await getChildrenForParent(parent.id);
      result[parent] = children;
    }
    return result;
  }

  @override
  Future<void> updateParentBalance(int parentId, double amount) async {
    final parent = await getParentById(parentId);
    final newBalance = parent.balance - amount;
    await localDataSource.updateParentBalance(parentId, newBalance);
  }

  @override
  Future<int> getParentIdByChildId(int childId) {
    return localDataSource.getParentIdByChildId(childId);
  }
}
