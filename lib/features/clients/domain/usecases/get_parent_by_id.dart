import 'package:dartz/dartz.dart';
import 'package:rehabilitation_center_app/core/errors/failures.dart';
import 'package:rehabilitation_center_app/core/usecases/usecase.dart';
import 'package:rehabilitation_center_app/features/clients/domain/parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class GetParentById implements UseCase<Parent, GetParentByIdParams> {
  final ClientRepository repository;

  GetParentById(this.repository);

  @override
  Future<Either<Failure, Parent>> call(GetParentByIdParams params) async {
    return await repository.getParentById(params.parentId);
  }
}

class GetParentByIdParams {
  final int parentId;

  GetParentByIdParams({required this.parentId});
}
