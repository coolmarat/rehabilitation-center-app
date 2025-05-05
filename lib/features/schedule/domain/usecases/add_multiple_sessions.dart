import 'package:rehabilitation_center_app/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/session_model.dart';

class AddMultipleSessions {
  final ScheduleRepository repository;

  AddMultipleSessions(this.repository);

  Future<void> call(List<Session> sessions) async {
    // TODO: Implement the actual logic to add multiple sessions in the repository
    await repository.addMultipleSessions(sessions);
  }
}
