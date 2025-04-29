import 'package:rehabilitation_center_app/features/activity_types/domain/activity_type.dart';
import 'package:rehabilitation_center_app/features/activity_types/domain/repositories/activity_type_repository.dart';

class UpdateActivityType {
  final ActivityTypeRepository repository;

  UpdateActivityType(this.repository);

  Future<void> call(ActivityType activityType) async {
    // Можно добавить валидацию перед обновлением
    await repository.updateActivityType(activityType);
  }
}
