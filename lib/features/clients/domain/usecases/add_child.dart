import 'package:rehabilitation_center_app/features/clients/domain/child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class AddChild {
  final ClientRepository repository;

  AddChild(this.repository);

  Future<Child> call(Child child) async {
    return await repository.addChild(child);
  }
}
