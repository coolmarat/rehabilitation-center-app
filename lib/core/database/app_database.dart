import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Импортируем модели таблиц (мы их создадим в следующих файлах)
part 'tables/employees.dart';
part 'tables/parents.dart';
part 'tables/children.dart';
part 'tables/activity_types.dart';
part 'tables/sessions.dart';

// Эта строка указывает drift сгенерировать файл
part 'app_database.g.dart'; 

@DriftDatabase(tables: [
  Employees,
  Parents,
  Children,
  ActivityTypes,
  Sessions,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  // Увеличиваем версию схемы до 4, так как добавили durationInMinutes
  int get schemaVersion => 4; 

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      // При создании базы данных создаем все таблицы
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // При обновлении с версии 1 до 2
      if (from == 1) {
        // Добавляем столбец 'address' в таблицу 'parents'
        await m.addColumn(parents, parents.address);
      }
      // При обновлении с версии 2 до 3
      if (from == 2) {
        // Добавляем столбец 'diagnosis' в таблицу 'children'
        await m.addColumn(children, children.diagnosis);
      }
      // При обновлении с версии 3 до 4
      if (from == 3) {
        // Добавляем столбец durationInMinutes в таблицу activityTypes
        await m.addColumn(activityTypes, activityTypes.durationInMinutes);
      }
      // Сюда можно будет добавить миграции для будущих версий
      // if (from == 4) { ... }
    },
  );

  // Здесь можно добавить методы для сложных запросов (DAO) позже
}

LazyDatabase _openConnection() {
  // Вычисляет путь к файлу базы данных в папке документов приложения.
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    // Назовем файл базы данных 'db.sqlite'
    final file = File(p.join(dbFolder.path, 'db.sqlite')); 
    return NativeDatabase.createInBackground(file);
  });
}
