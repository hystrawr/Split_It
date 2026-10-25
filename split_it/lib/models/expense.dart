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
  final double amount;
  final String currency;

  final double rate;
  final double amountPhp;
  final String paidBy;
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