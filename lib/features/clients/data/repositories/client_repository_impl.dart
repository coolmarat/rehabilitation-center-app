import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' show Value;
import 'package:rehabilitation_center_app/core/database/app_database.dart';
import 'package:rehabilitation_center_app/core/errors/failures.dart';
import 'package:rehabilitation_center_app/features/clients/data/datasources/client_local_data_source.dart';
import 'package:rehabilitation_center_app/features/clients/domain/child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class ClientRepositoryImpl implements ClientRepository {
  final ClientLocalDataSource localDataSource;

  ClientRepositoryImpl({required this.localDataSource});

  // --- Mappers ---
  Parent _mapParentEntryToParent(ParentEntry entry) => Parent(
        id: entry.id,
        fullName: entry.fullName,
        phoneNumber: entry.phoneNumber,
        email: entry.email,
        address: entry.address,
        balance: entry.balance,
      );

  ParentsCompanion _mapParentToCompanion(Parent parent) => ParentsCompanion(
        id: parent.id == 0 ? const Value.absent() : Value(parent.id),
        fullName: Value(parent.fullName),
        phoneNumber: Value(parent.phoneNumber),
        email: Value(parent.email),
        address: Value(parent.address),
        balance: Value(parent.balance),
      );

  Child _mapChildEntryToChild(ChildEntry entry) => Child(
        id: entry.id,
        parentId: entry.parentId,
        fullName: entry.fullName,
        dateOfBirth: entry.dateOfBirth,
        diagnosis: entry.diagnosis,
      );

  ChildrenCompanion _mapChildToCompanion(Child child) => ChildrenCompanion(
        id: child.id == 0 ? const Value.absent() : Value(child.id),
        parentId: Value(child.parentId),
        fullName: Value(child.fullName),
        dateOfBirth: Value(child.dateOfBirth),
        diagnosis: Value(child.diagnosis),
      );

  // --- Repository Methods ---

  Future<Either<Failure, T>> _tryCatch<T>(
      Future<T> Function() function) async {
    try {
      final result = await function();
      return Right(result);
    } catch (e) {
      // In a real app, you'd log the error e
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Parent>> addParent(Parent parent) {
    return _tryCatch(() async {
      final companion = _mapParentToCompanion(parent);
      final newId = await localDataSource.addParent(companion);
      return parent.copyWith(id: newId);
    });
  }

  @override
  Future<Either<Failure, Child>> addChild(Child child) {
    return _tryCatch(() async {
      final companion = _mapChildToCompanion(child);
      final newId = await localDataSource.addChild(companion);
      return child.copyWith(id: newId);
    });
  }

  @override
  Future<Either<Failure, void>> deleteParent(int id) {
    return _tryCatch(() => localDataSource.deleteParent(id));
  }

  @override
  Future<Either<Failure, void>> deleteChild(int id) {
    return _tryCatch(() => localDataSource.deleteChild(id));
  }

  @override
  Future<Either<Failure, Map<Parent, List<Child>>>> getAllParentsWithChildren() {
    return _tryCatch(() async {
      final parentEntries = await localDataSource.getParents();
      final parents = parentEntries.map(_mapParentEntryToParent).toList();
      final Map<Parent, List<Child>> result = {};
      for (final parent in parents) {
        final childEntries = await localDataSource.getChildrenForParent(parent.id);
        final children = childEntries.map(_mapChildEntryToChild).toList();
        result[parent] = children;
      }
      return result;
    });
  }

  @override
  Future<Either<Failure, Parent>> getParentById(int id) {
    return _tryCatch(() async {
      final entry = await localDataSource.getParentById(id);
      return _mapParentEntryToParent(entry);
    });
  }

  @override
  Future<Either<Failure, int>> getParentIdByChildId(int childId) {
    return _tryCatch(() => localDataSource.getParentIdByChildId(childId));
  }

  @override
  Future<Either<Failure, void>> updateParent(Parent parent) {
    return _tryCatch(() {
      final companion = _mapParentToCompanion(parent);
      return localDataSource.updateParent(companion);
    });
  }

  @override
  Future<Either<Failure, void>> updateParentBalance(
      {required int parentId, required double amount}) {
    return _tryCatch(() async {
      final parentEither = await getParentById(parentId);
      return parentEither.fold(
        (failure) => throw failure, // Propagate failure
        (parent) async {
          final newBalance = parent.balance + amount;
          await localDataSource.updateParentBalance(parentId, newBalance);
        },
      );
    });
  }

  @override
  Future<Either<Failure, void>> updateChild(Child child) {
    return _tryCatch(() {
      final companion = _mapChildToCompanion(child);
      return localDataSource.updateChild(companion);
    });
  }
}
