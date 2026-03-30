import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rehabilitation_center_app/core/database/app_database.dart';
import 'package:rehabilitation_center_app/features/clients/domain/child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/parent.dart';

/// Показывает нижний лист с историей баланса (пополнения и занятия)
/// для указанного родителя.
Future<void> showParentBalanceHistoryDialog({
  required BuildContext context,
  required AppDatabase db,
  required Parent parent,
  required List<Child> children,
  VoidCallback? onBalanceUpdated,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (_) => _BalanceHistorySheet(
          db: db,
          parent: parent,
          children: children,
          onBalanceUpdated: onBalanceUpdated,
        ),
  );
}

class _BalanceHistorySheet extends StatefulWidget {
  final AppDatabase db;
  final Parent parent;
  final List<Child> children;
  final VoidCallback? onBalanceUpdated;

  const _BalanceHistorySheet({
    required this.db,
    required this.parent,
    required this.children,
    this.onBalanceUpdated,
  });

  @override
  State<_BalanceHistorySheet> createState() => _BalanceHistorySheetState();
}

class _BalanceHistorySheetState extends State<_BalanceHistorySheet> {
  bool _isLoading = true;
  String? _error;
  late double _currentBalance;

  List<Payment> _payments = [];
  List<_SessionRow> _sessionRows = [];

  final _dateFormat = DateFormat('dd.MM.yyyy');
  final _currencyFormat = NumberFormat('#,##0.00', 'ru_RU');

