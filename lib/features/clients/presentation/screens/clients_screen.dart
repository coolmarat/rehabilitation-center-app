import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:rehabilitation_center_app/core/widgets/confirmation_dialog.dart';
// import 'package:rehabilitation_center_app/features/clients/domain/parent.dart'; // Удаляем неиспользуемый импорт
import 'package:rehabilitation_center_app/features/clients/presentation/bloc/client_bloc.dart';
import 'package:rehabilitation_center_app/features/clients/presentation/di/client_dependencies.dart';
import 'package:rehabilitation_center_app/features/clients/presentation/widgets/child_form_dialog.dart';
import 'package:rehabilitation_center_app/features/clients/presentation/widgets/parent_form_dialog.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  // Состояние для отображения поля поиска
  bool _isSearching = false;
  // Контроллер для текстового поля
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // УБИРАЕМ addListener отсюда
    // _searchController.addListener(() {
    //   context.read<ClientBloc>().add(SearchQueryChanged(_searchController.text));
    // });
  }

  @override
  void dispose() {
    _searchController.dispose(); // Очищаем контроллер
    super.dispose();
  }

  // Метод для переключения AppBar
  AppBar _buildAppBar(BuildContext context) {
    if (_isSearching) {
      // AppBar с полем поиска
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear(); // Очищаем текст при выходе из поиска
            });
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true, // Автофокус при открытии
          // ДОБАВЛЯЕМ onChanged здесь
          onChanged: (query) {
            // Используем context, который доступен в build методе AppBar
            context.read<ClientBloc>().add(SearchQueryChanged(query));
          },
          decoration: InputDecoration(
            hintText: 'Поиск по ФИО...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white54),
          ),
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // Кнопка очистки поля
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<ClientBloc>().add(SearchQueryChanged(''));
            },
          ),
        ],
      );
    } else {
      // Обычный AppBar
      return AppBar(
        title: const Text('Клиенты (Родители и Дети)'),
        actions: [
          // Иконка поиска
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Поиск',
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
          // Иконка добавления родителя
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Добавить родителя',
            onPressed: () {
              // Используем context, полученный от Builder ниже
              showParentFormDialog(context);
            },
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: clientProviders,
      // Используем Builder, чтобы получить context с доступом к ClientBloc
      // для кнопок в AppBar
      child: Builder(
        builder:
            (context) => Scaffold(
              // Используем метод для построения AppBar
              appBar: _buildAppBar(context),
              body: BlocListener<ClientBloc, ClientState>(
                listener: (context, state) {
                  // Показываем SnackBar, если есть сообщение
                  if (state.message != null && state.message!.isNotEmpty) {
                    // Определяем цвет фона в зависимости от статуса
                    final isError = state.status == ClientStatus.failure;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message!),
                        backgroundColor:
                            isError ? Colors.redAccent : Colors.green,
                        duration: const Duration(
                          seconds: 2,
                        ), // Длительность показа
                      ),
                    );
                    // Очищаем сообщение в BLoC после показа SnackBar,
                    // чтобы оно не показывалось снова при перестроении UI
                    context.read<ClientBloc>().add(ClearClientMessage());
                  }
                },
                child: BlocBuilder<ClientBloc, ClientState>(
                  builder: (context, state) {
                    switch (state.status) {
                      case ClientStatus.initial:
                      case ClientStatus.loading:
                        return const Center(child: CircularProgressIndicator());
                      case ClientStatus.failure:
                        return Center(
                          child: Text(
                            'Ошибка загрузки: ${state.errorMessage ?? "Неизвестная ошибка"}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      case ClientStatus.success:
                        if (state.parentsWithChildren.isEmpty) {
                          return const Center(
                            child: Text(
                              'Нет клиентов. Добавьте первого клиента.',
                            ),
                          );
                        }
                        // Сортируем родителей по fullName
                        final sortedParentEntries =
                            state.parentsWithChildren.entries.toList()..sort(
                              (a, b) => a.key.fullName.toLowerCase().compareTo(
                                b.key.fullName.toLowerCase(),
                              ),
                            );

                        final parentTiles =
                            sortedParentEntries.map((entry) {
                              final parent = entry.key;
                              final children = entry.value;
                              // Получаем сет ID для разворота из состояния
                              final shouldExpand = state
                                  .initiallyExpandedParentIds
                                  .contains(parent.id);

                              return ExpansionTile(
                                // ИЗМЕНЯЕМ Key, чтобы он зависел и от ID, и от состояния разворота
                                key: ValueKey('${parent.id}_$shouldExpand'),
                                // Устанавливаем начальное состояние разворота
                                initiallyExpanded: shouldExpand,
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        parent.fullName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(
                                        '${parent.balance.toStringAsFixed(2)} руб.',
                                        style: TextStyle(
                                          color: parent.balance < 0 ? Colors.redAccent : Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(parent.phoneNumber),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      tooltip: 'Редактировать родителя',
                                      onPressed: () {
                                        // Используем context из Builder
                                        showParentFormDialog(
                                          context,
                                          parent: parent,
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.redAccent,
                                      ),
                                      tooltip: 'Удалить родителя',
                                      onPressed: () async {
                                        // Используем context из Builder
                                        final confirmed =
                                            await showConfirmationDialog(
                                              context: context,
                                              title: 'Удалить родителя?',
                                              content:
                                                  'Вы уверены, что хотите удалить родителя "${parent.fullName}"? Это действие также удалит всех связанных с ним детей.',
                                              confirmText: 'Удалить',
                                            );
                                        if (confirmed == true) {
                                          context.read<ClientBloc>().add(
                                            DeleteParentRequested(parent.id),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                children: [
                                  // Сначала существующие дети
                                  if (children.isEmpty)
                                    const ListTile(title: Text('Детей нет'))
                                  else
                                    ...children.map(
                                      (child) => ListTile(
                                        key: ValueKey(child.id),
                                        title: Text(child.fullName),
                                        subtitle: Text(
                                          'Дата рожд.: ${child.dateOfBirth.toLocal().toString().split(' ')[0]}',
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                // Используем context из Builder
                                                // Вызываем диалог редактирования ребенка
                                                showChildFormDialog(
                                                  context,
                                                  parentId: parent.id,
                                                  child: child,
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                size: 20,
                                                color: Colors.redAccent,
                                              ),
                                              onPressed: () async {
                                                // Используем context из Builder
                                                final confirmed =
                                                    await showConfirmationDialog(
                                                      context: context,
                                                      title: 'Удалить ребенка?',
                                                      content:
                                                          'Вы уверены, что хотите удалить ребенка "${child.fullName}"?',
                                                      confirmText: 'Удалить',
                                                    );
                                                if (confirmed == true) {
                                                  context
                                                      .read<ClientBloc>()
                                                      .add(
                                                        DeleteChildRequested(
                                                          child.id,
                                                        ),
                                                      );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          // TODO: Возможно, переход к деталям ребенка
                                        },
                                      ),
                                    ),
                                  // Затем кнопка добавления нового ребенка
                                  ListTile(
                                    title: const Text('Добавить ребенка'),
                                    leading: const Icon(
                                      Icons.add_circle_outline,
                                    ),
                                    onTap: () {
                                      // Вызываем диалог добавления ребенка
                                      showChildFormDialog(
                                        context,
                                        parentId: parent.id,
                                      );
                                    },
                                  ),
                                ],
                              );
                            }).toList();

                        return ListView(children: parentTiles);
                    }
                  },
                ),
              ),
            ),
      ),
    );
  }
}
