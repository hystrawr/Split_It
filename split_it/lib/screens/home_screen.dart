import 'package:flutter/material.dart';

import '../app_routes.dart';

/// Home screen (/home). Placeholder until the group list is built.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Split It')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Text(
              'No groups yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.addGroup),
              child: const Text('+ New group'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.group),
              child: const Text('Open group'),
            ),
          ],
        ),
      ),
    );
  }
}
