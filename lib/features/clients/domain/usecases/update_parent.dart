import 'package:rehabilitation_center_app/features/clients/domain/parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class UpdateParent {
  final ClientRepository repository;

  UpdateParent(this.repository);

  Future<void> call(Parent parent) async {
    // Валидация и т.д.
    await repository.updateParent(parent);
  }
}
