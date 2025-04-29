import 'package:flutter/material.dart';

Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Да',
  String cancelText = 'Отмена',
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // Пользователь должен сделать выбор
    builder: (BuildContext dialogContext) {
      // Используем dialogContext внутри builder
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: Text(cancelText),
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(false); // Возвращаем false при отмене
            },
          ),
          TextButton(
            // Выделяем кнопку подтверждения
            style: TextButton.styleFrom(
              // Используем dialogContext для доступа к теме
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(confirmText),
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(true); // Возвращаем true при подтверждении
            },
          ),
        ],
      );
    },
  );
}
