import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_card.dart';
import 'avatar_circle.dart';
import 'status_pill.dart';

/// One group in the Home list: initials icon, name, member count and a
/// balance pill (owed / owes / settled / no expenses).
class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.name,
    required this.memberCount,
    required this.balance,
    this.hasExpenses = true,
    this.currency = '₱',
    this.onTap,
  });

  final String name;
  final int memberCount;

  /// Your balance in this group. Positive = you are owed, negative = you owe.
  final double balance;

  /// False for a new group, which shows "No expenses" instead of
  /// "Settled ✓" (its balance is 0 only because nothing was added yet).
  final bool hasExpenses;
  final String currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      child: Row(
        spacing: 12,
        children: [
          AvatarCircle(name: name, size: 48),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  name,
                  style: textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  memberCount == 1 ? '1 member' : '$memberCount members',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          hasExpenses
              ? StatusPill.fromAmount(balance, currency: currency)
              : const StatusPill(status: BalanceStatus.noExpenses),
        ],
      ),
    );
  }
}
