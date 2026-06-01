import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF6F35D4);
  static const primaryLight = Color(0xFFEDE7FF);
  static const navy = Color(0xFF0B1B3A);
  static const orange = Color(0xFFF0441A);
  static const background = Color(0xFFF8F8FB);
  static const cardWhite = Color(0xFFFFFFFF);
  static const muted = Color(0xFF8A8FAB);
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
