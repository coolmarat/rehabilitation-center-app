import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rehabilitation_center_app/features/activity_types/domain/activity_type.dart';

class ActivityTypeFormDialog extends StatefulWidget {
  final ActivityType? initialActivityType; // null для добавления, существующий для редактирования

  const ActivityTypeFormDialog({Key? key, this.initialActivityType}) : super(key: key);

  @override
  State<ActivityTypeFormDialog> createState() => _ActivityTypeFormDialogState();
}

class _ActivityTypeFormDialogState extends State<ActivityTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialActivityType?.name ?? '');
    _descriptionController = TextEditingController(text: widget.initialActivityType?.description ?? '');
    _priceController = TextEditingController(
      text: widget.initialActivityType?.defaultPrice.toStringAsFixed(2) ?? '',
    );
    _durationController = TextEditingController(
      text: widget.initialActivityType?.durationInMinutes.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialActivityType != null;
    final title = isEditing ? 'Редактировать вид услуги' : 'Добавить вид услуги';

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        // Оборачиваем в SingleChildScrollView на случай маленьких экранов
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Чтобы диалог не растягивался
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Название *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Описание'),
                maxLines: 3,
                // Описание не обязательное
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Цена по умолчанию *', suffixText: 'руб.', hintText: '0.00'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), // Разрешает цифры и одну точку, до 2 знаков после точки
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите цену';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Некорректное число';
                  }
                  if (double.parse(value) < 0) {
                    return 'Цена не может быть отрицательной';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Длительность (мин) *', hintText: '60'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Only allow digits
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите длительность';
                  }
                  final duration = int.tryParse(value);
                  if (duration == null) {
                    return 'Некорректное число';
                  }
                  if (duration <= 0) {
                    return 'Длительность должна быть положительной';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Отмена'),
          onPressed: () => Navigator.of(context).pop(), // Возвращаем null
        ),
        TextButton(
          child: Text(isEditing ? 'Сохранить' : 'Добавить'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final name = _nameController.text.trim();
              final description = _descriptionController.text.trim();
              final price = double.parse(_priceController.text); // Валидация уже прошла
              final duration = int.parse(_durationController.text);

              // Создаем объект ActivityType
              final result = isEditing
                  ? widget.initialActivityType!.copyWith(
                      name: name,
                      description: description,
                      defaultPrice: price,
                      durationInMinutes: duration,
                    )
                  : ActivityType.noId(
                      name: name,
                      description: description,
                      defaultPrice: price,
                      durationInMinutes: duration,
                    );

              Navigator.of(context).pop(result); // Возвращаем созданный/обновленный объект
            }
          },
        ),
      ],
    );
  }
}
