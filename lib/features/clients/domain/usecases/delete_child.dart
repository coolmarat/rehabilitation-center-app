import 'package:dartz/dartz.dart';
import 'package:rehabilitation_center_app/core/errors/failures.dart';
import 'package:rehabilitation_center_app/core/usecases/usecase.dart';
import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class DeleteChild implements UseCase<void, int> {
  final ClientRepository repository;

  DeleteChild(this.repository);

  @override
  Future<Either<Failure, void>> call(int params) async {
    return await repository.deleteChild(params);
  }
}

