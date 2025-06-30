import 'package:dartz/dartz.dart';
import 'package:rehabilitation_center_app/core/errors/failures.dart';
import 'package:rehabilitation_center_app/features/clients/domain/parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/child.dart';

// Абстрактный репозиторий для клиентов
abstract class ClientRepository {
  Future<Either<Failure, Map<Parent, List<Child>>>> getAllParentsWithChildren();

  Future<Either<Failure, Parent>> getParentById(int parentId);

  Future<Either<Failure, Parent>> addParent(Parent parent);

  Future<Either<Failure, void>> updateParent(Parent parent);

  Future<Either<Failure, void>> deleteParent(int parentId);

  Future<Either<Failure, Child>> addChild(Child child);

  Future<Either<Failure, void>> updateChild(Child child);

  Future<Either<Failure, void>> deleteChild(int childId);

  Future<Either<Failure, int>> getParentIdByChildId(int childId);

  Future<Either<Failure, void>> updateParentBalance(
      {required int parentId, required double amount});
}