  @override
  void initState() {
    super.initState();
    _currentBalance = widget.parent.balance;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final childIds = widget.children.map((c) => c.id).toList();

      // Загружаем пополнения и занятия
      final payments = await widget.db.paymentDao.getPaymentsForParent(
        widget.parent.id,
      );
      final sessionResults = await widget.db.paymentDao
          .getSessionsForParentChildren(childIds);

      final sessionRows =
          sessionResults.map((row) {
            final session = row.readTable(widget.db.sessions);
            final child = row.readTable(widget.db.children);
            final activity = row.readTable(widget.db.activityTypes);
            return _SessionRow(
              session: session,
              childFullName: child.fullName,
              activityName: activity.name,
            );
          }).toList();

      _debugPrintLoadedHistory(payments: payments, sessionRows: sessionRows);

      if (mounted) {
        setState(() {
          _payments = payments;
          _sessionRows = sessionRows;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _debugPrintLoadedHistory({
    required List<Payment> payments,
    required List<_SessionRow> sessionRows,
  }) {
    final combinedEntries = <_HistoryEntry>[
      ...payments.map((payment) => _PaymentEntry(payment)),
      ...sessionRows.map((row) => _SessionEntry(row)),
    ]..sort((a, b) => b.date.compareTo(a.date));

    debugPrint('======== Parent Balance History Debug ========');
    debugPrint(
      'Parent: ${widget.parent.id} | ${widget.parent.fullName} | currentBalance=$_currentBalance',
    );
    debugPrint('Payments count: ${payments.length}');

    for (final payment in payments) {
      debugPrint(
        'PAYMENT id=${payment.id}, clientId=${payment.clientId}, date=${payment.paymentDate.toIso8601String()}, amount=${payment.amount}, type=${payment.type}',
      );
    }

    debugPrint('Sessions count: ${sessionRows.length}');

    for (final row in sessionRows) {
      debugPrint(
        'SESSION id=${row.session.id}, child=${row.childFullName}, date=${row.session.sessionDateTime.toIso8601String()}, price=${row.session.price}, activity=${row.activityName}',
      );
    }

    debugPrint('Combined entries shown in dialog: ${combinedEntries.length}');

    for (final entry in combinedEntries) {
      switch (entry) {
        case _PaymentEntry(:final payment):
          debugPrint(
            'ENTRY payment id=${payment.id}, date=${payment.paymentDate.toIso8601String()}, amount=${payment.amount}',
          );
        case _SessionEntry(:final row):
          debugPrint(
            'ENTRY session id=${row.session.id}, date=${row.session.sessionDateTime.toIso8601String()}, price=${row.session.price}',
          );
      }
    }

    final totalSessions = sessionRows.fold<double>(
      0,
      (sum, row) => sum + row.session.price,
    );
    final totalTopUps = _currentBalance + totalSessions;

    debugPrint(
      'Summary totals: totalTopUps=$totalTopUps, totalSessions=$totalSessions, balance=$_currentBalance',
    );
    debugPrint('=============================================');
  }

  /// Сумма всех занятий (расходы)
  double get _totalSessions =>
      _sessionRows.fold(0.0, (sum, r) => sum + r.session.price);

  /// Общая сумма пополнений = баланс + занятия
  /// (включает пополнения, сделанные до начала записи)
  double get _totalTopUps => _currentBalance + _totalSessions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'История баланса — ${widget.parent.fullName}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Body
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                        ? _ErrorView(message: _error!)
                        : _buildContent(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    // Объединяем пополнения и занятия в единый хронологический список
    final List<_HistoryEntry> entries = [
      ..._payments.map((p) => _PaymentEntry(p)),
      ..._sessionRows.map((r) => _SessionEntry(r)),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: entries.length + 1, // +1 for summary card
      itemBuilder: (context, index) {
        if (index == 0) {
          return _SummaryCard(
            totalTopUps: _totalTopUps,
            totalSessions: _totalSessions,
            balance: _currentBalance,
            currencyFormat: _currencyFormat,
          );
        }
        final entry = entries[index - 1];
        if (entry is _PaymentEntry) {
          return _PaymentTile(
            payment: entry.payment,
            dateFormat: _dateFormat,
            currencyFormat: _currencyFormat,
            onEdit: () => _showEditPaymentDialog(entry.payment),
          );
        } else if (entry is _SessionEntry) {
          return _SessionTile(
            row: entry.row,
            showChildName: widget.children.length > 1,
            dateFormat: _dateFormat,
            currencyFormat: _currencyFormat,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Future<void> _showEditPaymentDialog(Payment payment) async {
    final controller = TextEditingController(text: payment.amount.toString());
    final result = await showDialog<double>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Изменить сумму пополнения'),
            content: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Сумма (₽)'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () {
                  final newAmount = double.tryParse(
                    controller.text.replaceAll(',', '.'),
                  );
                  Navigator.pop(context, newAmount);
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
    );

    if (result != null && result != payment.amount && result >= 0) {
      try {
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }

        await widget.db.paymentDao.updateTopUpAmount(
          payment.id,
          widget.parent.id,
          payment.amount,
          result,
        );

        final updatedParent =
            await (widget.db.select(widget.db.parents)
              ..where((p) => p.id.equals(widget.parent.id))).getSingle();

        if (mounted) {
          setState(() {
            _currentBalance = updatedParent.balance;
          });

          widget.onBalanceUpdated?.call();

          await _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка обновления суммы: $e')),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}

// ── Data classes ─────────────────────────────────────────────────────────────

class _SessionRow {
  final Session session;
  final String childFullName;
  final String activityName;

  const _SessionRow({
    required this.session,
    required this.childFullName,
    required this.activityName,
  });
}

abstract class _HistoryEntry {
  DateTime get date;
}

class _PaymentEntry extends _HistoryEntry {
  final Payment payment;
  _PaymentEntry(this.payment);
  @override
  DateTime get date => payment.paymentDate;
}

class _SessionEntry extends _HistoryEntry {
  final _SessionRow row;
  _SessionEntry(this.row);
  @override
  DateTime get date => row.session.sessionDateTime;
}

// ── Tiles ────────────────────────────────────────────────────────────────────

class _PaymentTile extends StatelessWidget {
  final Payment payment;
  final DateFormat dateFormat;
  final NumberFormat currencyFormat;
  final VoidCallback onEdit;

  const _PaymentTile({
    required this.payment,
    required this.dateFormat,
    required this.currencyFormat,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade100,
        child: const Icon(Icons.arrow_upward, color: Colors.green, size: 20),
      ),
      title: const Text('Пополнение баланса'),
      subtitle: Text(dateFormat.format(payment.paymentDate.toLocal())),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+${currencyFormat.format(payment.amount)} ₽',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: onEdit,
            splashRadius: 20,
            tooltip: 'Изменить сумму',
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final _SessionRow row;
  final bool showChildName;
  final DateFormat dateFormat;
  final NumberFormat currencyFormat;

  const _SessionTile({
    required this.row,
    required this.showChildName,
    required this.dateFormat,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      dateFormat.format(row.session.sessionDateTime.toLocal()),
      if (showChildName) row.childFullName,
    ];

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.red.shade100,
        child: const Icon(
          Icons.school_outlined,
          color: Colors.redAccent,
          size: 20,
        ),
      ),
      title: Text(row.activityName),
      subtitle: Text(parts.join(' · ')),
      trailing: Text(
        '−${currencyFormat.format(row.session.price)} ₽',
        style: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}

// ── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double totalTopUps;
  final double totalSessions;
  final double balance;
  final NumberFormat currencyFormat;

  const _SummaryCard({
    required this.totalTopUps,
    required this.totalSessions,
    required this.balance,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _SummaryRow(
              icon: Icons.arrow_upward,
              label: 'Пополнения (всего)',
              value: '+${currencyFormat.format(totalTopUps)} ₽',
              color: Colors.green,
            ),
            const Divider(height: 16),
            _SummaryRow(
              icon: Icons.arrow_downward,
              label: 'Занятия',
              value: '−${currencyFormat.format(totalSessions)} ₽',
              color: Colors.redAccent,
            ),
            const Divider(height: 16),
            _SummaryRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Баланс',
              value: '${currencyFormat.format(balance)} ₽',
              color: balance < 0 ? Colors.redAccent : Colors.green,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Ошибка загрузки данных:\n$message',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }
}
