import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Top bar with an outlined back button and a title. Drop it into
/// `Scaffold.appBar` on every screen except Home.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.actions,
  });

  final String title;

  /// Hide the back button, e.g. on Home.
  final bool showBack;

  /// Runs instead of popping, e.g. to confirm discarding a form.
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(title),
      titleSpacing: showBack && canPop ? 0 : NavigationToolbar.kMiddleSpacing,
      leading: showBack && canPop
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                tooltip: 'Back',
                onPressed: onBack ?? () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  side: AppTheme.outlineSide,
                ),
              ),
            )
          : null,
      actions: actions,
    );
  }
}
