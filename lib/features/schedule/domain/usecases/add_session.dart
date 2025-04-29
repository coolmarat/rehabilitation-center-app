// Use case для добавления сессии

import 'package:rehabilitation_center_app/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/session_model.dart'; // Import Session model

// Use case для добавления сессии
class AddSession {
  final ScheduleRepository repository;

  AddSession(this.repository);

  // Принимаем Session для удобства передачи данных в репозиторий
  Future<void> call(Session session) async {
    // Pass the Session domain model directly
    await repository.addSession(session);
  }
}
