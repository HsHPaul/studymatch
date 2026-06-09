import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
        primary: AppColors.primary,
        primaryLight: AppColors.primaryLight,
        bg: AppColors.background,
        card: AppColors.cardWhite,
        navy: AppColors.navy,
        muted: AppColors.muted,
        brightness: Brightness.light,
        inputFill: AppColors.cardWhite,
        navIndicator: AppColors.primaryLight,
        divider: const Color(0xFFEEEBF8),
        outline: const Color(0xFFD0CDED),
        surfaceVariant: const Color(0xFFEEEBF8),
      );

  static ThemeData get dark {
    const primary = Color(0xFFF9AB0B);
    const primaryLight = Color(0xFF2D2100);
    const bg = Color(0xFF000000);
    const card = Color(0xFF1C1C1E);
    const navy = Color(0xFFFFFFFF);
    const muted = Color(0xFF636366);
    return _build(
      primary: primary,
      primaryLight: primaryLight,
      bg: bg,
      card: card,
      navy: navy,
      muted: muted,
      brightness: Brightness.dark,
      inputFill: const Color(0xFF2C2C2E),
      navIndicator: primaryLight,
      divider: const Color(0xFF2C2C2E),
      outline: const Color(0xFF3A3A3C),
      surfaceVariant: const Color(0xFF2C2C2E),
    );
  }

  static ThemeData _build({
    required Color primary,
    required Color primaryLight,
    required Color bg,
    required Color card,
    required Color navy,
    required Color muted,
    required Brightness brightness,
    required Color inputFill,
    required Color navIndicator,
    required Color divider,
    required Color outline,
    required Color surfaceVariant,
  }) {
    final base = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryLight,
      onPrimaryContainer: primary,
      secondary: navy,
      surface: card,
      surfaceContainerLowest: bg,
      surfaceContainerHighest: surfaceVariant,
      onSurface: navy,
      onSurfaceVariant: muted,
      error: AppColors.error,
      outline: outline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: bg,

      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: navy,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: navy),
      ),

      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
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
          backgroundColor: primary,
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
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: primary, width: 1.5),
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
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: TextStyle(color: muted, fontSize: 15),
        hintStyle: TextStyle(color: muted),
        prefixIconColor: muted,
        suffixIconColor: muted,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: primaryLight,
        labelStyle: TextStyle(
          color: primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        deleteIconColor: primary,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black12,
        indicatorColor: navIndicator,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 24);
          }
          return IconThemeData(color: muted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            );
          }
          return TextStyle(
            color: muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const StadiumBorder(),
      ),

      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
            color: navy, fontWeight: FontWeight.w800, fontSize: 36),
        displayMedium: TextStyle(
            color: navy, fontWeight: FontWeight.w700, fontSize: 30),
        headlineLarge: TextStyle(
            color: navy, fontWeight: FontWeight.w700, fontSize: 26),
        headlineMedium: TextStyle(
            color: navy, fontWeight: FontWeight.w700, fontSize: 22),
        headlineSmall: TextStyle(
            color: navy, fontWeight: FontWeight.w600, fontSize: 18),
        titleLarge: TextStyle(
            color: navy, fontWeight: FontWeight.w600, fontSize: 17),
        titleMedium: TextStyle(
            color: navy, fontWeight: FontWeight.w600, fontSize: 15),
        titleSmall: TextStyle(
            color: navy, fontWeight: FontWeight.w600, fontSize: 13),
        bodyLarge: TextStyle(
            color: navy, fontWeight: FontWeight.w400, fontSize: 16),
        bodyMedium: TextStyle(
            color: navy, fontWeight: FontWeight.w400, fontSize: 14),
        bodySmall: TextStyle(
            color: muted, fontWeight: FontWeight.w400, fontSize: 12),
        labelLarge: TextStyle(
            color: navy, fontWeight: FontWeight.w600, fontSize: 14),
        labelMedium: TextStyle(
            color: muted, fontWeight: FontWeight.w500, fontSize: 12),
        labelSmall: TextStyle(
            color: muted, fontWeight: FontWeight.w500, fontSize: 11),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: muted, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: navy,
        contentTextStyle:
            const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: TextStyle(
          color: navy,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
