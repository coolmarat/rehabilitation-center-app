import 'package:rehabilitation_center_app/features/clients/domain/parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class AddParent {
  final ClientRepository repository;

  AddParent(this.repository);

  Future<Parent> call(Parent parent) async {
    // Можно добавить валидацию или другую бизнес-логику здесь
    return await repository.addParent(parent);
  }
}
