import 'package:flutter/foundation.dart';

import '../models/group.dart';
import '../services/storage_service.dart';
import 'balance_provider.dart';
import 'group_provider.dart';

class GroupSummary {
  const GroupSummary({required this.group, required this.balance});

  final Group group;

  final double balance;

  String get id => group.id;
  String get name => group.name;
  int get memberCount => group.members.length;
  bool get hasExpenses => group.expenses.isNotEmpty;
}

class HomeProvider extends ChangeNotifier {
  HomeProvider({StorageService? storage})
    : _storage = storage ?? StorageService();

  static const String defaultUserName = 'Barby';

  final StorageService _storage;

  GroupProvider? _groups;
  BalanceProvider? _balances;
  String _userName = defaultUserName;

  void update(GroupProvider groups, BalanceProvider balances) {
    _groups = groups;
    _balances = balances;
    notifyListeners();
  }

  String get userName => _userName;

  bool get isLoading => _groups?.isLoading ?? true;
  String get query => _groups?.query ?? '';

  bool get hasNoGroups => _groups?.groups.isEmpty ?? true;

  List<GroupSummary> get groups {
    final balances = _balances;
    final groups = _groups?.filteredGroups ?? const <Group>[];
    return [
      for (final group in groups)
        GroupSummary(group: group, balance: balances?.ownerBalance(group) ?? 0),
    ];
  }

  double get totalOwed => _balances?.totalOwed ?? 0;

  double get totalOwe => _balances?.totalOwe ?? 0;

  Future<void> loadUserName() async {
    _userName = await _storage.loadUserName() ?? defaultUserName;
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _userName = trimmed;
    notifyListeners();
    await _storage.saveUserName(trimmed);
  }

  void search(String query) => _groups?.search(query);

  Future<void> deleteGroup(String id) async {
    await _groups?.deleteGroup(id);
  }
}
