import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:split_it/app_routes.dart';
import 'package:split_it/main.dart';

void main() {
  // GroupProvider loads from shared_preferences, which has no device in
  // tests, so every test starts with empty fake storage.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

    // Add Expense has no back button; an empty form closes on Cancel.
    Future<void> cancelExpense() async {
      await tester.scrollUntilVisible(
        find.text('Cancel'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tap('Cancel');
    }

    Future<void> back() async {
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    // Home -> Add Group -> back to Home. The form needs a name and one
    // other member before Create Group closes it.
    await tap('New group');
    expect(find.text('New Group'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Trip');
    await tester.enterText(
      find.widgetWithText(TextField, 'Member name'),
      'Ana',
    );
    await tap('Add');
    await tap('Create Group');
    expect(find.text('Hi, Barby!'), findsOneWidget);

    // Home -> Group Details (no group cards yet, so open the route directly)
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed(AppRoutes.group);
    await tester.pumpAndSettle();
    // Until the data layer is in, the title is the placeholder group name.
    final groupTitle = find.widgetWithText(AppBar, 'Group');
    expect(groupTitle, findsOneWidget);

    // Group -> Add Expense -> back to Group
    await tap('Add Expense');
    expect(find.widgetWithText(AppBar, 'Add Expense'), findsOneWidget);
    await cancelExpense();
    expect(groupTitle, findsOneWidget);

    // Group -> Balances -> back
    await tap('Balances');
    expect(find.widgetWithText(AppBar, 'Balances'), findsOneWidget);
    await back();

    // Group -> Expense Details -> Edit (Add Expense) -> back -> Delete
    // (no expense rows yet, so open the route directly)
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed(AppRoutes.expense, arguments: 'expense-1');
    await tester.pumpAndSettle();
    expect(find.text('Expense Details'), findsOneWidget);
    await tap('Edit');
    expect(find.widgetWithText(AppBar, 'Add Expense'), findsOneWidget);
    await cancelExpense();
    await tap('Delete');
    expect(groupTitle, findsOneWidget);

    // Group -> back to Home
    await back();
    expect(find.text('Hi, Barby!'), findsOneWidget);
  });
}
