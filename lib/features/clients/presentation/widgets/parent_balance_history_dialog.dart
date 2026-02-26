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
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (_) => _BalanceHistorySheet(db: db, parent: parent, children: children),
  );
}

class _BalanceHistorySheet extends StatefulWidget {
  final AppDatabase db;
  final Parent parent;
  final List<Child> children;

  const _BalanceHistorySheet({
    required this.db,
    required this.parent,
    required this.children,
  });

  @override
  State<_BalanceHistorySheet> createState() => _BalanceHistorySheetState();
}

class _BalanceHistorySheetState extends State<_BalanceHistorySheet> {
  bool _isLoading = true;
  String? _error;

  List<Payment> _payments = [];
  List<_SessionRow> _sessionRows = [];

  final _dateFormat = DateFormat('dd.MM.yyyy');
  final _currencyFormat = NumberFormat('#,##0.00', 'ru_RU');

  @override
  void initState() {
    super.initState();
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

  /// Сумма всех занятий (расходы)
  double get _totalSessions =>
      _sessionRows.fold(0.0, (sum, r) => sum + r.session.price);

  /// Общая сумма пополнений = баланс + занятия
  /// (включает пополнения, сделанные до начала записи)
  double get _totalTopUps => widget.parent.balance + _totalSessions;

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
            balance: widget.parent.balance,
            currencyFormat: _currencyFormat,
          );
        }
        final entry = entries[index - 1];
        if (entry is _PaymentEntry) {
          return _PaymentTile(
            payment: entry.payment,
            dateFormat: _dateFormat,
            currencyFormat: _currencyFormat,
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

  const _PaymentTile({
    required this.payment,
    required this.dateFormat,
    required this.currencyFormat,
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
      trailing: Text(
        '+${currencyFormat.format(payment.amount)} ₽',
        style: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
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
