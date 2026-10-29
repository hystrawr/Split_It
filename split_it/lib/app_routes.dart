import 'package:flutter/material.dart';

import 'screens/add_expense_screen.dart';
import 'screens/add_group_screen.dart';
import 'screens/balance_screen.dart';
import 'screens/expense_detail_screen.dart';
import 'screens/group_details_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

/// Named routes for every screen in the app.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String home = '/home';
  static const String addGroup = '/addGroup';
  static const String group = '/group';
  static const String addExpense = '/addExpense';
  static const String expense = '/expense';
  static const String balance = '/balance';

  /// Passed to MaterialApp.routes.
  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    home: (context) => const HomeScreen(),
    addGroup: (context) => const AddGroupScreen(),
    group: (context) => const GroupDetailsScreen(),
    addExpense: (context) => const AddExpenseScreen(),
    expense: (context) => const ExpenseDetailScreen(),
    balance: (context) => const BalanceScreen(),
  };
}
