import 'package:rehabilitation_center_app/features/schedule/domain/repositories/schedule_repository.dart';

class CheckRecurringSessionConflicts {
  final ScheduleRepository repository;

  CheckRecurringSessionConflicts(this.repository);

  Future<List<DateTime>> call(
    List<DateTime> sessionDates,
    int employeeId,
    int childId,
    int durationMinutes,
  ) async {
    // TODO: Implement the actual conflict checking logic in the repository
    // For now, return an empty list (no conflicts)
    return [];
  }
}
