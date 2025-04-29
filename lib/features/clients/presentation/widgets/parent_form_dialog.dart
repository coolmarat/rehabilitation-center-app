import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rehabilitation_center_app/features/clients/domain/parent.dart';
import 'package:rehabilitation_center_app/features/clients/presentation/bloc/client_bloc.dart';

class ParentFormDialog extends StatefulWidget {
  final Parent? parent; // null для добавления, не null для редактирования

  const ParentFormDialog({Key? key, this.parent}) : super(key: key);

  @override
  State<ParentFormDialog> createState() => _ParentFormDialogState();
}

class _ParentFormDialogState extends State<ParentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  bool get _isEditing => widget.parent != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.parent?.fullName ?? '');
    _phoneController = TextEditingController(text: widget.parent?.phoneNumber ?? '');
    _emailController = TextEditingController(text: widget.parent?.email ?? '');
    _addressController = TextEditingController(text: widget.parent?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final parentData = Parent(
        // Если редактируем, используем существующий ID, иначе 0 (или другое значение, указывающее на нового родителя)
        id: widget.parent?.id ?? 0, 
        fullName: _nameController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        address: _addressController.text.isNotEmpty ? _addressController.text : null,
      );

      if (_isEditing) {
        context.read<ClientBloc>().add(UpdateParentRequested(parentData));
      } else {
        context.read<ClientBloc>().add(AddParentRequested(parentData));
      }
      Navigator.of(context).pop(); // Закрыть диалог после отправки
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Редактировать родителя' : 'Добавить родителя'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'ФИО *'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите ФИО';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Телефон *'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите номер телефона';
                  }
                  // TODO: Добавить более строгую валидацию номера телефона
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email (опционально)'),
                keyboardType: TextInputType.emailAddress,
                // Валидация Email необязательна
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Адрес (опционально)'),
                keyboardType: TextInputType.streetAddress,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Отмена'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text(_isEditing ? 'Сохранить' : 'Добавить'),
          onPressed: _submitForm,
        ),
      ],
    );
  }
}

// Вспомогательная функция для показа диалога
Future<void> showParentFormDialog(BuildContext context, {Parent? parent}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // Не закрывать по тапу вне диалога
    builder: (BuildContext dialogContext) {
      // Важно передать BlocProvider.value, если диалог вызывается из контекста,
      // где ClientBloc уже доступен (как в нашем ClientsScreen)
      return BlocProvider.value(
         value: BlocProvider.of<ClientBloc>(context),
         child: ParentFormDialog(parent: parent),
      );
    },
  );
}
