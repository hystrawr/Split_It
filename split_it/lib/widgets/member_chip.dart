import 'package:flutter/material.dart';

import 'avatar_circle.dart';

/// Pill for a member name.
///
/// - Pass [onRemove] for the Add Group form (shows an ×).
/// - Pass [onSelected] for the "Divided with" toggles on Add Expense.
/// - Pass neither for a plain label (Members tab, split breakdown).
class MemberChip extends StatelessWidget {
  const MemberChip({
    super.key,
    required this.name,
    this.subtitle,
    this.onRemove,
    this.selected = false,
    this.onSelected,
  });

  final String name;

  /// Extra text after the name, e.g. "paid ₱300".
  final String? subtitle;
  final VoidCallback? onRemove;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    final label = Text(subtitle == null ? name : '$name · $subtitle');
    final avatar = AvatarCircle(name: name, size: 24);

    if (onSelected != null) {
      return FilterChip(
        avatar: avatar,
        label: label,
        selected: selected,
        onSelected: onSelected,
      );
    }

    return Chip(
      avatar: avatar,
      label: label,
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close, size: 18),
    );
  }
}
