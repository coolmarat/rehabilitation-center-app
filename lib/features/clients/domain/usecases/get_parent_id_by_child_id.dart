import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';

class GetParentIdByChildId {
  final ClientRepository repository;

  GetParentIdByChildId(this.repository);

  Future<int> call(int childId) async {
    return await repository.getParentIdByChildId(childId);
  }
}
