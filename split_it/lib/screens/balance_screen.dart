import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/debt.dart';
import '../models/group.dart';
import '../providers/balance_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_pill.dart';

/// Balance screen (/balance): who owes whom in one group, grouped by the
/// person who owes. Expects the groupId as the route argument.
class BalanceScreen extends StatelessWidget {
  const BalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groupId = ModalRoute.of(context)?.settings.arguments as String?;
    final groupProvider = context.watch<GroupProvider>();
    final balances = context.watch<BalanceProvider>();
    final group = groupId == null ? null : groupProvider.groupById(groupId);

    return Scaffold(
      appBar: const AppHeader(title: 'Balances'),
      body: SafeArea(
        child: groupProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : group == null
            ? const EmptyState(
                icon: Icons.search_off,
                title: 'Group not found',
                message: 'It may have been deleted.',
              )
            : _DebtList(group: group, debts: balances.debtsFor(group)),
      ),
    );
  }
}

/// The debt cards for [group], one card per person who owes.
class _DebtList extends StatelessWidget {
  const _DebtList({required this.group, required this.debts});

  final Group group;
  final List<Debt> debts;

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No debts yet',
        message: 'Add an expense shared with others to see who owes whom.',
      );
    }
    if (debts.every((debt) => debt.isSettled)) {
      return const EmptyState(
        icon: Icons.celebration_outlined,
        title: 'Everyone is settled up',
        message: 'No one owes anything in this group.',
      );
    }

    // Owner first ("You owe"), then the others in member order.
    final debtors = [
      for (final member in group.members)
        if (debts.any((debt) => debt.from == member.id)) member.id,
    ];

    return ListView.separated(
      // Room at the bottom for the last card's offset shadow.
      padding: const EdgeInsets.fromLTRB(20, 8, 24, 24),
      itemCount: debtors.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final debtorId = debtors[index];
        return _DebtorCard(
          group: group,
          title: _isOwner(debtorId) ? 'You owe' : '${_nameOf(debtorId)} owes',
          debts: debts.where((debt) => debt.from == debtorId).toList(),
          nameOf: _nameOf,
        );
      },
    );
  }

  bool _isOwner(String memberId) =>
      group.members.any((member) => member.id == memberId && member.isOwner);

  /// "You" for the owner, otherwise the member's name.
  String _nameOf(String memberId) {
    for (final member in group.members) {
      if (member.id == memberId) return member.isOwner ? 'You' : member.name;
    }
    return 'Unknown';
  }
}

/// One person's debts, e.g. "Kelly owes" with a row per expense.
class _DebtorCard extends StatelessWidget {
  const _DebtorCard({
    required this.group,
    required this.title,
    required this.debts,
    required this.nameOf,
  });

  final Group group;
  final String title;
  final List<Debt> debts;
  final String Function(String memberId) nameOf;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.darkGreen),
          ),
          for (final debt in debts)
            _DebtRow(group: group, debt: debt, creditor: nameOf(debt.to)),
        ],
      ),
    );
  }
}

/// "Trisha  ₱100.00  Iced latte  [Mark as settled]". Settled rows are faded
/// and show a "Settled ✓" pill instead of the button.
class _DebtRow extends StatelessWidget {
  const _DebtRow({
    required this.group,
    required this.debt,
    required this.creditor,
  });

  final Group group;
  final Debt debt;
  final String creditor;

  String get _item {
    for (final expense in group.expenses) {
      if (expense.id == debt.expenseId) return expense.item;
    }
    return '';
  }

  Future<void> _markSettled(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Mark as settled?',
      message:
          'Mark this debt as paid? $creditor will no longer be owed '
          '₱${debt.amount.toStringAsFixed(2)} for $_item.',
      confirmLabel: 'Mark as paid',
    );
    if (!confirmed || !context.mounted) return;

    await context.read<BalanceProvider>().markSettled(group.id, debt);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Debt marked as settled')));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: debt.isSettled ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: debt.isSettled ? AppColors.settled : AppColors.paid,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outline, width: 1.5),
        ),
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    creditor,
                    style: textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '₱${debt.amount.toStringAsFixed(2)}',
                    style: textTheme.titleLarge,
                  ),
                  if (_item.isNotEmpty)
                    Text(
                      _item,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (debt.isSettled)
              const StatusPill(status: BalanceStatus.settled)
            else
              PrimaryButton(
                label: 'Mark as settled',
                color: AppColors.sage,
                onPressed: () => _markSettled(context),
              ),
          ],
        ),
      ),
    );
  }
}
