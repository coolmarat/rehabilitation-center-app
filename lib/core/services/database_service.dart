import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:rehabilitation_center_app/core/database/app_database.dart';
import 'package:get_it/get_it.dart';

class DatabaseService {
  final AppDatabase _database;

  DatabaseService(this._database);

  /// Удаляет текущую базу данных и создает новую пустую
  Future<void> resetDatabase() async {
    try {
      // Закрываем текущее соединение с базой данных
      await _database.close();

      // Получаем путь к файлу базы данных
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'db.sqlite'));

      // Удаляем файл базы данных, если он существует
      if (await file.exists()) {
        await file.delete();
      }

      // Удаляем также файлы WAL и SHM, если они существуют
      final walFile = File('${file.path}-wal');
      final shmFile = File('${file.path}-shm');
      
      if (await walFile.exists()) {
        await walFile.delete();
      }
      
      if (await shmFile.exists()) {
        await shmFile.delete();
      }

      // Создаем новый экземпляр базы данных
      final newDatabase = AppDatabase();
      
      // Заменяем старый экземпляр в GetIt
      final sl = GetIt.instance;
      await sl.unregister<AppDatabase>();
      sl.registerSingleton<AppDatabase>(newDatabase);

      print('База данных успешно пересоздана');
    } catch (e) {
      print('Ошибка при пересоздании базы данных: $e');
      rethrow;
    }
  }

  /// Проверяет, существует ли файл базы данных
  Future<bool> databaseExists() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'db.sqlite'));
      return await file.exists();
    } catch (e) {
      print('Ошибка при проверке существования базы данных: $e');
      return false;
    }
  }

  /// Получает размер файла базы данных в байтах
  Future<int> getDatabaseSize() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'db.sqlite'));
      
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('Ошибка при получении размера базы данных: $e');
      return 0;
    }
  }

  /// Получает полный путь к файлу базы данных
  Future<String> getDatabasePath() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      return p.join(dbFolder.path, 'db.sqlite');
    } catch (e) {
      print('Ошибка при получении пути базы данных: $e');
      return '';
    }
  }
}
