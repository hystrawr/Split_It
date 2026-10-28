import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:split_it/models/expense.dart';
import 'package:split_it/models/group.dart';
import 'package:split_it/models/member.dart';
import 'package:split_it/providers/balance_provider.dart';
import 'package:split_it/providers/group_provider.dart';

const _you = Member(id: 'you', name: 'You', isOwner: true);
const _trisha = Member(id: 'trisha', name: 'Trisha');
const _kelly = Member(id: 'kelly', name: 'Kelly');

Expense _expense(
  String id,
  double amountPhp, {
  required String paidBy,
  required List<String> splitWith,
}) {
  return Expense(
    id: id,
    groupId: 'g1',
    where: 'Panda Coffee',
    item: id,
    category: 'Food',
    amount: amountPhp,
    currency: 'PHP',
    rate: 1,
    amountPhp: amountPhp,
    paidBy: paidBy,
    splitWith: splitWith,
    date: DateTime(2026, 10, 27),
  );
}

Group _group(List<Expense> expenses, {List<String> settled = const []}) {
  return Group(
    id: 'g1',
    name: 'Cafe Barkads',
    defaultCurrency: 'PHP',
    createdAt: DateTime(2026, 10, 27),
    members: const [_you, _trisha, _kelly],
    expenses: expenses,
    settledDebtIds: settled,
  );
}

void main() {
  final balances = BalanceProvider();

  // Trisha pays ₱300 for iced lattes shared by all three.
  final latte = _expense(
    'latte',
    300,
    paidBy: 'trisha',
    splitWith: ['you', 'trisha', 'kelly'],
  );

  test('an expense is split equally and the payer owes nothing', () {
    final debts = balances.debtsFor(_group([latte]));

    expect(debts.length, 2);
    expect(debts.every((debt) => debt.to == 'trisha'), isTrue);
    expect(debts.every((debt) => debt.amount == 100), isTrue);
  });

  test('net balances add up to zero', () {
    final net = balances.netBalances(_group([latte]));

    expect(net['trisha'], 200);
    expect(net['you'], -100);
    expect(net['kelly'], -100);
    expect(net.values.fold(0.0, (sum, value) => sum + value), 0);
  });

  test('debts in both directions cancel out in the net balance', () {
    // You pay ₱150 for fries shared with Trisha, so Trisha owes you ₱75.
    final fries = _expense(
      'fries',
      150,
      paidBy: 'you',
      splitWith: ['you', 'trisha'],
    );

    final group = _group([latte, fries]);

    expect(balances.netBalances(group)['you'], closeTo(-25, 0.001));
    expect(balances.ownerBalance(group), closeTo(-25, 0.001));
  });

  test('what you owe does not lower what you are owed', () {
    // You pay ₱150 for fries shared with Trisha, so Trisha owes you ₱75,
    // while you still owe Trisha ₱100 for the latte.
    final fries = _expense(
      'fries',
      150,
      paidBy: 'you',
      splitWith: ['you', 'trisha'],
    );

    final group = _group([latte, fries]);

    expect(balances.ownerOwed(group), 75);
    expect(balances.ownerOwes(group), 100);

    final settled = _group([latte, fries], settled: ['fries:trisha:you']);
    expect(balances.ownerOwed(settled), 0);
    expect(balances.ownerOwes(settled), 100);
  });

  test('a settled debt no longer counts', () {
    final group = _group([latte], settled: ['latte:you:trisha']);

    final debts = balances.debtsFor(group);
    final net = balances.netBalances(group);

    expect(debts.firstWhere((debt) => debt.from == 'you').isSettled, isTrue);
    expect(net['you'], 0);
    expect(net['kelly'], -100);
    expect(net['trisha'], 100);
  });

  test('uneven amounts leave no tiny leftovers', () {
    // ₱100 split three ways is 33.333... each.
    final snack = _expense(
      'snack',
      100,
      paidBy: 'kelly',
      splitWith: ['you', 'trisha', 'kelly'],
    );

    final net = balances.netBalances(_group([snack]));

    expect(net['kelly'], closeTo(66.67, 0.01));
    expect(net['you'], closeTo(-33.33, 0.01));
  });

  test('totalSpent and paidBy add up the expenses', () {
    final group = _group([
      latte,
      _expense('grab', 120, paidBy: 'kelly', splitWith: ['you', 'kelly']),
    ]);

    expect(balances.totalSpent(group), 420);
    expect(balances.paidBy(group, 'kelly'), 120);
  });

  test('markSettled saves the debt through GroupProvider', () async {
    SharedPreferences.setMockInitialValues({});
    final groups = GroupProvider();
    final provider = BalanceProvider()..updateGroups(groups);

    await groups.addGroup(
      name: 'Cafe Barkads',
      defaultCurrency: 'PHP',
      memberNames: ['You', 'Trisha'],
    );
    final group = groups.groups.single;
    final you = group.members[0].id;
    final trisha = group.members[1].id;
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
        paidBy: trisha,
        splitWith: [you, trisha],
        date: DateTime(2026, 10, 27),
      ),
    );
    expect(provider.totalOwe, 100);

    final debt = provider.debtsFor(groups.groups.single).single;
    await provider.markSettled(group.id, debt);

    expect(provider.totalOwe, 0);
    expect(groups.groups.single.settledDebtIds, [debt.id]);
  });
}
