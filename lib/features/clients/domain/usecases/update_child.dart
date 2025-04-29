import 'package:rehabilitation_center_app/features/clients/domain/child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class UpdateChild {
  final ClientRepository repository;

  UpdateChild(this.repository);

  Future<void> call(Child child) async {
    await repository.updateChild(child);
  }
}
