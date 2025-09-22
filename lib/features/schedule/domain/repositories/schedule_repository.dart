// Интерфейс репозитория для расписания

import 'package:rehabilitation_center_app/features/schedule/domain/session_model.dart'; // Import Session model

import '../entities/schedule_form_data.dart';
import '../entities/session_details.dart';

// Интерфейс репозитория для расписания
abstract class ScheduleRepository {
  // Получить список сессий (с деталями) для определенного дня
  Future<List<SessionDetails>> getSessionsForDay(DateTime date);

  // Получить данные, необходимые для формы добавления/редактирования сессии
  Future<ScheduleFormData> getScheduleFormData();

  // Добавить новую сессию
  // Принимаем объект Session из доменного слоя
  Future<void> addSession(Session session);

  // Обновить существующую сессию
  Future<void> updateSession(Session session);

  // Удалить сессию по ID
  Future<int> deleteSession(
    int sessionId,
  ); // Возвращает количество удаленных строк (0 или 1)

  // Проверить пересечения для периодических сессий
  Future<List<DateTime>> checkRecurringSessionConflicts(
    List<DateTime> sessionDates,
    int employeeId,
    int childId,
    int durationMinutes,
  );

  // Добавить несколько сессий
  Future<void> addMultipleSessions(List<Session> sessions);

  // Получить баланс занятий клиента (ребенка)
  Future<int> getClientSessionBalance(int clientId);
  
  // Получить баланс занятий родителя
  Future<int> getParentSessionBalance(int parentId);
}
