/// "[from] owes [to] [amount] PHP" for one expense.
///
/// Debts are never saved. BalanceProvider calculates them from a group's
/// expenses, and sets [isSettled] by checking Group.settledDebtIds, so the
/// settled status is only stored in one place.
class Debt {
  const Debt({
    required this.from,
    required this.to,
    required this.amount,
    required this.expenseId,
    this.isSettled = false,
  });

  /// Member id of the person who owes. Ids are used instead of names
  /// because two members could have the same name.
  final String from;

  /// Member id of the person who paid and is owed.
  final String to;

  /// Amount owed, in PHP.
  final double amount;
  final String expenseId;
  final bool isSettled;

  /// Identifies this debt, so it stays settled after balances are
  /// recalculated. One expense has at most one debt per debtor.
  String get id => '$expenseId:$from:$to';
}
