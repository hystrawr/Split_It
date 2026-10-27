import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../services/storage_service.dart';

/// Shared state for every group and its expenses.
/// Screens read groups from here and call its methods to change them;
/// every change is saved to the device and then shown on all screens.
class GroupProvider extends ChangeNotifier {
  GroupProvider({StorageService? storage})
    : _storage = storage ?? StorageService();

  final StorageService _storage;

  List<Group> _groups = [];
  bool _isLoading = false;
  String _query = '';

  /// All groups. Read-only, so screens can't change the list directly.
  List<Group> get groups => List.unmodifiable(_groups);
  bool get isLoading => _isLoading;
  String get query => _query;

  /// Groups whose name contains the search text (all groups if it's empty).
  List<Group> get filteredGroups {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return groups;
    return _groups
        .where((group) => group.name.toLowerCase().contains(query))
        .toList();
  }

  /// Loads the saved groups. Called once when the app starts.
  Future<void> loadGroups() async {
    _isLoading = true;
    notifyListeners();

    _groups = await _storage.loadGroups();

    _isLoading = false;
    notifyListeners();
  }

  /// Updates the search text from the Home search bar.
  void search(String query) {
    _query = query;
    notifyListeners();
  }

  /// The group with [id], or null if it was deleted.
  Group? groupById(String id) {
    for (final group in _groups) {
      if (group.id == id) return group;
    }
    return null;
  }

  /// The expense with [id] from any group, or null. Used by Expense Detail,
  /// which only receives the expense id.
  Expense? expenseById(String id) {
    for (final group in _groups) {
      for (final expense in group.expenses) {
        if (expense.id == id) return expense;
      }
    }
    return null;
  }

  /// Creates a group. The first name in [memberNames] is the owner ("You").
  Future<void> addGroup({
    required String name,
    required String defaultCurrency,
    required List<String> memberNames,
  }) async {
    final members = [
      for (var i = 0; i < memberNames.length; i++)
        Member(id: _newId(), name: memberNames[i], isOwner: i == 0),
    ];

    _groups.add(
      Group(
        id: _newId(),
        name: name,
        defaultCurrency: defaultCurrency,
        members: members,
        createdAt: DateTime.now(),
      ),
    );
    await _saveAndNotify();
  }

  /// Deletes the group with [id] and all its expenses.
  Future<void> deleteGroup(String id) async {
    _groups.removeWhere((group) => group.id == id);
    await _saveAndNotify();
  }

  /// Adds [expense] to the group with expense.groupId.
  Future<void> addExpense(Expense expense) async {
    await _replaceGroup(
      expense.groupId,
      (group) => group.copyWith(expenses: [...group.expenses, expense]),
    );
  }

  /// Replaces the expense that has the same id as [expense].
  Future<void> updateExpense(Expense expense) async {
    await _replaceGroup(
      expense.groupId,
      (group) => group.copyWith(
        expenses: group.expenses
            .map((e) => e.id == expense.id ? expense : e)
            .toList(),
      ),
    );
  }

  /// Deletes an expense and any settled debts that belonged to it.
  Future<void> deleteExpense(String groupId, String expenseId) async {
    await _replaceGroup(
      groupId,
      (group) => group.copyWith(
        expenses: group.expenses.where((e) => e.id != expenseId).toList(),
        // Debt ids start with the expense id (see Debt.id).
        settledDebtIds: group.settledDebtIds
            .where((debtId) => !debtId.startsWith('$expenseId:'))
            .toList(),
      ),
    );
  }

  /// Finds the group with [groupId], replaces it with [update]'s result,
  /// then saves. Group is immutable, so a change means a new copy.
  Future<void> _replaceGroup(
    String groupId,
    Group Function(Group group) update,
  ) async {
    final index = _groups.indexWhere((group) => group.id == groupId);
    if (index == -1) return;
    _groups[index] = update(_groups[index]);
    await _saveAndNotify();
  }

  /// Tells the screens to rebuild, then saves every group to the device.
  Future<void> _saveAndNotify() async {
    notifyListeners();
    await _storage.saveGroups(_groups);
  }

  int _idCounter = 0;

  /// A unique id: the current time plus a counter, because members created
  /// in the same loop can get the same timestamp.
  String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';
}
