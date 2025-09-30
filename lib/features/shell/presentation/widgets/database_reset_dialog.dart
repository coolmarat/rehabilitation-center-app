import 'package:flutter/material.dart';

class DatabaseResetDialog extends StatelessWidget {
  final String databasePath;
  
  const DatabaseResetDialog({
    super.key,
    required this.databasePath,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(
            Icons.warning,
            color: Colors.red,
            size: 28,
          ),
          SizedBox(width: 8),
          Text('Подтверждение удаления'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Вы действительно хотите удалить всю базу данных?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Путь: $databasePath',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Это действие приведет к:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Удалению всех сотрудников\n'
            '• Удалению всех клиентов и их детей\n'
            '• Удалению всех видов услуг\n'
            '• Удалению всего расписания\n'
            '• Удалению всех платежей и истории',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Данное действие НЕОБРАТИМО!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Удалить базу данных'),
        ),
      ],
    );
  }
}

/// Показывает диалог подтверждения удаления базы данных
Future<bool> showDatabaseResetDialog(
  BuildContext context,
  String databasePath,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // Пользователь должен явно выбрать действие
    builder: (BuildContext context) {
      return DatabaseResetDialog(databasePath: databasePath);
    },
  );
  
  return result ?? false; // Возвращаем false, если диалог был закрыт без выбора
}
