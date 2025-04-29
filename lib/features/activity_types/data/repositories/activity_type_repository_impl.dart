import 'package:rehabilitation_center_app/core/database/app_database.dart';
import 'package:rehabilitation_center_app/features/activity_types/domain/activity_type.dart';
import 'package:rehabilitation_center_app/features/activity_types/domain/repositories/activity_type_repository.dart';
import 'package:drift/drift.dart';

class ActivityTypeRepositoryImpl implements ActivityTypeRepository {
  final AppDatabase _database;

  ActivityTypeRepositoryImpl(this._database);

  @override
  Future<List<ActivityType>> getActivityTypes() async {
    final entries = await _database.select(_database.activityTypes).get();
    return entries.map((entry) => _mapEntryToActivityType(entry)).toList();
  }

  @override
  Future<void> addActivityType(ActivityType activityType) async {
    final companion = ActivityTypesCompanion.insert(
      name: activityType.name,
      description: activityType.description, 
      defaultPrice: activityType.defaultPrice,
      durationInMinutes: Value(activityType.durationInMinutes),
    );
    await _database.into(_database.activityTypes).insert(companion);
  }

  @override
  Future<void> updateActivityType(ActivityType activityType) async {
    final companion = ActivityTypesCompanion(
      id: Value(activityType.id),
      name: Value(activityType.name),
      description: Value(activityType.description),
      defaultPrice: Value(activityType.defaultPrice),
      durationInMinutes: Value(activityType.durationInMinutes),
    );
    await (_database.update(_database.activityTypes)
          ..where((tbl) => tbl.id.equals(activityType.id)))
        .write(companion);
  }

  @override
  Future<void> deleteActivityType(int id) async {
    await (_database.delete(_database.activityTypes)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  // Вспомогательный метод для маппинга
  ActivityType _mapEntryToActivityType(ActivityTypeEntry entry) {
    return ActivityType(
      id: entry.id,
      name: entry.name,
      description: entry.description,
      defaultPrice: entry.defaultPrice,
      durationInMinutes: entry.durationInMinutes,
    );
  }
}
