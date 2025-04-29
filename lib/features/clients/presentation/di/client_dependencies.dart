import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rehabilitation_center_app/core/database/app_database.dart';
import 'package:rehabilitation_center_app/features/clients/data/datasources/client_local_data_source.dart';
import 'package:rehabilitation_center_app/features/clients/data/repositories/client_repository_impl.dart';
import 'package:rehabilitation_center_app/features/clients/domain/repositories/client_repository.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/add_child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/add_parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/delete_child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/delete_parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/get_parents_with_children.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/update_child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/update_parent.dart';
import 'package:rehabilitation_center_app/features/clients/presentation/bloc/client_bloc.dart';

// Список провайдеров для фичи Клиенты
List<SingleChildWidget> clientProviders = [
  // 1. DataSource
  Provider<ClientLocalDataSource>(
    create: (context) => ClientLocalDataSourceImpl(
      database: context.read<AppDatabase>(), // Зависимость от AppDatabase
    ),
  ),

  // 2. Repository
  Provider<ClientRepository>(
    create: (context) => ClientRepositoryImpl(
      localDataSource: context.read<ClientLocalDataSource>(), // Зависимость от DataSource
    ),
  ),

  // 3. Use Cases
  Provider<GetParentsWithChildren>(
    create: (context) => GetParentsWithChildren(context.read<ClientRepository>()),
  ),
  Provider<AddParent>(
    create: (context) => AddParent(context.read<ClientRepository>()),
  ),
  Provider<UpdateParent>(
    create: (context) => UpdateParent(context.read<ClientRepository>()),
  ),
  Provider<DeleteParent>(
    create: (context) => DeleteParent(context.read<ClientRepository>()),
  ),
  Provider<AddChild>(
    create: (context) => AddChild(context.read<ClientRepository>()),
  ),
  Provider<UpdateChild>(
    create: (context) => UpdateChild(context.read<ClientRepository>()),
  ),
  Provider<DeleteChild>(
    create: (context) => DeleteChild(context.read<ClientRepository>()),
  ),

  // 4. BLoC
  BlocProvider<ClientBloc>(
    create: (context) => ClientBloc(
      getParentsWithChildren: context.read<GetParentsWithChildren>(),
      addParent: context.read<AddParent>(),
      updateParent: context.read<UpdateParent>(),
      deleteParent: context.read<DeleteParent>(),
      addChild: context.read<AddChild>(),
      updateChild: context.read<UpdateChild>(),
      deleteChild: context.read<DeleteChild>(),
    )..add(LoadClients()), // Сразу загружаем данные при создании BLoC
  ),
];
