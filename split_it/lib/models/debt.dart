class Debt {
  const Debt({
    required this.from,
    required this.to,
    required this.amount,
    required this.expenseId,
    this.isSettled = false,
  });

  final String from;
  final String to;
  final double amount;
  final String expenseId;
  final bool isSettled;

  String get id => '$expenseId:$from:$to';

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      from: json['from'] as String,
      to: json['to'] as String,
      amount: (json['amount'] as num).toDouble(),
      expenseId: json['expenseId'] as String,
      isSettled: json['isSettled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'amount': amount,
      'expenseId': expenseId,
      'isSettled': isSettled,
    };
  }
}