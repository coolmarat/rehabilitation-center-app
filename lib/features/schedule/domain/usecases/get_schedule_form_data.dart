// Use case для получения данных для формы (сотрудники, услуги, дети)

import '../entities/schedule_form_data.dart';
import '../repositories/schedule_repository.dart';

// Use case для получения данных для формы расписания
class GetScheduleFormData {
  final ScheduleRepository repository;

  GetScheduleFormData(this.repository);

  Future<ScheduleFormData> call() async {
    return await repository.getScheduleFormData();
  }
}
