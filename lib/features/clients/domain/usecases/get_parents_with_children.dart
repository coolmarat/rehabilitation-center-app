import 'package:dartz/dartz.dart';
import 'package:rehabilitation_center_app/core/errors/failures.dart';
import 'package:rehabilitation_center_app/core/usecases/usecase.dart';
import 'package:rehabilitation_center_app/features/clients/domain/child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class GetParentsWithChildren implements UseCase<Map<Parent, List<Child>>, NoParams> {
  final ClientRepository repository;

  GetParentsWithChildren(this.repository);

  @override
  Future<Either<Failure, Map<Parent, List<Child>>>> call(NoParams params) async {
    return await repository.getAllParentsWithChildren();
  }
}

