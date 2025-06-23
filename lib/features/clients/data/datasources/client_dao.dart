part of '../../../../core/database/app_database.dart';

@DriftAccessor(tables: [Children, Parents])
class ClientDao extends DatabaseAccessor<AppDatabase> with _$ClientDaoMixin {
  final AppDatabase db;

  ClientDao(this.db) : super(db);

  // Методы для работы с клиентами будут добавлены здесь.
}
