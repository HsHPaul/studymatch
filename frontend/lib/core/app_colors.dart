import 'package:flutter/material.dart';

abstract final class AppColors {
  static bool _dark = false;
  static set dark(bool v) => _dark = v;

  static Color get primary =>
      _dark ? const Color(0xFFF9AB0B) : const Color(0xFF6F35D4);
  static Color get primaryLight =>
      _dark ? const Color(0xFF2D2100) : const Color(0xFFEDE7FF);
  static Color get navy =>
      _dark ? const Color(0xFFFFFFFF) : const Color(0xFF0B1B3A);
  static Color get background =>
      _dark ? const Color(0xFF000000) : const Color(0xFFF8F8FB);
  static Color get cardWhite =>
      _dark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
  static Color get muted =>
      _dark ? const Color(0xFF636366) : const Color(0xFF8A8FAB);

  // Unchanged in both modes
  static const orange = Color(0xFFF0441A);
  static const success = Color(0xFF27AE60);
  static const warning = Color(0xFFF39C12);
  static const error = Color(0xFFE74C3C);
}

abstract final class AppShadows {
  static const card = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const soft = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const nav = [
    BoxShadow(
      color: Color(0x18000000),
      blurRadius: 24,
      offset: Offset(0, -4),
    ),
  ];
}
