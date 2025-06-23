import 'package:equatable/equatable.dart';
import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class UpdateParentBalance {
  final ClientRepository repository;

  UpdateParentBalance(this.repository);

  Future<void> call(UpdateParentBalanceParams params) async {
    await repository.updateParentBalance(params.parentId, params.amount);
  }
}

class UpdateParentBalanceParams extends Equatable {
  final int parentId;
  final double amount; // Сумма для списания

  const UpdateParentBalanceParams({required this.parentId, required this.amount});

  @override
  List<Object?> get props => [parentId, amount];
}
