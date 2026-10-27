import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:split_it/models/expense.dart';
import 'package:split_it/providers/group_provider.dart';

/// An expense for [groupId] paid by [paidBy] and split with [splitWith].
Expense _expense({
  required String id,
  required String groupId,
  required String paidBy,
  required List<String> splitWith,
  double amount = 300,
}) {
  return Expense(
    id: id,
    groupId: groupId,
    where: 'Panda Coffee',
    item: 'Iced latte',
    category: 'Food',
    amount: amount,
    currency: 'PHP',
    rate: 1,
    amountPhp: amount,
    paidBy: paidBy,
    splitWith: splitWith,
    date: DateTime(2026, 10, 27),
  );
}

void main() {
  // Every test starts with empty fake storage.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('addGroup makes the first member the owner', () async {
    final provider = GroupProvider();

    await provider.addGroup(
      name: 'Cafe Barkads',
      defaultCurrency: 'PHP',
      memberNames: ['Trisha', 'Barby', 'Kelly'],
    );

    final group = provider.groups.single;
    expect(group.name, 'Cafe Barkads');
    expect(group.members.length, 3);
    expect(group.members[0].isOwner, isTrue);
    expect(group.members[1].isOwner, isFalse);
    // Every member needs its own id.
    expect(group.members.map((m) => m.id).toSet().length, 3);
  });

  test('search filters groups by name, ignoring case', () async {
    final provider = GroupProvider();
    await provider.addGroup(
      name: 'Cafe Barkads',
      defaultCurrency: 'PHP',
      memberNames: ['Trisha', 'Barby'],
    );
    await provider.addGroup(
      name: 'Boardmates',
      defaultCurrency: 'PHP',
      memberNames: ['Trisha', 'Kelly'],
    );

    provider.search('cafe');
    expect(provider.filteredGroups.map((g) => g.name), ['Cafe Barkads']);

    provider.search('');
    expect(provider.filteredGroups.length, 2);
  });

  test('groups are saved and loaded again after a restart', () async {
    final first = GroupProvider();
    await first.addGroup(
      name: 'Bcd trip',
      defaultCurrency: 'PHP',
      memberNames: ['Trisha', 'Barby'],
    );

    // A new provider is like opening the app again.
    final second = GroupProvider();
    await second.loadGroups();

    expect(second.groups.single.name, 'Bcd trip');
  });

  test('expenses can be added, edited and deleted', () async {
    final provider = GroupProvider();
    await provider.addGroup(
      name: 'Cafe Barkads',
      defaultCurrency: 'PHP',
      memberNames: ['Trisha', 'Barby'],
    );
    final group = provider.groups.single;
    final trisha = group.members[0].id;
    final barby = group.members[1].id;

    await provider.addExpense(
      _expense(
        id: 'e1',
        groupId: group.id,
        paidBy: trisha,
        splitWith: [trisha, barby],
      ),
    );
    expect(provider.groupById(group.id)!.expenses.length, 1);

    await provider.updateExpense(
      _expense(
        id: 'e1',
        groupId: group.id,
        paidBy: trisha,
        splitWith: [trisha, barby],
        amount: 450,
      ),
    );
    expect(provider.expenseById('e1')!.amount, 450);

    await provider.deleteExpense(group.id, 'e1');
    expect(provider.expenseById('e1'), isNull);
  });

  test('deleteGroup removes the group', () async {
    final provider = GroupProvider();
    await provider.addGroup(
      name: 'Cafe Barkads',
      defaultCurrency: 'PHP',
      memberNames: ['Trisha', 'Barby'],
    );
    final id = provider.groups.single.id;

    await provider.deleteGroup(id);

    expect(provider.groups, isEmpty);
    expect(provider.groupById(id), isNull);
  });
}
