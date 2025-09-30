import 'package:get_it/get_it.dart';
import 'package:rehabilitation_center_app/core/database/app_database.dart';
import 'package:rehabilitation_center_app/core/services/database_service.dart';
import 'package:rehabilitation_center_app/features/employees/data/datasources/employee_local_data_source.dart';
import 'package:rehabilitation_center_app/features/employees/data/repositories/employee_repository_impl.dart';
import 'package:rehabilitation_center_app/features/employees/domain/repositories/employee_repository.dart';
import 'package:rehabilitation_center_app/features/employees/domain/usecases/add_employee.dart';
import 'package:rehabilitation_center_app/features/employees/domain/usecases/delete_employee.dart';
import 'package:rehabilitation_center_app/features/employees/domain/usecases/get_employees.dart';
import 'package:rehabilitation_center_app/features/employees/domain/usecases/update_employee.dart';
import 'package:rehabilitation_center_app/features/employees/presentation/bloc/employee_bloc.dart';
import 'package:rehabilitation_center_app/features/activity_types/data/repositories/activity_type_repository_impl.dart';
import 'package:rehabilitation_center_app/features/activity_types/domain/repositories/activity_type_repository.dart';
import 'package:rehabilitation_center_app/features/activity_types/domain/usecases/add_activity_type.dart';
import 'package:rehabilitation_center_app/features/activity_types/domain/usecases/delete_activity_type.dart';
import 'package:rehabilitation_center_app/features/activity_types/domain/usecases/get_activity_types.dart';
import 'package:rehabilitation_center_app/features/activity_types/domain/usecases/update_activity_type.dart';
import 'package:rehabilitation_center_app/features/activity_types/presentation/bloc/activity_type_bloc.dart';

// --- Импорты для фичи Клиенты ---
import 'package:rehabilitation_center_app/features/clients/data/datasources/client_local_data_source.dart';
import 'package:rehabilitation_center_app/features/clients/data/repositories/client_repository_impl.dart';
import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/get_parent_id_by_child_id.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/update_parent_balance.dart';
import 'package:rehabilitation_center_app/features/clients/presentation/bloc/client_bloc.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/get_parents_with_children.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/add_parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/update_parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/delete_parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/add_child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/update_child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/delete_child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/get_parent_balance.dart';


// --- Импорты для фичи Расписание ---
import 'package:rehabilitation_center_app/features/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/usecases/add_session.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/usecases/get_schedule_form_data.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/usecases/get_sessions_for_day.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/usecases/update_session.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/usecases/delete_session.dart';
import 'package:rehabilitation_center_app/features/schedule/presentation/bloc/schedule_bloc.dart' hide GetClientSessionBalance;
import 'package:rehabilitation_center_app/features/schedule/domain/usecases/check_recurring_session_conflicts.dart'; // Import new use case
import 'package:rehabilitation_center_app/features/schedule/domain/usecases/add_multiple_sessions.dart'; // Import new use case
import 'package:rehabilitation_center_app/features/schedule/domain/usecases/get_client_session_balance.dart';
import 'package:rehabilitation_center_app/features/schedule/domain/usecases/get_parent_session_balance.dart';
// ----------------------------------

// Сервис локатор
final sl = GetIt.instance;

