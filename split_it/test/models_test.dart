import 'package:flutter_test/flutter_test.dart';

import 'package:split_it/models/expense.dart';
import 'package:split_it/models/group.dart';
import 'package:split_it/models/member.dart';

void main() {
  test('Group survives a toJson / fromJson round trip', () {
    final group = Group(
      id: 'g1',
      name: 'Cafe Barkads',
      defaultCurrency: 'PHP',
      createdAt: DateTime(2026, 10, 25),
      members: const [
        Member(id: 'm1', name: 'Trisha', isOwner: true),
        Member(id: 'm2', name: 'Barby'),
      ],
      expenses: [
        Expense(
          id: 'e1',
          groupId: 'g1',
          where: 'Panda Coffee',
          item: 'Iced latte',
          category: 'Food',
          amount: 300,
          currency: 'PHP',
          rate: 1,
          amountPhp: 300,
          paidBy: 'm1',
          splitWith: const ['m1', 'm2'],
          date: DateTime(2026, 10, 25),
        ),
      ],
      settledDebtIds: const ['e1:m2:m1'],
    );

    final copy = Group.fromJson(group.toJson());

    expect(copy.name, 'Cafe Barkads');
    expect(copy.members.length, 2);
    expect(copy.members.first.isOwner, isTrue);
    expect(copy.expenses.first.amountPhp, 300.0);
    expect(copy.expenses.first.splitWith, ['m1', 'm2']);
    expect(copy.settledDebtIds, ['e1:m2:m1']);
  });
}
