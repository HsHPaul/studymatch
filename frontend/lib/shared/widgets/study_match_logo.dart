import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class StudyMatchLogo extends StatelessWidget {
  final double size;
  final bool showLabel;

  const StudyMatchLogo({super.key, this.size = 48, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/hsh_logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
        if (showLabel) ...[
          const SizedBox(height: 6),
          Text(
            'StudyMatch',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: size * 0.35,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}
