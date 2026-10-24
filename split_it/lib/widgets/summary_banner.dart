import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_card.dart';

/// One label/value pair inside a [SummaryBanner].
class SummaryItem {
  const SummaryItem({required this.label, required this.value});

  final String label;
  final String value;
}

/// Green banner at the top of Home (total balance) and Group Details
/// (total spent, members, you're owed).
class SummaryBanner extends StatelessWidget {
  const SummaryBanner({super.key, required this.title, required this.items});

  final String title;
  final List<SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      color: AppColors.sage,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(color: AppColors.darkGreen),
          ),
          Row(
            children: [
              for (final item in items)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.value,
                        style: textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.label,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
