import 'package:rehabilitation_center_app/features/activity_types/domain/activity_type.dart';

abstract class ActivityTypeRepository {
  Future<List<ActivityType>> getActivityTypes();
  Future<void> addActivityType(ActivityType activityType);
  Future<void> updateActivityType(ActivityType activityType);
  Future<void> deleteActivityType(int id);
}
