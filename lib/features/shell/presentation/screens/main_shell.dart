import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Убедимся, что импорт правильный

// TODO: Импортировать экраны для каждой секции, когда они будут созданы
// import 'package:rehabilitation_center_app/features/employees/presentation/screens/employees_screen.dart';
// import 'package:rehabilitation_center_app/features/clients/presentation/screens/clients_screen.dart';
// import 'package:rehabilitation_center_app/features/schedule/presentation/screens/schedule_screen.dart';
// import 'package:rehabilitation_center_app/features/reports/presentation/screens/reports_screen.dart';
// import 'package:rehabilitation_center_app/features/settings/presentation/screens/settings_screen.dart';

class MainShell extends StatefulWidget {
  // Принимаем дочерний виджет от ShellRoute
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Убираем _selectedIndex и _widgetOptions, т.к. навигация и отображение
  // теперь управляются через go_router и widget.child
  // int _selectedIndex = 0;
  // static const List<Widget> _widgetOptions = <Widget>[...];

  // Функция для навигации
  void _goBranch(int index) {
    // Определяем путь в зависимости от индекса
    String location;
    switch (index) {
      case 0:
        location = '/schedule';
        break;
      case 1:
        location = '/employees';
        break;
      case 2:
        location = '/clients';
        break;
      // Обновляем индекс для Видов Услуг
      case 3:
        location = '/activity-types';
        break;
      // Обновляем индекс для Отчетов
      case 4:
        location = '/reports';
        break;
      // Обновляем индекс для Настроек
      case 5:
        location = '/settings';
        break;
      default:
        location = '/schedule'; // По умолчанию - Расписание
    }
    // Используем GoRouter для перехода по ветке ShellRoute
    context.go(location);
  }

  // Функция для определения текущего индекса на основе маршрута
  int _calculateSelectedIndex(BuildContext context) {
    final GoRouter route = GoRouter.of(context);
    final String location =
        route.routerDelegate.currentConfiguration.last.matchedLocation;
    if (location.startsWith('/schedule')) {
      return 0;
    }
    if (location.startsWith('/employees')) {
      return 1;
    }
    if (location.startsWith('/clients')) {
      return 2;
    }
    // Обновляем проверку и индекс для Видов услуг
    if (location.startsWith('/activity-types')) {
      return 3;
    }
    // Обновляем проверку и индекс для Отчетов
    if (location.startsWith('/reports')) {
      return 4;
    }
    // Обновляем проверку и индекс для Настроек
    if (location.startsWith('/settings')) {
      return 5;
    }
    return 0; // По умолчанию
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationRail(
            // Определяем выбранный индекс на основе текущего маршрута
            selectedIndex: _calculateSelectedIndex(context),
            // Вызываем навигацию при выборе пункта
            onDestinationSelected: _goBranch,
            labelType:
                NavigationRailLabelType
                    .selected, // Показывать текст только для выбранного элемента
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: Text('Расписание'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Сотрудники'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.family_restroom_outlined),
                selectedIcon: Icon(Icons.family_restroom),
                label: Text('Клиенты'),
              ),
              // Переносим Виды услуг сюда
              NavigationRailDestination(
                icon: Icon(Icons.local_offer_outlined),
                selectedIcon: Icon(Icons.local_offer),
                label: Text('Виды услуг'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: Text('Отчеты'),
              ),
              // NavigationRailDestination(
              //   icon: Icon(Icons.settings_outlined),
              //   selectedIcon: Icon(Icons.settings),
              //   label: Text('Настройки'),
              // ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Отображаем дочерний виджет, переданный ShellRoute
          Expanded(
            // Убираем старую логику с _widgetOptions
            // child: _widgetOptions.elementAt(_selectedIndex),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
