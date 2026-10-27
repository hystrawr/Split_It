import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:split_it/models/expense.dart';
import 'package:split_it/providers/balance_provider.dart';
import 'package:split_it/providers/group_provider.dart';
import 'package:split_it/providers/home_provider.dart';

/// Wires the three providers together the same way main.dart does.
({GroupProvider groups, HomeProvider home}) _providers() {
  final groups = GroupProvider();
  final balances = BalanceProvider()..updateGroups(groups);
  final home = HomeProvider()..update(groups, balances);
  groups.addListener(() {
    balances.updateGroups(groups);
    home.update(groups, balances);
  });
  return (groups: groups, home: home);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('groups show your balance and the totals add up', () async {
    final (:groups, :home) = _providers();
    await groups.addGroup(
      name: 'Cafe Barkads',
      defaultCurrency: 'PHP',
      memberNames: ['You', 'Trisha'],
    );
    final group = groups.groups.single;
    final you = group.members[0].id;
    final trisha = group.members[1].id;
    expect(home.groups.single.hasExpenses, isFalse);

    // You paid ₱300 for both of you, so Trisha owes you ₱150.
    await groups.addExpense(
      Expense(
        id: 'e1',
        groupId: group.id,
        where: 'Panda Coffee',
        item: 'Iced latte',
        category: 'Food',
        amount: 300,
        currency: 'PHP',
        rate: 1,
        amountPhp: 300,
        paidBy: you,
        splitWith: [you, trisha],
        date: DateTime(2026, 10, 27),
      ),
    );

    expect(home.groups.single.name, 'Cafe Barkads');
    expect(home.groups.single.memberCount, 2);
    expect(home.groups.single.hasExpenses, isTrue);
    expect(home.groups.single.balance, 150);
    expect(home.totalOwed, 150);
    expect(home.totalOwe, 0);
  });

  test(
    'search filters groups but hasNoGroups only checks all groups',
    () async {
      final (:groups, :home) = _providers();
      await groups.addGroup(
        name: 'Cafe Barkads',
        defaultCurrency: 'PHP',
        memberNames: ['You', 'Trisha'],
      );

      home.search('boardmates');

      expect(home.groups, isEmpty);
      expect(home.hasNoGroups, isFalse);
      expect(home.query, 'boardmates');
    },
  );

  test('the user name is saved and loaded again', () async {
    final first = HomeProvider();
    expect(first.userName, HomeProvider.defaultUserName);
    await first.setUserName('  Trisha ');

    final second = HomeProvider();
    await second.loadUserName();

    expect(second.userName, 'Trisha');
  });
}
