import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:split_it/app_routes.dart';
import 'package:split_it/main.dart';

void main() {
  testWidgets('App starts on the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SplitItApp());

    expect(find.text('Hi, Barby!'), findsOneWidget);
    expect(find.text('No groups yet'), findsOneWidget);
  });

  testWidgets('Every screen can be reached', (WidgetTester tester) async {
    await tester.pumpWidget(const SplitItApp());

    Future<void> tap(String label) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    Future<void> back() async {
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    // Home -> Add Group -> back to Home
    await tap('New group');
    expect(find.text('New Group'), findsOneWidget);
    await tap('Create Group');
    expect(find.text('Hi, Barby!'), findsOneWidget);

    // Home -> Group Details (no group cards yet, so open the route directly)
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed(AppRoutes.group);
    await tester.pumpAndSettle();
    expect(find.text('Group Details'), findsOneWidget);

    // Group -> Add Expense -> back to Group
    await tap('+ Add Expense');
    expect(find.widgetWithText(AppBar, 'Add Expense'), findsOneWidget);
    await tap('Save');
    expect(find.text('Group Details'), findsOneWidget);

    // Group -> Balances -> back
    await tap('Balances');
    expect(find.widgetWithText(AppBar, 'Balances'), findsOneWidget);
    await back();

    // Group -> Expense Details -> Edit (Add Expense) -> back -> Delete
    await tap('Open expense');
    expect(find.text('Expense Details'), findsOneWidget);
    await tap('Edit');
    expect(find.widgetWithText(AppBar, 'Add Expense'), findsOneWidget);
    await back();
    await tap('Delete');
    expect(find.text('Group Details'), findsOneWidget);

    // Group -> back to Home
    await back();
    expect(find.text('Hi, Barby!'), findsOneWidget);
  });
}