Future<void> init() async {
  // --- Features - Employees ---
  // Bloc
  // Регистрируем как Factory, так как BLoC обычно имеет состояние и должен создаваться заново
  sl.registerFactory(
    () => EmployeeBloc(
      getEmployees: sl(),
      addEmployee: sl(),
      updateEmployee: sl(),
      deleteEmployee: sl(),
    ),
  );

  // Use cases
  // Регистрируем как LazySingleton, так как они не имеют состояния и могут быть переиспользованы
  sl.registerLazySingleton(() => GetEmployees(sl()));
  sl.registerLazySingleton(() => AddEmployee(sl()));
  sl.registerLazySingleton(() => UpdateEmployee(sl()));
  sl.registerLazySingleton(() => DeleteEmployee(sl()));

  // Repository
  sl.registerLazySingleton<EmployeeRepository>(
    () => EmployeeRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<EmployeeLocalDataSource>(
    () => EmployeeLocalDataSourceImpl(database: sl()),
  );

  // --- Features - Activity Types ---
  // Bloc
  sl.registerFactory(
    () => ActivityTypeBloc(
      getActivityTypes: sl(),
      addActivityType: sl(),
      updateActivityType: sl(),
      deleteActivityType: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetActivityTypes(sl()));
  sl.registerLazySingleton(() => AddActivityType(sl()));
  sl.registerLazySingleton(() => UpdateActivityType(sl()));
  sl.registerLazySingleton(() => DeleteActivityType(sl()));

  // Repository
  sl.registerLazySingleton<ActivityTypeRepository>(
    () => ActivityTypeRepositoryImpl(sl()),
  );

  // --- Features - Clients ---
  // Bloc
  sl.registerFactory(
    () => ClientBloc(
      getParentsWithChildren: sl(),
      addParent: sl(),
      updateParent: sl(),
      deleteParent: sl(),
      addChild: sl(),
      updateChild: sl(),
      deleteChild: sl(),
      updateParentBalance: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetParentsWithChildren(sl()));
  sl.registerLazySingleton(() => AddParent(sl()));
  sl.registerLazySingleton(() => UpdateParent(sl()));
  sl.registerLazySingleton(() => DeleteParent(sl()));
  sl.registerLazySingleton(() => AddChild(sl()));
  sl.registerLazySingleton(() => UpdateChild(sl()));
  sl.registerLazySingleton(() => DeleteChild(sl()));
  sl.registerLazySingleton(() => GetParentIdByChildId(sl()));
  sl.registerLazySingleton(() => UpdateParentBalance(sl()));
  sl.registerLazySingleton(() => GetParentBalance(sl()));

  // Repository
  sl.registerLazySingleton<ClientRepository>(
    () => ClientRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ClientLocalDataSource>(
    () => ClientLocalDataSourceImpl(clientDao: sl()),
  );

  // DAO
  sl.registerLazySingleton(() => ClientDao(sl()));

  // --- Features - Schedule ---
  // Bloc
  sl.registerFactory(
    () => ScheduleBloc(
      getSessionsForDay: sl(),
      getScheduleFormData: sl(),
      addSession: sl(),
      updateSession: sl(),
      deleteSession: sl(),
      checkRecurringSessionConflicts: sl(), // Provide the dependency
      addMultipleSessions: sl(), // Provide the dependency
      getClientSessionBalance: sl(),
      getParentSessionBalance: sl(), // Добавляем новый use case
      getParentIdByChildId: sl(),
      updateParentBalance: sl(),
      getParentBalance: sl(), // Добавляем GetParentBalance для корректного получения баланса
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetSessionsForDay(sl()));
  sl.registerLazySingleton(() => GetScheduleFormData(sl()));
  sl.registerLazySingleton(() => AddSession(sl()));
  sl.registerLazySingleton(() => UpdateSession(sl()));
  sl.registerLazySingleton(() => DeleteSession(sl()));
  sl.registerLazySingleton(
    () => CheckRecurringSessionConflicts(sl()),
  ); // Register new use case
  sl.registerLazySingleton(
    () => AddMultipleSessions(sl()),
  ); // Register new use case

  sl.registerLazySingleton(
      () => GetClientSessionBalance(sl<ScheduleRepository>()));

  // Регистрируем новый UseCase для получения баланса родителя
  sl.registerLazySingleton(
      () => GetParentSessionBalance(sl<ScheduleRepository>()));

  // Use cases, которые относятся к клиентам, но используются в расписании, теперь в секции Clients

  // Repository
  sl.registerLazySingleton<ScheduleRepository>(
    () => ScheduleRepositoryImpl(sl()), // Передаем базу данных позиционно
  );

  // --- Core ---
  // Database
  // Регистрируем AppDatabase как Singleton, т.к. нам нужен один экземпляр на все приложение
  // Важно: этот экземпляр должен быть тем же, что используется в Provider в main.dart
  // Мы можем либо передать сюда существующий экземпляр, либо зарегистрировать его здесь
  // и получать из sl в main.dart. Выберем второй подход.
  if (!sl.isRegistered<AppDatabase>()) {
    // Проверяем, не зарегистрирован ли уже
    sl.registerSingleton<AppDatabase>(AppDatabase());
  }

  // Database Service
  sl.registerLazySingleton<DatabaseService>(
    () => DatabaseService(sl()),
  );

}
