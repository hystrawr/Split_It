import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum BalanceStatus { owed, owes, paid, settled }

/// Pill showing where a balance or debt stands: owed, owes, paid or settled.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.status,
    this.amount,
    this.currency = '₱',
  });

  /// Picks the status from a signed balance. Positive = you are owed,
  /// negative = you owe, zero = settled.
  factory StatusPill.fromAmount(
    double amount, {
    Key? key,
    String currency = '₱',
  }) {
    final BalanceStatus status;
    if (amount > 0) {
      status = BalanceStatus.owed;
    } else if (amount < 0) {
      status = BalanceStatus.owes;
    } else {
      status = BalanceStatus.settled;
    }
    return StatusPill(
      key: key,
      status: status,
      amount: amount.abs(),
      currency: currency,
    );
  }

  final BalanceStatus status;

  /// Shown after "owed" / "owes". Ignored for paid and settled.
  final double? amount;
  final String currency;

  String get _money =>
      amount == null ? '' : ' $currency${amount!.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      BalanceStatus.owed => (AppColors.owed, 'owed$_money'),
      BalanceStatus.owes => (AppColors.owes, 'owes$_money'),
      BalanceStatus.paid => (AppColors.paid, 'Paid'),
      BalanceStatus.settled => (AppColors.settled, 'Settled ✓'),
    };

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
