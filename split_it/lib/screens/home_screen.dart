import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../providers/home_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/group_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/summary_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = context.read<HomeProvider>().query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddGroup() => Navigator.pushNamed(context, AppRoutes.addGroup);

  void _openGroup(GroupSummary group) =>
      Navigator.pushNamed(context, AppRoutes.group, arguments: group.id);

  Future<bool> _confirmDelete(GroupSummary group) {
    return ConfirmDialog.show(
      context,
      title: 'Delete group?',
      message: '"${group.name}" and all its expenses will be removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
  }

  void _deleteGroup(GroupSummary group) {
    context.read<HomeProvider>().deleteGroup(group.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Deleted "${group.name}"')));
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<HomeProvider>().search('');
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              _buildGreeting(context, home.userName),
              SummaryBanner(
                title: 'Total balance',
                items: [
                  SummaryItem(
                    label: 'you are owed',
                    value: '₱${home.totalOwed.toStringAsFixed(2)}',
                  ),
                  SummaryItem(
                    label: 'you owe',
                    value: '₱${home.totalOwe.toStringAsFixed(2)}',
                  ),
                ],
              ),
              _buildSearchRow(home),
              Expanded(child: _buildGroupList(home)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, String userName) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hi, $userName!', style: textTheme.headlineMedium),
              Text(
                'Who owes whom today?',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        AvatarCircle(name: userName, size: 48),
      ],
    );
  }

  Widget _buildSearchRow(HomeProvider home) {
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: home.search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search groups',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: home.query.isEmpty
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

  Widget _buildGroupList(HomeProvider home) {
    if (home.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (home.hasNoGroups) {
      return const EmptyState(
        icon: Icons.group_outlined,
        title: 'No groups yet',
        message: 'Make a group to start splitting expenses.',
      );
    }

    final groups = home.groups;
    if (groups.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No matches',
        message: 'No group is named "${home.query.trim()}".',
      );
    }

    return ListView.separated(
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
            hasExpenses: group.hasExpenses,
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
