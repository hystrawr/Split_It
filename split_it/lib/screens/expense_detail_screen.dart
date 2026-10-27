import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../models/expense.dart';
import '../models/group.dart';
import '../providers/balance_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/error_state.dart';
import '../widgets/primary_button.dart';
import 'add_expense_screen.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key});

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _peso(double amount) => '₱${amount.toStringAsFixed(2)}';

  static String? _originalAmountText(Expense expense) {
    if (expense.currency == 'PHP' || expense.rate == 0) return null;
    final code = expense.currency;
    return '${expense.amount.toStringAsFixed(2)} $code · '
        '1 $code = ${_peso(1 / expense.rate)}';
  }

  static List<_SplitRow> _splitRows(
    Group group,
    Expense expense,
    BalanceProvider balances,
  ) {
    final share = balances.shareOf(expense);
    return [
      _SplitRow(
        name: _nameOf(group, expense.paidBy),
        paid: expense.amountPhp,
        share: expense.splitWith.contains(expense.paidBy) ? share : 0,
      ),
      for (final memberId in expense.splitWith)
        if (memberId != expense.paidBy)
          _SplitRow(name: _nameOf(group, memberId), share: share),
    ];
  }

  static String _nameOf(Group group, String memberId) {
    for (final member in group.members) {
      if (member.id == memberId) return member.name;
    }
    return 'Unknown';
  }

  String? _expenseId(BuildContext context) =>
      ModalRoute.of(context)?.settings.arguments as String?;

  void _edit(BuildContext context, Expense expense) => Navigator.pushNamed(
    context,
    AppRoutes.addExpense,
    arguments: AddExpenseArgs(groupId: expense.groupId, expenseId: expense.id),
  );

  Future<void> _delete(BuildContext context, Expense expense) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete expense?',
      message:
          'This removes "${expense.item}" and updates everyone\'s '
          'balances.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final groups = context.read<GroupProvider>();
    Navigator.pop(context);
    await groups.deleteExpense(expense.groupId, expense.id);
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final balances = context.watch<BalanceProvider>();
    final expenseId = _expenseId(context);
    final expense = expenseId == null
        ? null
        : groupProvider.expenseById(expenseId);
    final group = expense == null
        ? null
        : groupProvider.groupById(expense.groupId);

    Widget body;
    if (groupProvider.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (expense == null || group == null) {
      body = ErrorState(
        title: "Couldn't load this expense",
        message: 'It may have been deleted.',
        onRetry: groupProvider.loadGroups,
      );
    } else {
      body = _buildBody(context, expense, _splitRows(group, expense, balances));
    }

    return Scaffold(
      appBar: const AppHeader(title: 'Expense Details'),
      body: SafeArea(child: body),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Expense expense,
    List<_SplitRow> rows,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 24, 16),
            children: [
              _buildItemCard(context, expense),
              const SizedBox(height: 24),
              Text('Split breakdown', style: textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                rows.length == 1
                    ? 'Split between 1 person'
                    : 'Split equally between ${rows.length} people',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                Text(
                  'No one is in this split.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                for (final row in rows) ...[
                  _SplitTile(row: row),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 24, 16),
          child: _buildActions(context, expense),
        ),
      ],
    );
  }

  /// big card
  Widget _buildItemCard(BuildContext context, Expense expense) {
    final textTheme = Theme.of(context).textTheme;
    final date = expense.date;
    final details = [
      if (expense.where.isNotEmpty) expense.where,
      '${_months[date.month - 1]} ${date.day}',
      expense.category,
    ].join(' · ');
    final originalAmount = _originalAmountText(expense);

    return AppCard(
      color: AppColors.sage,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        spacing: 6,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(AppTheme.outlineSide),
            ),
            child: Icon(
              _categoryIcon(expense.category),
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            expense.item,
            style: textTheme.titleLarge,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _peso(expense.amountPhp),
              style: textTheme.headlineMedium?.copyWith(
                color: AppColors.darkGreen,
              ),
            ),
          ),
          Text(
            details,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.darkGreen),
            textAlign: TextAlign.center,
          ),
          if (originalAmount != null)
            Text(
              originalAmount,
              style: textTheme.bodySmall?.copyWith(color: AppColors.darkGreen),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  static IconData _categoryIcon(String category) => switch (category) {
    'Food' => Icons.restaurant_outlined,
    'Ride' => Icons.directions_car_outlined,
    'Bills' => Icons.receipt_outlined,
    _ => Icons.shopping_bag_outlined,
  };

  Widget _buildActions(BuildContext context, Expense expense) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Expanded(
            child: PrimaryButton(
              label: 'Delete',
              icon: Icons.close,
              color: AppColors.beige,
              expand: true,
              onPressed: () => _delete(context, expense),
            ),
          ),
          Expanded(
            child: PrimaryButton(
              label: 'Edit',
              icon: Icons.edit_outlined,
              expand: true,
              onPressed: () => _edit(context, expense),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitRow {
  const _SplitRow({required this.name, required this.share, this.paid});

  final String name;
  final double share;
  final double? paid;
}

class _SplitTile extends StatelessWidget {
  const _SplitTile({required this.row});

  final _SplitRow row;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final paid = row.paid;
    final isPayer = paid != null;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        spacing: 12,
        children: [
          AvatarCircle(name: row.name),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  row.name,
                  style: textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'share ${ExpenseDetailScreen._peso(row.share)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isPayer ? AppColors.owed : AppColors.owes,
              borderRadius: BorderRadius.circular(AppTheme.chipRadius),
              border: const Border.fromBorderSide(AppTheme.outlineSide),
            ),
            child: Text(
              isPayer
                  ? 'paid ${ExpenseDetailScreen._peso(paid)}'
                  : 'owes ${ExpenseDetailScreen._peso(row.share)}',
              style: textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}
