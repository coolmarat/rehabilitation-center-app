import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rehabilitation_center_app/core/services/database_integrity_service.dart';
import 'package:rehabilitation_center_app/injection_container.dart' as di;

class IntegrityCheckScreen extends StatefulWidget {
  const IntegrityCheckScreen({super.key});

  @override
  State<IntegrityCheckScreen> createState() => _IntegrityCheckScreenState();
}

class _IntegrityCheckScreenState extends State<IntegrityCheckScreen> {
  late final DatabaseIntegrityService _integrityService;
  List<OrphanedChildData> _orphanedChildren = [];
  OrphanedChildData? _selectedChild;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _integrityService = di.sl<DatabaseIntegrityService>();
    _loadOrphanedChildren();
  }

  Future<void> _loadOrphanedChildren() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orphaned = await _integrityService.findOrphanedChildren();
      setState(() {
        _orphanedChildren = orphaned;
        _selectedChild = orphaned.isNotEmpty ? orphaned.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка при загрузке данных: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSelectedChild() async {
    if (_selectedChild == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Подтверждение удаления'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Вы действительно хотите удалить ребенка "${_selectedChild!.child.fullName}" и все связанные данные?',
                ),
                const SizedBox(height: 16),
                Text(
                  'Будет удалено:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                Text('• Запись о ребенке'),
                Text('• Сессий: ${_selectedChild!.sessions.length}'),
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
                child: const Text('Удалить'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await _integrityService.deleteOrphanedChild(_selectedChild!.child.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ребенок "${_selectedChild!.child.fullName}" и связанные данные удалены',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await _loadOrphanedChildren();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при удалении: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAllOrphanedChildren() async {
    if (_orphanedChildren.isEmpty) return;

    int totalSessions = 0;
    for (final orphaned in _orphanedChildren) {
      totalSessions += orphaned.sessions.length;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Подтверждение массового удаления'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Вы действительно хотите удалить ВСЕХ детей без родителей и все связанные данные?',
                ),
                const SizedBox(height: 16),
                Text(
                  'Будет удалено:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                Text('• Детей: ${_orphanedChildren.length}'),
                Text('• Сессий: $totalSessions'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Это действие необратимо!',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
                child: const Text('Удалить всё'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      final deletedCount = await _integrityService.deleteAllOrphanedChildren();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Удалено записей: $deletedCount'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadOrphanedChildren();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при удалении: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Проверка целостности базы данных'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrphanedChildren,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Анализ базы данных...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadOrphanedChildren,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_orphanedChildren.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green.shade400),
            const SizedBox(height: 16),
            const Text(
              'База данных в порядке!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Нет детей без родителей',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Заголовок с предупреждением
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.orange.shade50,
          child: Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: Colors.orange.shade700,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Найдено ${_orphanedChildren.length} детей без родителей',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Эти записи ссылаются на несуществующих родителей и являются ошибочными данными.',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _deleteAllOrphanedChildren,
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Удалить всё'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Основной контент с двумя панелями
        Expanded(
          child: Row(
            children: [
              // Левая панель - список детей
              SizedBox(width: 350, child: _buildChildrenList()),
              const VerticalDivider(width: 1),
              // Правая панель - детали выбранного ребенка
              Expanded(
                child:
                    _selectedChild != null
                        ? _buildChildDetails(_selectedChild!)
                        : const Center(
                          child: Text('Выберите ребенка из списка слева'),
                        ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChildrenList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Дети без родителей',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: _orphanedChildren.length,
            itemBuilder: (context, index) {
              final orphaned = _orphanedChildren[index];
              final isSelected = _selectedChild?.child.id == orphaned.child.id;

              return ListTile(
                selected: isSelected,
                selectedTileColor: Theme.of(context).primaryColor.withAlpha(25),
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  child: Icon(Icons.person_off, color: Colors.red.shade700),
                ),
                title: Text(
                  orphaned.child.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'ID: ${orphaned.child.id} | Parent ID: ${orphaned.child.parentId}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${orphaned.sessions.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'сессий',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    _selectedChild = orphaned;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChildDetails(OrphanedChildData orphaned) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Карточка с информацией о ребенке
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.red.shade100,
                        child: Icon(
                          Icons.person_off,
                          size: 30,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              orphaned.child.fullName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Нет родителя (ID: ${orphaned.child.parentId})',
                                style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _deleteSelectedChild,
                        icon: const Icon(Icons.delete),
                        label: const Text('Удалить'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildDetailRow('ID ребенка', '${orphaned.child.id}'),
                  _buildDetailRow(
                    'Дата рождения',
                    dateFormat.format(orphaned.child.dateOfBirth),
                  ),
                  _buildDetailRow(
                    'Диагноз',
                    orphaned.child.diagnosis ?? 'Не указан',
                  ),
                  _buildDetailRow(
                    'ID родителя (несущ.)',
                    '${orphaned.child.parentId}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Связанные сессии
          Text(
            'Связанные сессии (${orphaned.sessions.length})',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (orphaned.sessions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Нет связанных сессий',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            )
          else
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orphaned.sessions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final session = orphaned.sessions[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          session.isCompleted
                              ? Colors.green.shade100
                              : Colors.blue.shade100,
                      child: Icon(
                        session.isCompleted ? Icons.check : Icons.schedule,
                        color:
                            session.isCompleted
                                ? Colors.green.shade700
                                : Colors.blue.shade700,
                      ),
                    ),
                    title: Text(dateTimeFormat.format(session.sessionDateTime)),
                    subtitle: Text(
                      'ID: ${session.id} | Сотрудник ID: ${session.employeeId} | Тип: ${session.activityTypeId}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${session.price.toStringAsFixed(0)} ₽',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          session.isPaid ? 'Оплачено' : 'Не оплачено',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                session.isPaid ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
