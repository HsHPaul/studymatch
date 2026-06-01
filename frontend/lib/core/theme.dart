import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.navy,
      surface: AppColors.cardWhite,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerHighest: const Color(0xFFEEEBF8),
      onSurface: AppColors.navy,
      onSurfaceVariant: AppColors.muted,
      error: AppColors.error,
      outline: const Color(0xFFD0CDED),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: AppColors.background,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.navy,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppColors.navy),
      ),

      // ── Cards ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Filled / Elevated Buttons ────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── InputDecoration ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD0CDED), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD0CDED), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.muted, fontSize: 15),
        hintStyle: const TextStyle(color: AppColors.muted),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
      ),

      // ── Chips ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryLight,
        labelStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        deleteIconColor: AppColors.primary,
      ),

      // ── NavigationBar ────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cardWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black12,
        indicatorColor: AppColors.primaryLight,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.muted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            );
          }
          return const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
      ),

      // ── FloatingActionButton ─────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: StadiumBorder(),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEEBF8),
        thickness: 1,
        space: 1,
      ),

      // ── Text ─────────────────────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            color: AppColors.navy, fontWeight: FontWeight.w800, fontSize: 36),
        displayMedium: TextStyle(
            color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 30),
        headlineLarge: TextStyle(
            color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 26),
        headlineMedium: TextStyle(
            color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 22),
        headlineSmall: TextStyle(
            color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 18),
        titleLarge: TextStyle(
            color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 17),
        titleMedium: TextStyle(
            color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 15),
        titleSmall: TextStyle(
            color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 13),
        bodyLarge: TextStyle(
            color: AppColors.navy, fontWeight: FontWeight.w400, fontSize: 16),
        bodyMedium: TextStyle(
            color: AppColors.navy, fontWeight: FontWeight.w400, fontSize: 14),
        bodySmall: TextStyle(
            color: AppColors.muted, fontWeight: FontWeight.w400, fontSize: 12),
        labelLarge: TextStyle(
            color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 14),
        labelMedium: TextStyle(
            color: AppColors.muted, fontWeight: FontWeight.w500, fontSize: 12),
        labelSmall: TextStyle(
            color: AppColors.muted, fontWeight: FontWeight.w500, fontSize: 11),
      ),

      // ── Checkbox ─────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.muted, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navy,
        contentTextStyle:
            const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          color: AppColors.navy,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      // ── BottomSheet ───────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
