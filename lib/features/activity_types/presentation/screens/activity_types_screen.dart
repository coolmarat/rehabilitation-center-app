import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rehabilitation_center_app/core/widgets/confirmation_dialog.dart'; // Убедитесь, что импорт правильный
import 'package:rehabilitation_center_app/features/activity_types/domain/activity_type.dart';
import 'package:rehabilitation_center_app/features/activity_types/presentation/bloc/activity_type_bloc.dart';
import 'package:rehabilitation_center_app/features/activity_types/presentation/widgets/activity_type_form_dialog.dart';

import '../../../../injection_container.dart';

class ActivityTypesScreen extends StatelessWidget {
  const ActivityTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ActivityTypeBloc>()..add(LoadActivityTypes()),
      // Оборачиваем Scaffold в Builder
      child: Builder(
        builder: (innerContext) {
          // innerContext находится ПОД BlocProvider
          return Scaffold(
            appBar: AppBar(
              title: const Text('Виды услуг'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Добавить вид услуги',
                  // Используем innerContext для вызова диалога
                  onPressed: () => _showActivityTypeDialog(innerContext, null),
                ),
              ],
            ),
            body: BlocConsumer<ActivityTypeBloc, ActivityTypeState>(
              listener: (context, state) {
                // listener может использовать context из BlocConsumer
                if (state.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message!),
                      backgroundColor:
                          state.status == ActivityTypeStatus.failure
                              ? Colors.red
                              : Colors.green,
                    ),
                  );
                }
              },
              builder: (context, state) {
                // builder может использовать context из BlocConsumer
                if (state.status == ActivityTypeStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state.status == ActivityTypeStatus.failure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Ошибка загрузки данных.'),
                        ElevatedButton(
                          onPressed:
                              () => context.read<ActivityTypeBloc>().add(
                                LoadActivityTypes(),
                              ),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  );
                } else if (state.activityTypes.isEmpty) {
                  return const Center(
                    child: Text('Виды услуг еще не добавлены.'),
                  );
                } else {
                  // Список видов услуг
                  return ListView.builder(
                    itemCount: state.activityTypes.length,
                    itemBuilder: (context, index) {
                      final activityType = state.activityTypes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: ListTile(
                          title: Text(activityType.name),
                          subtitle:
                              activityType.description.isNotEmpty
                                  ? Text(activityType.description)
                                  : null, // Показываем описание, если есть
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Отображаем цену, если она есть
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  '${activityType.defaultPrice.toStringAsFixed(2)} ₽', // Форматируем цену
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                tooltip: 'Редактировать',
                                // Используем innerContext
                                onPressed:
                                    () => _showActivityTypeDialog(
                                      innerContext,
                                      activityType,
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Удалить',
                                // Используем innerContext
                                onPressed:
                                    () => _showDeleteConfirmation(
                                      innerContext,
                                      activityType,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  // Метод для показа диалога добавления/редактирования
  // Обновляем метод, чтобы он принимал BuildContext
  Future<void> _showActivityTypeDialog(
    BuildContext dialogContext,
    ActivityType? activityType,
  ) async {
    // Используем переданный dialogContext для получения BLoC
    final bloc = dialogContext.read<ActivityTypeBloc>();
    final result = await showDialog<ActivityType>(
      context:
          dialogContext, // Используем переданный dialogContext для показа диалога
      builder: (_) => ActivityTypeFormDialog(initialActivityType: activityType),
      barrierDismissible: false,
    );

    if (result != null) {
      if (activityType == null) {
        bloc.add(AddActivityTypeRequested(result));
      } else {
        bloc.add(UpdateActivityTypeRequested(result));
      }
    }
  }

  // Метод для показа диалога подтверждения удаления
  // Обновляем метод, чтобы он принимал BuildContext
  Future<void> _showDeleteConfirmation(
    BuildContext dialogContext,
    ActivityType activityType,
  ) async {
    final confirmed = await showConfirmationDialog(
      context:
          dialogContext, // Используем переданный dialogContext для показа диалога
      title: 'Удалить вид услуги?',
      content:
          'Вы уверены, что хотите удалить "${activityType.name}"? Это действие нельзя будет отменить.',
      confirmText: 'Удалить',
    );

    if (confirmed == true) {
      // Используем dialogContext для получения BLoC
      dialogContext.read<ActivityTypeBloc>().add(
        DeleteActivityTypeRequested(activityType.id),
      );
    }
  }
}
