import 'package:dartz/dartz.dart';
import 'package:rehabilitation_center_app/core/errors/failures.dart';
import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class GetParentBalance {
  final ClientRepository repository;

  GetParentBalance(this.repository);

  Future<Either<Failure, double>> call(int parentId) async {
    // Получаем родителя по ID
    final parentEither = await repository.getParentById(parentId);
    
    // Возвращаем баланс из сущности Parent или Failure если не удалось получить родителя
    return parentEither.fold(
      (failure) => Left(failure),
      (parent) => Right(parent.balance),
    );
  }
}
