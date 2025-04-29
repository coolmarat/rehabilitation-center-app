import 'package:rehabilitation_center_app/features/activity_types/domain/repositories/activity_type_repository.dart';

class DeleteActivityType {
  final ActivityTypeRepository repository;

  DeleteActivityType(this.repository);

  Future<void> call(int id) async {
    await repository.deleteActivityType(id);
  }
}
