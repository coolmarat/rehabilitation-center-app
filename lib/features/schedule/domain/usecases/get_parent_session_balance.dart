import 'package:rehabilitation_center_app/features/schedule/domain/repositories/schedule_repository.dart';

class GetParentSessionBalance {
  final ScheduleRepository repository;

  GetParentSessionBalance(this.repository);

  Future<int> call(int parentId) async {
    return await repository.getParentSessionBalance(parentId);
  }
}
