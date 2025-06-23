part of '../../../../core/database/app_database.dart';

@DriftAccessor(tables: [Sessions, Children, Employees, ActivityTypes])
class ScheduleDao extends DatabaseAccessor<AppDatabase> with _$ScheduleDaoMixin {
  final AppDatabase db;

  ScheduleDao(this.db) : super(db);

  // Методы для работы с расписанием будут добавлены здесь.
}
