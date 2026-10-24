import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/group_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/summary_banner.dart';

// TODO: replace with the Group model
class _GroupItem {
  const _GroupItem({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.balance,
  });

  final String id;
  final String name;
  final int memberCount;
  final double balance;
}

/// Home screen (/home): greeting, total balance, search and the group list.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // TODO: read the user's name and groups from GroupProvider.
  static const String _userName = 'Barby';

  final List<_GroupItem> _groups = [];

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_GroupItem> get _filteredGroups {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _groups;
    return _groups
        .where((group) => group.name.toLowerCase().contains(query))
        .toList();
  }

  double get _totalOwed => _groups
      .where((group) => group.balance > 0)
      .fold(0, (sum, group) => sum + group.balance);

  double get _totalOwe => _groups
      .where((group) => group.balance < 0)
      .fold(0, (sum, group) => sum - group.balance);

  void _openAddGroup() => Navigator.pushNamed(context, AppRoutes.addGroup);

  void _openGroup(_GroupItem group) =>
      Navigator.pushNamed(context, AppRoutes.group, arguments: group.id);

  Future<bool> _confirmDelete(_GroupItem group) {
    return ConfirmDialog.show(
      context,
      title: 'Delete group?',
      message: '"${group.name}" and all its expenses will be removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
  }

  void _deleteGroup(_GroupItem group) {
    setState(() => _groups.remove(group));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Deleted "${group.name}"')));
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              _buildGreeting(context),
              SummaryBanner(
                title: 'Total balance',
                items: [
                  SummaryItem(
                    label: 'you are owed',
                    value: '₱${_totalOwed.toStringAsFixed(2)}',
                  ),
                  SummaryItem(
                    label: 'you owe',
                    value: '₱${_totalOwe.toStringAsFixed(2)}',
                  ),
                ],
              ),
              _buildSearchRow(),
              Expanded(child: _buildGroupList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hi, $_userName!', style: textTheme.headlineMedium),
              Text(
                'Who owes whom today?',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const AvatarCircle(name: _userName, size: 48),
      ],
    );
  }

  Widget _buildSearchRow() {
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search groups',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: _clearSearch,
                    ),
            ),
          ),
        ),
        PrimaryButton(
          label: 'New group',
          icon: Icons.add,
          onPressed: _openAddGroup,
        ),
      ],
    );
  }

  Widget _buildGroupList() {
    if (_groups.isEmpty) {
      return const EmptyState(
        icon: Icons.group_outlined,
        title: 'No groups yet',
        message: 'Make a group to start splitting expenses.',
      );
    }

    final groups = _filteredGroups;
    if (groups.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No matches',
        message: 'No group is named "${_query.trim()}".',
      );
    }

    return ListView.separated(
      // Room at the bottom for the last card's offset shadow.
      padding: const EdgeInsets.only(bottom: 24, right: 4),
      itemCount: groups.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final group = groups[index];
        return Dismissible(
          key: ValueKey(group.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(group),
          onDismissed: (_) => _deleteGroup(group),
          background: _buildDeleteBackground(),
          child: GroupCard(
            name: group.name,
            memberCount: group.memberCount,
            balance: group.balance,
            onTap: () => _openGroup(group),
          ),
        );
      },
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: AppTheme.borderRadius,
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    );
  }
}
