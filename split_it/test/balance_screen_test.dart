import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:split_it/models/expense.dart';
import 'package:split_it/providers/balance_provider.dart';
import 'package:split_it/providers/group_provider.dart';
import 'package:split_it/screens/balance_screen.dart';

/// Opens the Balance screen for [groupId] with real providers.
Future<void> _openBalanceScreen(
  WidgetTester tester,
  GroupProvider groups,
  String groupId,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: groups),
        ChangeNotifierProxyProvider<GroupProvider, BalanceProvider>(
          create: (_) => BalanceProvider(),
          update: (_, groups, balances) =>
              (balances ?? BalanceProvider())..updateGroups(groups),
        ),
      ],
      child: MaterialApp(
        onGenerateRoute: (_) => MaterialPageRoute(
          settings: RouteSettings(arguments: groupId),
          builder: (_) => const BalanceScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows "No debts yet" when there are no expenses', (
    tester,
  ) async {
    final groups = GroupProvider();
    await groups.addGroup(
      name: 'Cafe Barkads',
      defaultCurrency: 'PHP',
      memberNames: ['You', 'Trisha'],
    );

    await _openBalanceScreen(tester, groups, groups.groups.single.id);

    expect(find.text('No debts yet'), findsOneWidget);
  });

  testWidgets('a debt can be marked as settled', (tester) async {
    final groups = GroupProvider();
    await groups.addGroup(
      name: 'Cafe Barkads',
      defaultCurrency: 'PHP',
      memberNames: ['You', 'Trisha'],
    );
    final group = groups.groups.single;
    await groups.addExpense(
      Expense(
        id: 'latte',
        groupId: group.id,
        where: 'Panda Coffee',
        item: 'Iced latte',
        category: 'Food',
        amount: 200,
        currency: 'PHP',
        rate: 1,
        amountPhp: 200,
        paidBy: group.members[1].id,
        splitWith: [group.members[0].id, group.members[1].id],
        date: DateTime(2026, 10, 27),
      ),
    );

    await _openBalanceScreen(tester, groups, group.id);

    expect(find.text('You owe'), findsOneWidget);
    expect(find.text('₱100.00'), findsOneWidget);
    expect(find.text('Iced latte'), findsOneWidget);

    await tester.tap(find.text('Mark as settled'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mark this debt as paid?'), findsOneWidget);

    await tester.tap(find.text('Mark as paid'));
    await tester.pumpAndSettle();

    expect(find.text('Everyone is settled up'), findsOneWidget);
    expect(groups.groups.single.settledDebtIds, [
      'latte:${group.members[0].id}:${group.members[1].id}',
    ]);
  });
}
