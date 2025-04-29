import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Импортируем основной экран/shell навигации
import 'package:rehabilitation_center_app/features/shell/presentation/screens/main_shell.dart';

// Импортируем экраны для дочерних маршрутов
import 'package:rehabilitation_center_app/features/employees/presentation/screens/employees_screen.dart'; 
// Импортируем новый экран Клиентов
import 'package:rehabilitation_center_app/features/clients/presentation/screens/clients_screen.dart';
// Импортируем экран Расписания
import 'package:rehabilitation_center_app/features/schedule/presentation/screens/schedule_screen.dart';
import 'package:rehabilitation_center_app/features/activity_types/presentation/screens/activity_types_screen.dart';
// Импортируем экран Финансового отчета
import 'package:rehabilitation_center_app/features/reports/presentation/finance_report_screen.dart';

class AppRouter {
  // Ключ для основного навигатора (опционально, но может пригодиться)
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  // Ключ для навигатора внутри ShellRoute
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    initialLocation: '/employees', // Начнем с экрана сотрудников для теста
    navigatorKey: _rootNavigatorKey, // Привязываем ключ к корневому навигатору
    routes: <RouteBase>[
      // ShellRoute для основной навигации с боковой панелью
      ShellRoute(
        navigatorKey: _shellNavigatorKey, // Привязываем ключ к Shell навигатору
        builder: (BuildContext context, GoRouterState state, Widget child) {
          // MainShell будет отображать 'child' в своем теле
          return MainShell(child: child);
        },
        routes: <RouteBase>[
          // Маршрут для экрана Сотрудников
          GoRoute(
            path: '/employees',
            builder: (BuildContext context, GoRouterState state) {
              return const EmployeesScreen();
            },
          ),
          // Раскомментируем и добавим маршруты-заглушки для других разделов
          GoRoute(
            path: '/clients',
            builder: (BuildContext context, GoRouterState state) {
              // Заменяем заглушку на реальный экран
              return const ClientsScreen(); 
            },
          ),
          GoRoute(
            path: '/schedule',
            builder: (BuildContext context, GoRouterState state) {
              // TODO: Заменить на реальный ScheduleScreen --> Заменено!
              return const ScheduleScreen(); // Используем реальный экран
            },
          ),
          GoRoute(
            path: '/reports',
            builder: (BuildContext context, GoRouterState state) {
              // TODO: Заменить на реальный ReportsScreen -> Заменено!
              return const FinanceReportScreen(); // Используем реальный экран отчета
            },
          ),
          // Добавим маршрут для настроек как пример
           GoRoute(
            path: '/settings', // Добавляем путь
             builder: (BuildContext context, GoRouterState state) {
               // TODO: Заменить на реальный SettingsScreen
              return const Center(child: Text('Настройки (Заглушка)')); // Временная заглушка
            },
           ),
          // Add the new route for Activity Types
          GoRoute(
            path: '/activity-types',
            builder: (BuildContext context, GoRouterState state) {
              return const ActivityTypesScreen();
            },
          ),
        ],
      ),
      // TODO: Добавить маршруты для отдельных экранов без Shell (например, логин или настройки)
      // GoRoute(
      //   path: '/login',
      //   builder: (BuildContext context, GoRouterState state) {
      //     return const LoginScreen();
      //   },
      // ),
    ],
    // TODO: Добавить обработку ошибок навигации
    // errorBuilder: (context, state) => ErrorScreen(state.error),
  );
}
