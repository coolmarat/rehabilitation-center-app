import 'package:rehabilitation_center_app/features/schedule/domain/repositories/schedule_repository.dart';

class GetClientSessionBalance {
  final ScheduleRepository repository;

  GetClientSessionBalance(this.repository);

  Future<int> call(int clientId) async {
    return await repository.getClientSessionBalance(clientId);
  }
}
