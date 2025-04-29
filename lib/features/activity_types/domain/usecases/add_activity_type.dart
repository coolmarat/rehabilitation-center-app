import 'package:rehabilitation_center_app/features/activity_types/domain/activity_type.dart';
import 'package:rehabilitation_center_app/features/activity_types/domain/repositories/activity_type_repository.dart';

class AddActivityType {
  final ActivityTypeRepository repository;

  AddActivityType(this.repository);

  Future<void> call(ActivityType activityType) async {
    // Можно добавить валидацию перед добавлением
    await repository.addActivityType(activityType);
  }
}
