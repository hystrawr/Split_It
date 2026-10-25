import 'expense.dart';
import 'member.dart';

/// A group of members who share expenses, e.g. "Cafe Barkads".
class Group {
  const Group({
    required this.id,
    required this.name,
    required this.defaultCurrency,
    required this.members,
    required this.createdAt,
    this.expenses = const [],
    this.settledDebtIds = const [],
  });

  final String id;
  final String name;
  final String defaultCurrency;
  final List<Member> members;
  final DateTime createdAt;
  final List<Expense> expenses;

  /// Ids of debts that were marked as settled (see Debt.id). Unsettled debts
  /// are not saved; BalanceProvider calculates them from [expenses].
  final List<String> settledDebtIds;

  /// Returns a copy with some fields changed. Used by GroupProvider, since the
  /// fields are final. [id] and [createdAt] never change.
  Group copyWith({
    String? name,
    String? defaultCurrency,
    List<Member>? members,
    List<Expense>? expenses,
    List<String>? settledDebtIds,
  }) {
    return Group(
      id: id,
      name: name ?? this.name,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      members: members ?? this.members,
      createdAt: createdAt,
      expenses: expenses ?? this.expenses,
      settledDebtIds: settledDebtIds ?? this.settledDebtIds,
    );
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      defaultCurrency: json['defaultCurrency'] as String,
      members: (json['members'] as List<dynamic>)
          .map((m) => Member.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expenses: (json['expenses'] as List<dynamic>? ?? [])
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList(),
      settledDebtIds: List<String>.from(
        json['settledDebtIds'] as List<dynamic>? ?? [],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'defaultCurrency': defaultCurrency,
    'members': members.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'expenses': expenses.map((e) => e.toJson()).toList(),
    'settledDebtIds': settledDebtIds,
  };
}
