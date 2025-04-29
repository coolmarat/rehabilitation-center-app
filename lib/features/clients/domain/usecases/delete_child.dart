import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class DeleteChild {
  final ClientRepository repository;

  DeleteChild(this.repository);

  Future<void> call(int childId) async {
    await repository.deleteChild(childId);
  }
}
