import 'package:dartz/dartz.dart';
import 'package:rehabilitation_center_app/core/errors/failures.dart';
import 'package:rehabilitation_center_app/core/usecases/usecase.dart';
import 'package:rehabilitation_center_app/features/clients/domain/child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class AddChild implements UseCase<Child, Child> {
  final ClientRepository repository;

  AddChild(this.repository);

  @override
  Future<Either<Failure, Child>> call(Child params) async {
    return await repository.addChild(params);
  }
}

