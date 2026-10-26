import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Yellow outlined button with an offset shadow. The button slides into
/// its shadow while pressed, so it needs a little state.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.amber,
    this.expand = false,
  });

  final String label;

  /// Pass null to disable the button.
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  /// Stretch to the full available width.
  final bool expand;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  static const double _shadowOffset = 4;

  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (_enabled && _pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offset = _pressed ? _shadowOffset : 0.0;

    final label = Text(
      widget.label,
      style: Theme.of(context).textTheme.labelLarge,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        if (widget.icon != null) Icon(widget.icon, size: 20),
        // An expanded button has a fixed width, so the label shrinks to
        // "Add Exp…" on narrow screens instead of overflowing. A hugging
        // button can sit in a Row with no width limit, where Flexible
        // would throw.
        if (widget.expand) Flexible(child: label) else label,
      ],
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          transform: Matrix4.translationValues(offset, offset, 0),
          // Less side padding when expanded: the content is centered
          // anyway, and it leaves room for the full label on a 360px phone.
          padding: EdgeInsets.symmetric(
            horizontal: widget.expand ? 12 : 20,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: _enabled ? widget.color : AppColors.settled,
            borderRadius: AppTheme.borderRadius,
            border: const Border.fromBorderSide(AppTheme.outlineSide),
            boxShadow: _pressed || !_enabled ? null : AppTheme.offsetShadow,
          ),
          child: IconTheme(
            data: const IconThemeData(color: AppColors.textPrimary),
            child: content,
          ),
        ),
      ),
    );
  }
}
