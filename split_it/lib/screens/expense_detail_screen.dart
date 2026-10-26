import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/error_state.dart';
import '../widgets/primary_button.dart';
import 'add_expense_screen.dart';

/// Expense Detail screen (/expense): the item card, the split breakdown per
/// person and the Edit / Delete buttons. Expects the expenseId as the route
/// argument.
///
/// UI only. The expense, the shares and deleting all come from the data
/// layer; nothing is calculated here.
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

  // TODO: read these from GroupProvider for the expenseId once the data
  // layer is in. Until then they show an empty expense.
  bool get _isLoading => false;
  String? get _error => null;

  /// The expense's group (Expense.groupId), passed on to Edit.
  String? get _groupId => null;
  String get _item => 'Expense';
  String get _where => '';
  String get _category => 'Others';
  DateTime? get _date => null;

  /// The expense in pesos (Expense.amountPhp).
  double get _amountPhp => 0;

  /// The amount as typed and its saved rate, e.g. "\$5.00 USD · 1 USD =
  /// ₱58.24". Null for PHP expenses, which hides the line.
  String? get _originalAmountText => null;

  // TODO: one row per person in the split, payer first, e.g.
  // _SplitRow(name: 'Barby', paid: 300, share: 100) for the payer and
  // _SplitRow(name: 'Trisha', share: 100) for everyone else.
  List<_SplitRow> get _splitRows => const [];

  // TODO: ask the provider to fetch the expense again.
  void _retry() {}

  static String _peso(double amount) => '₱${amount.toStringAsFixed(2)}';

  String? _expenseId(BuildContext context) =>
      ModalRoute.of(context)?.settings.arguments as String?;

  void _edit(BuildContext context) => Navigator.pushNamed(
    context,
    AppRoutes.addExpense,
    arguments: AddExpenseArgs(
      groupId: _groupId,
      expenseId: _expenseId(context),
    ),
  );

  Future<void> _delete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete expense?',
      message: 'This removes "$_item" and updates everyone\'s balances.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    // TODO: delete the expense through GroupProvider.
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Expense Details'),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return ErrorState(
        title: "Couldn't load this expense",
        message: error,
        onRetry: _retry,
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final rows = _splitRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            // Right/bottom room for the cards' offset shadows.
            padding: const EdgeInsets.fromLTRB(20, 8, 24, 16),
            children: [
              _buildItemCard(context),
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
          child: _buildActions(context),
        ),
      ],
    );
  }

  /// Big centered card: item, peso amount, "Panda Coffee · Aug 5 · Food".
  Widget _buildItemCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final date = _date;
    final details = [
      if (_where.isNotEmpty) _where,
      if (date != null) '${_months[date.month - 1]} ${date.day}',
      _category,
    ].join(' · ');
    final originalAmount = _originalAmountText;

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
            child: Icon(_categoryIcon(_category), color: AppColors.darkGreen),
          ),
          const SizedBox(height: 4),
          Text(
            _item,
            style: textTheme.titleLarge,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _peso(_amountPhp),
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

  Widget _buildActions(BuildContext context) {
    // Same height trick as Add Expense: Delete matches Edit's height.
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
              onPressed: () => _delete(context),
            ),
          ),
          Expanded(
            child: PrimaryButton(
              label: 'Edit',
              icon: Icons.edit_outlined,
              expand: true,
              onPressed: () => _edit(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// One person in the split. [paid] is set only for the payer.
class _SplitRow {
  // ignore: unused_element_parameter
  const _SplitRow({required this.name, required this.share, this.paid});

  final String name;

  /// This person's part of the expense, in pesos.
  final double share;

  /// What the payer paid, in pesos. Null for everyone else.
  final double? paid;
}

/// Avatar, name, "share ₱100" and a "paid ₱300" (sage) or "owes ₱100"
/// (pink) pill.
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
