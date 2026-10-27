import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../models/group.dart';
import '../providers/balance_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/member_balance_tile.dart';
import '../widgets/primary_button.dart';
import '../widgets/summary_banner.dart';
import 'add_expense_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  const GroupDetailsScreen({super.key});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  static const int _expensesTab = 0;
  static const int _membersTab = 1;

  int _tabIndex = _expensesTab;

  String? get _groupId => ModalRoute.of(context)?.settings.arguments as String?;
  Group? _group;
  late BalanceProvider _balances;

  String get _groupName => _group?.name ?? 'Group';
  String get _currency => _group?.defaultCurrency ?? 'PHP';
  int get _memberCount => _group?.members.length ?? 0;
  double get _totalSpent => _group == null ? 0 : _balances.totalSpent(_group!);

  ///pos= u are owed. neg= u owe
  double get _yourBalance =>
      _group == null ? 0 : _balances.ownerBalance(_group!);

  /// newest first
  List<_ExpenseTile> get _expenseTiles {
    final group = _group;
    if (group == null) return const [];
    final expenses = [...group.expenses]
      ..sort((a, b) => b.date.compareTo(a.date));
    return [
      for (final expense in expenses)
        _ExpenseTile(
          title: expense.item,
          paidBy: _nameOf(group, expense.paidBy),
          date: expense.date,
          amount: expense.amountPhp,
          onTap: () => _openExpense(expense.id),
        ),
    ];
  }

  List<MemberBalanceTile> get _memberTiles {
    final group = _group;
    if (group == null) return const [];
    final balances = _balances.netBalances(group);
    return [
      for (final member in group.members)
        MemberBalanceTile(
          name: member.name,
          paid: _balances.paidBy(group, member.id),
          balance: balances[member.id] ?? 0,
        ),
    ];
  }

  /// loads groups
  void _retry() => context.read<GroupProvider>().loadGroups();

  static String _nameOf(Group group, String memberId) {
    for (final member in group.members) {
      if (member.id == memberId) return member.name;
    }
    return 'Unknown';
  }

  static String _peso(double amount) => '₱${amount.toStringAsFixed(2)}';

  void _openAddExpense() => Navigator.pushNamed(
    context,
    AppRoutes.addExpense,
    arguments: AddExpenseArgs(groupId: _groupId),
  );

  void _openBalances() =>
      Navigator.pushNamed(context, AppRoutes.balance, arguments: _groupId);

  void _openExpense(String expenseId) =>
      Navigator.pushNamed(context, AppRoutes.expense, arguments: expenseId);

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    _balances = context.watch<BalanceProvider>();
    final groupId = _groupId;
    _group = groupId == null ? null : groupProvider.groupById(groupId);

    return Scaffold(
      appBar: AppHeader(title: _groupName),
      body: SafeArea(child: _buildBody(groupProvider.isLoading)),
    );
  }

  Widget _buildBody(bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_group == null) {
      return ErrorState(
        title: "Couldn't load this group",
        message: 'It may have been deleted.',
        onRetry: _retry,
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          SummaryBanner(
            title: 'Total spent',
            items: [
              SummaryItem(
                label: _memberCount == 1
                    ? '1 member · $_currency'
                    : '$_memberCount members · $_currency',
                value: _peso(_totalSpent),
              ),
              SummaryItem(
                label: _yourBalance < 0 ? 'you owe' : "you're owed",
                value: _peso(_yourBalance.abs()),
              ),
            ],
          ),
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Add Expense',
                  icon: Icons.add,
                  expand: true,
                  onPressed: _openAddExpense,
                ),
              ),
              Expanded(
                child: PrimaryButton(
                  label: 'Balances',
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.surface,
                  expand: true,
                  onPressed: _openBalances,
                ),
              ),
            ],
          ),
          _TabToggle(
            labels: const ['Expenses', 'Members'],
            selectedIndex: _tabIndex,
            onChanged: (index) => setState(() => _tabIndex = index),
          ),
          Expanded(
            child: _tabIndex == _membersTab
                ? _buildMemberList()
                : _buildExpenseList(),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Tap an expense for details · Members tab shows each balance',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList() {
    final tiles = _expenseTiles;
    if (tiles.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No expenses yet',
        message: 'Add the first expense to start splitting.',
      );
    }
    return _buildTileList(tiles);
  }

  Widget _buildMemberList() {
    final tiles = _memberTiles;
    if (tiles.isEmpty) {
      return const EmptyState(
        icon: Icons.group_outlined,
        title: 'No members',
        message: 'Members added to this group show up here.',
      );
    }
    return _buildTileList(tiles);
  }

  Widget _buildTileList(List<Widget> tiles) {
    return ListView.separated(
      // Room at the bottom for the last card's offset shadow.
      padding: const EdgeInsets.only(bottom: 16, right: 4),
      itemCount: tiles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => tiles[index],
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.title,
    required this.paidBy,
    required this.date,
    required this.amount,
    required this.onTap,
  });

  final String title;
  final String paidBy;
  final DateTime date;

  /// Amount in pesos.
  final double amount;
  final VoidCallback onTap;

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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shortDate = '${_months[date.month - 1]} ${date.day}';

    return AppCard(
      onTap: onTap,
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Paid by $paidBy · $shortDate',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text('₱${amount.toStringAsFixed(2)}', style: textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _TabToggle extends StatelessWidget {
  const _TabToggle({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.chipRadius),
        border: const Border.fromBorderSide(AppTheme.outlineSide),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            _buildTab(context, i, labels[i]),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index, String label) {
    final active = index == selectedIndex;

    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        child: GestureDetector(
          onTap: () => onChanged(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.amber : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.chipRadius),
              border: active
                  ? const Border.fromBorderSide(AppTheme.outlineSide)
                  : null,
            ),
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
        ),
      ),
    );
  }
}
