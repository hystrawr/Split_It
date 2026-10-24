import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SplitItApp());
}

class SplitItApp extends StatelessWidget {
  const SplitItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Split It',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}
