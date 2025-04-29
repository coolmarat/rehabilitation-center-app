import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class DeleteParent {
  final ClientRepository repository;

  DeleteParent(this.repository);

  Future<void> call(int parentId) async {
    await repository.deleteParent(parentId);
  }
}
