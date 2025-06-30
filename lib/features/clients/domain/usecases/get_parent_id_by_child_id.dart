import 'package:dartz/dartz.dart';
import 'package:rehabilitation_center_app/core/errors/failures.dart';
import 'package:rehabilitation_center_app/core/usecases/usecase.dart';
import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class GetParentIdByChildId implements UseCase<int, int> {
  final ClientRepository repository;

  GetParentIdByChildId(this.repository);

  @override
  Future<Either<Failure, int>> call(int childId) async {
    return await repository.getParentIdByChildId(childId);
  }
}
