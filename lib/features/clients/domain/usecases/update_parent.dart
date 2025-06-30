import 'package:dartz/dartz.dart';
import 'package:rehabilitation_center_app/core/errors/failures.dart';
import 'package:rehabilitation_center_app/core/usecases/usecase.dart';
import 'package:rehabilitation_center_app/features/clients/domain/parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class UpdateParent implements UseCase<void, Parent> {
  final ClientRepository repository;

  UpdateParent(this.repository);

  @override
  Future<Either<Failure, void>> call(Parent params) async {
    return await repository.updateParent(params);
  }
}

