import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_card.dart';
import 'avatar_circle.dart';
import 'status_pill.dart';

/// One member with what they paid and a balance pill (owed / owes /
/// settled).
class MemberBalanceTile extends StatelessWidget {
  const MemberBalanceTile({
    super.key,
    required this.name,
    required this.paid,
    required this.balance,
    this.currency = '₱',
  });

  final String name;
  final double paid;

  /// Positive = this member is owed, negative = they owe.
  final double balance;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Row(
        spacing: 12,
        children: [
          AvatarCircle(name: name),
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
                  'paid $currency${paid.toStringAsFixed(2)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          StatusPill.fromAmount(balance, currency: currency),
        ],
      ),
    );
  }
}
