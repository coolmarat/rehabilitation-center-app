import 'package:rehabilitation_center_app/core/database/app_database.dart';

/// Модель для представления orphaned child с связанными данными
class OrphanedChildData {
  final ChildEntry child;
  final List<Session> sessions;

  OrphanedChildData({required this.child, required this.sessions});

  int get totalSessionsCount => sessions.length;
}

/// Сервис для проверки целостности базы данных
class DatabaseIntegrityService {
  final AppDatabase _database;

  DatabaseIntegrityService(this._database);

  /// Находит всех детей, у которых parentId ссылается на несуществующего родителя
  Future<List<OrphanedChildData>> findOrphanedChildren() async {
    final orphanedChildren = <OrphanedChildData>[];

    // Получаем всех детей
    final allChildren = await _database.select(_database.children).get();

    // Получаем все ID существующих родителей
    final allParents = await _database.select(_database.parents).get();
    final parentIds = allParents.map((p) => p.id).toSet();

    // Находим детей с несуществующими родителями
    for (final child in allChildren) {
      if (!parentIds.contains(child.parentId)) {
        // Получаем связанные сессии
        final sessions =
            await (_database.select(_database.sessions)
              ..where((s) => s.childId.equals(child.id))).get();

        orphanedChildren.add(
          OrphanedChildData(child: child, sessions: sessions),
        );
      }
    }

    return orphanedChildren;
  }

  /// Удаляет orphaned child и все связанные с ним данные
  Future<void> deleteOrphanedChild(int childId) async {
    await _database.transaction(() async {
      // Удаляем сессии, связанные с ребенком
      await (_database.delete(_database.sessions)
        ..where((s) => s.childId.equals(childId))).go();

      // Удаляем самого ребенка
      await (_database.delete(_database.children)
        ..where((c) => c.id.equals(childId))).go();
    });
  }

  /// Удаляет всех orphaned children и их связанные данные
  Future<int> deleteAllOrphanedChildren() async {
    final orphanedChildren = await findOrphanedChildren();
    int deletedCount = 0;

    for (final orphaned in orphanedChildren) {
      await deleteOrphanedChild(orphaned.child.id);
      deletedCount++;
    }

    return deletedCount;
  }

  /// Получает общую статистику целостности БД
  Future<Map<String, int>> getIntegrityStats() async {
    final orphanedChildren = await findOrphanedChildren();

    int totalOrphanedSessions = 0;
    for (final orphaned in orphanedChildren) {
      totalOrphanedSessions += orphaned.sessions.length;
    }

    return {
      'orphanedChildren': orphanedChildren.length,
      'orphanedSessions': totalOrphanedSessions,
    };
  }
}
