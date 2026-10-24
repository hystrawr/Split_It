import 'package:flutter/material.dart';

import '../app_routes.dart';

/// Expense Detail screen (/expense). Placeholder until the split breakdown is
/// built.
class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Details')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.addExpense),
              child: const Text('Edit'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}
