import 'package:flutter/material.dart';

/// Add Group screen (/addGroup). Placeholder until the form is built.
class AddGroupScreen extends StatelessWidget {
  const AddGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Group')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Create Group'),
        ),
      ),
    );
  }
}
