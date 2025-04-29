import 'package:rehabilitation_center_app/features/clients/domain/child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class GetParentsWithChildren {
  final ClientRepository repository;

  GetParentsWithChildren(this.repository);

  Future<Map<Parent, List<Child>>> call() async {
    return await repository.getAllParentsWithChildren();
  }
}
