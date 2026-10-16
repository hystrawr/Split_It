import 'package:flutter/material.dart';

import '../app_routes.dart';

/// Group Details screen (/group). Placeholder until members and expenses are
/// built.
class GroupDetailsScreen extends StatelessWidget {
  const GroupDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Details')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.addExpense),
              child: const Text('+ Add Expense'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.balance),
              child: const Text('Balances'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.expense),
              child: const Text('Open expense'),
            ),
          ],
        ),
      ),
    );
  }
}
