import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Pill showing where a balance stands. Positive = you are owed,
/// negative = you owe, zero = settled.
class BalanceChip extends StatelessWidget {
  const BalanceChip({super.key, required this.amount, this.currency = '₱'});

  /// Forces the "Settled ✓" look, e.g. for a paid debt on the Balance screen.
  const BalanceChip.settled({super.key}) : amount = 0, currency = '₱';

  final double amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    if (amount > 0) {
      color = AppColors.owed;
      label = 'owed $currency${amount.toStringAsFixed(2)}';
    } else if (amount < 0) {
      color = AppColors.owes;
      label = 'owes $currency${(-amount).toStringAsFixed(2)}';
    } else {
      color = AppColors.settled;
      label = 'Settled ✓';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.chipRadius),
        border: const Border.fromBorderSide(AppTheme.outlineSide),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
