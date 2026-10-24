import 'package:flutter/material.dart';

/// Balance screen (/balance). Placeholder until the debt list is built.
class BalanceScreen extends StatelessWidget {
  const BalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Balances')),
      body: Center(
        child: Text(
          'No debts yet',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
