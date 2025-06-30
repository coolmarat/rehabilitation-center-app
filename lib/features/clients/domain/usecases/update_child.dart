import 'package:dartz/dartz.dart';
import 'package:rehabilitation_center_app/core/errors/failures.dart';
import 'package:rehabilitation_center_app/core/usecases/usecase.dart';
import 'package:rehabilitation_center_app/features/clients/domain/child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class UpdateChild implements UseCase<void, Child> {
  final ClientRepository repository;

  UpdateChild(this.repository);

  @override
  Future<Either<Failure, void>> call(Child params) async {
    return await repository.updateChild(params);
  }
}

