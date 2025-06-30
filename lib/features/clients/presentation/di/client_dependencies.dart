import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';
import 'package:rehabilitation_center_app/features/clients/presentation/bloc/client_bloc.dart';
import 'package:rehabilitation_center_app/injection_container.dart';

// Список провайдеров для фичи Клиенты
List<SingleChildWidget> clientProviders = [
  BlocProvider<ClientBloc>(
    create: (_) => sl<ClientBloc>()..add(LoadClients()),
  ),
];
