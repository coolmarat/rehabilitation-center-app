import 'package:rehabilitation_center_app/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/session_model.dart';

// Use case для обновления существующей сессии
class UpdateSession {
  final ScheduleRepository repository;

  UpdateSession(this.repository);

  Future<void> call(Session session) async {
    // Валидация сессии (например, проверка id) может быть добавлена здесь
    await repository.updateSession(session);
  }
}
