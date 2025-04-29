import 'package:rehabilitation_center_app/features/schedule/domain/repositories/schedule_repository.dart';

// Use case для удаления сессии
class DeleteSession {
  final ScheduleRepository repository;

  DeleteSession(this.repository);

  Future<void> call(int sessionId) async {
    await repository.deleteSession(sessionId);
  }
}
