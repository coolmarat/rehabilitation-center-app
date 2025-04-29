// Use case для получения сессий на день

import '../entities/session_details.dart';
import '../repositories/schedule_repository.dart';

// Use case для получения сессий на день
class GetSessionsForDay {
  final ScheduleRepository repository;

  GetSessionsForDay(this.repository);

  Future<List<SessionDetails>> call(DateTime date) async {
    return await repository.getSessionsForDay(date);
  }
}
