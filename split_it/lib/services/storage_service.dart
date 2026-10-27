import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/group.dart';

class StorageService {
  static const String _groupsKey = 'groups';
  static const String _userNameKey = 'userName';

  Future<List<Group>> loadGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_groupsKey);
    if (raw == null) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((g) => Group.fromJson(g as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> saveGroups(List<Group> groups) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(groups.map((g) => g.toJson()).toList());
    await prefs.setString(_groupsKey, raw);
  }

  Future<String?> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }
}
