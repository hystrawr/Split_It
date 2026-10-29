import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:split_it/main.dart';
import 'package:split_it/models/expense.dart';
import 'package:split_it/providers/group_provider.dart';
import 'package:split_it/screens/splash_screen.dart';

void main() {
  // GroupProvider loads from shared_preferences, which has no device in
  // tests, so every test starts with empty fake storage.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App starts on the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SplitItApp());
    // The splash shows while the groups load, then Home opens.
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Hi, Barby!'), findsOneWidget);
    expect(find.text('No groups yet'), findsOneWidget);
  });

  testWidgets('Every screen can be reached', (WidgetTester tester) async {
    await tester.pumpWidget(const SplitItApp());
    await tester.pumpAndSettle(); // past the splash

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
    // A new group has nothing to split yet, so it isn't "Settled".
    expect(find.text('No expenses'), findsOneWidget);
    expect(find.text('Settled ✓'), findsNothing);

    // Home -> Group Details through the new group's card
    await tap('Trip');
    final groupTitle = find.widgetWithText(AppBar, 'Trip');
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

    // Add an expense straight through GroupProvider so there's a row to tap.
    final context = tester.element(groupTitle);
    final groups = Provider.of<GroupProvider>(context, listen: false);
    final group = groups.groups.single;
    await groups.addExpense(
      Expense(
        id: 'expense-1',
        groupId: group.id,
        where: 'Panda Coffee',
        item: 'Iced latte',
        category: 'Food',
        amount: 300,
        currency: 'PHP',
        rate: 1,
        amountPhp: 300,
        paidBy: group.members[0].id,
        splitWith: [for (final member in group.members) member.id],
        date: DateTime(2026, 10, 27),
      ),
    );
    await tester.pumpAndSettle();

    // Group -> Expense Details -> Edit (Add Expense) -> back -> Delete
    await tap('Iced latte');
    expect(find.text('Expense Details'), findsOneWidget);
    expect(find.text('owes ₱150.00'), findsOneWidget);
    await tap('Edit');
    expect(find.widgetWithText(AppBar, 'Edit Expense'), findsOneWidget);
    await cancelExpense();
    await tap('Delete');
    expect(find.text('Delete expense?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(groupTitle, findsOneWidget);
    expect(find.text('No expenses yet'), findsOneWidget);

    // Group -> back to Home
    await back();
    expect(find.text('Hi, Barby!'), findsOneWidget);
  });
}
