import 'package:flutter/material.dart';

/// Home screen (/home). Placeholder until the group list is built.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Split It')),
      body: Center(
        child: Text(
          'No groups yet',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
