import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:rehabilitation_center_app/core/errors/failures.dart';
import 'package:rehabilitation_center_app/core/usecases/usecase.dart';
import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class UpdateParentBalance implements UseCase<void, UpdateParentBalanceParams> {
  final ClientRepository repository;

  UpdateParentBalance(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateParentBalanceParams params) async {
    return await repository.updateParentBalance(
        parentId: params.parentId, amount: params.amount);
  }
}

class UpdateParentBalanceParams extends Equatable {
  final int parentId;
  final double amount; // Сумма для списания

  const UpdateParentBalanceParams({required this.parentId, required this.amount});

  @override
  List<Object?> get props => [parentId, amount];
}
