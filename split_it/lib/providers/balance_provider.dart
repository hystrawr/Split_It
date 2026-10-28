import 'package:flutter/foundation.dart';

import '../models/debt.dart';
import '../models/expense.dart';
import '../models/group.dart';
import 'group_provider.dart';

class BalanceProvider extends ChangeNotifier {
  GroupProvider? _groups;
  void updateGroups(GroupProvider groups) {
    _groups = groups;
    notifyListeners();
  }

  double shareOf(Expense expense) {
    if (expense.splitWith.isEmpty) return 0;
    return expense.amountPhp / expense.splitWith.length;
  }

  List<Debt> debtsFor(Group group) {
    final debts = <Debt>[];
    for (final expense in group.expenses) {
      if (expense.splitWith.isEmpty) continue;
      final share = shareOf(expense);

      for (final memberId in expense.splitWith) {
        if (memberId == expense.paidBy) continue;
        final debt = Debt(
          from: memberId,
          to: expense.paidBy,
          amount: share,
          expenseId: expense.id,
        );
        debts.add(
          group.settledDebtIds.contains(debt.id) ? debt.asSettled() : debt,
        );
      }
    }
    return debts;
  }

  /// Each member's net balance in PHP, from the debts that aren't settled.
  /// Positive = the member is owed money, negative = they owe.
  Map<String, double> netBalances(Group group) {
    final balances = {for (final member in group.members) member.id: 0.0};
    for (final debt in debtsFor(group)) {
      if (debt.isSettled) continue;
      balances[debt.to] = (balances[debt.to] ?? 0) + debt.amount;
      balances[debt.from] = (balances[debt.from] ?? 0) - debt.amount;
    }
    // Splitting can leave tiny leftovers like 0.0000001; treat them as 0.
    return balances.map(
      (id, amount) => MapEntry(id, amount.abs() < 0.005 ? 0.0 : amount),
    );
  }

  /// The app user's (owner's) net balance in [group].
  double ownerBalance(Group group) {
    final owner = group.members.where((member) => member.isOwner);
    if (owner.isEmpty) return 0;
    return netBalances(group)[owner.first.id] ?? 0;
  }

  /// What others still owe the owner in [group]. Not reduced by what the
  /// owner owes them; only settling a debt lowers it.
  double ownerOwed(Group group) => _ownerDebtTotal(group, owedToOwner: true);

  /// What the owner still owes others in [group], as a positive number.
  /// Not reduced by what they owe the owner.
  double ownerOwes(Group group) => _ownerDebtTotal(group, owedToOwner: false);

  double _ownerDebtTotal(Group group, {required bool owedToOwner}) {
    final owner = group.members.where((member) => member.isOwner);
    if (owner.isEmpty) return 0;
    final ownerId = owner.first.id;
    final total = debtsFor(group)
        .where((debt) => !debt.isSettled)
        .where((debt) => (owedToOwner ? debt.to : debt.from) == ownerId)
        .fold(0.0, (sum, debt) => sum + debt.amount);
    return total < 0.005 ? 0 : total;
  }

  /// Total amount the member with [memberId] paid in [group], in PHP.
  double paidBy(Group group, String memberId) {
    return group.expenses
        .where((expense) => expense.paidBy == memberId)
        .fold(0.0, (sum, expense) => sum + expense.amountPhp);
  }

  /// Total of every expense in [group], in PHP.
  double totalSpent(Group group) {
    return group.expenses.fold(0.0, (sum, expense) => sum + expense.amountPhp);
  }

  /// What the owner is owed across all groups (Home banner).
  double get totalOwed =>
      _allGroups.fold(0.0, (sum, group) => sum + ownerOwed(group));

  /// What the owner owes across all groups (Home banner), as a positive
  /// number.
  double get totalOwe =>
      _allGroups.fold(0.0, (sum, group) => sum + ownerOwes(group));

  /// Marks a debt as paid. GroupProvider saves it, then notifies, which
  /// calls [updateGroups] and recalculates every balance.
  Future<void> markSettled(String groupId, Debt debt) async {
    await _groups?.settleDebt(groupId, debt.id);
  }

  List<Group> get _allGroups => _groups?.groups ?? const <Group>[];
}
