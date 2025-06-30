import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; 
import 'package:provider/provider.dart'; 
import 'package:rehabilitation_center_app/app/app_router.dart'; 
import 'package:rehabilitation_center_app/app/app_theme.dart'; 
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:rehabilitation_center_app/core/database/app_database.dart'; 
import 'package:rehabilitation_center_app/injection_container.dart' as di; 
import 'package:rehabilitation_center_app/features/employees/presentation/bloc/employee_bloc.dart'; 
import 'package:rehabilitation_center_app/features/schedule/presentation/bloc/schedule_bloc.dart';
import 'package:rehabilitation_center_app/features/clients/presentation/bloc/client_bloc.dart'; // Import ClientBloc
import 'package:flutter_localizations/flutter_localizations.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await initializeDateFormatting('ru_RU', null);

  await di.init();

  runApp(const MyApp()); 
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EmployeeBloc>(
          create: (context) => di.sl<EmployeeBloc>(), 
        ),
        BlocProvider<ScheduleBloc>(
          create: (context) => di.sl<ScheduleBloc>()
            ..add(LoadSessionsForDay(DateTime.now())), // Загружаем сессии для сегодняшнего дня при старте
        ),
        BlocProvider<ClientBloc>(
          create: (context) => di.sl<ClientBloc>(), // ClientBloc уже вызывает LoadClients() в своём конструкторе
        ),
        // TODO: Добавить провайдеры для других BLoC'ов
      ],
      child: Provider<AppDatabase>(
        create: (_) => di.sl<AppDatabase>(), 
        dispose: (_, db) => db.close(), 
        child: MaterialApp.router(
          title: 'Центр Реабилитации',
          theme: AppTheme.lightTheme, 
          debugShowCheckedModeBanner: false,
          routerConfig: AppRouter.router, 
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ru'), 
            Locale('en'), 
          ],
          locale: const Locale('ru'),
        ),
      ),
    );
  }
}
