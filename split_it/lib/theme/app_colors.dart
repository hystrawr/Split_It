import 'package:flutter/material.dart';

/// Color palette for Split It (cream + sage + amber, soft neo-brutalist).
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color cream = Color(0xFFFFF8E7);
  static const Color surface = Color(0xFFFFFFFF);

  /// Secondary buttons, e.g. Delete on Expense Detail.
  static const Color beige = Color(0xFFF1E4C8);

  // Greens (summary cards, banners)
  static const Color sage = Color(0xFFB7CBA8);
  static const Color darkGreen = Color(0xFF2F4F3A);

  // Primary action (buttons)
  static const Color amber = Color(0xFFFFC94A);
  static const Color amberDark = Color(0xFFE0A800);

  // Outlines, shadows and text
  static const Color outline = Color(0xFF111111);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF5C5C5C);

  // Status pills
  static const Color owed = Color(0xFFCDE8C4); // you are owed
  static const Color owes = Color(0xFFF8C8C0); // you owe
  static const Color paid = Color(0xFFFFE7A3); // a debt marked as paid
  static const Color settled = Color(0xFFE4E4E4);

  static const Color error = Color(0xFFC62828);
}
