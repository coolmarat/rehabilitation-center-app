import 'package:rehabilitation_center_app/features/activity_types/domain/activity_type.dart';
import 'package:rehabilitation_center_app/features/activity_types/domain/repositories/activity_type_repository.dart';

class GetActivityTypes {
  final ActivityTypeRepository repository;

  GetActivityTypes(this.repository);

  Future<List<ActivityType>> call() async {
    return await repository.getActivityTypes();
  }
}
