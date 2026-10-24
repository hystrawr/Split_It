import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Global theme. Shared border/shadow values live here so the reusable
/// widgets (cards, buttons, chips) all get the same outlined look.
class AppTheme {
  AppTheme._();

  static const double borderWidth = 2.0;
  static const double radius = 14.0;
  static const double chipRadius = 999.0;

  static const BorderSide outlineSide = BorderSide(
    color: AppColors.outline,
    width: borderWidth,
  );

  static final BorderRadius borderRadius = BorderRadius.circular(radius);

  /// Hard offset shadow used by cards and buttons.
  static const List<BoxShadow> offsetShadow = [
    BoxShadow(color: AppColors.outline, offset: Offset(4, 4)),
  ];

  /// Ready-made decoration for outlined cards.
  static BoxDecoration cardDecoration({Color color = AppColors.surface}) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius,
      border: Border.fromBorderSide(outlineSide),
      boxShadow: offsetShadow,
    );
  }

  static final RoundedRectangleBorder _outlinedShape = RoundedRectangleBorder(
    borderRadius: borderRadius,
    side: outlineSide,
  );

  static final OutlineInputBorder _inputBorder = OutlineInputBorder(
    borderRadius: borderRadius,
    borderSide: outlineSide,
  );

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.amber,
      onPrimary: AppColors.textPrimary,
      secondary: AppColors.darkGreen,
      onSecondary: Colors.white,
      tertiary: AppColors.sage,
      onTertiary: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      outline: AppColors.outline,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);

    final textTheme = base.textTheme
        .apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        )
        .copyWith(
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: _outlinedShape,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: AppColors.settled,
          elevation: 0,
          shape: _outlinedShape,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          side: outlineSide,
          shape: _outlinedShape,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkGreen,
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.amber,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        shape: _outlinedShape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: _inputBorder,
        enabledBorder: _inputBorder,
        focusedBorder: _inputBorder.copyWith(
          borderSide: outlineSide.copyWith(color: AppColors.darkGreen),
        ),
        errorBorder: _inputBorder.copyWith(
          borderSide: outlineSide.copyWith(color: AppColors.error),
        ),
        focusedErrorBorder: _inputBorder.copyWith(
          borderSide: outlineSide.copyWith(color: AppColors.error),
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.sage,
        labelStyle: textTheme.labelLarge,
        side: outlineSide,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(chipRadius),
        ),
        showCheckmark: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cream,
        shape: _outlinedShape,
        titleTextStyle: textTheme.titleLarge,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.darkGreen,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.darkGreen,
      ),
    );
  }
}
