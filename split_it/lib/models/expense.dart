/// One expense inside a group. Balances are calculated from [amountPhp].
class Expense {
  const Expense({
    required this.id,
    required this.groupId,
    required this.where,
    required this.item,
    required this.category,
    required this.amount,
    required this.currency,
    required this.rate,
    required this.amountPhp,
    required this.paidBy,
    required this.splitWith,
    required this.date,
  });

  final String id;
  final String groupId;
  final String where;
  final String item;
  final String category;

  /// Amount in [currency], as the user typed it.
  final double amount;

  /// ISO code of [amount], e.g. "USD".
  final String currency;

  /// Frankfurter rate with base PHP: 1 PHP = [rate] [currency].
  /// Saved with the expense so old expenses don't change when rates do.
  /// For PHP expenses the rate is 1.
  final double rate;

  /// [amount] converted to PHP (amount / rate). Balances use this value.
  final double amountPhp;

  /// Member id of the person who paid.
  final String paidBy;

  /// Member ids of everyone who shares this expense, including the payer
  /// if they share it too.
  final List<String> splitWith;
  final DateTime date;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      where: json['where'] as String,
      item: json['item'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      rate: (json['rate'] as num).toDouble(),
      amountPhp: (json['amountPhp'] as num).toDouble(),
      paidBy: json['paidBy'] as String,
      splitWith: List<String>.from(json['splitWith'] as List<dynamic>),
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'where': where,
      'item': item,
      'category': category,
      'amount': amount,
      'currency': currency,
      'rate': rate,
      'amountPhp': amountPhp,
      'paidBy': paidBy,
      'splitWith': splitWith,
      'date': date.toIso8601String(),
    };
  }
}
