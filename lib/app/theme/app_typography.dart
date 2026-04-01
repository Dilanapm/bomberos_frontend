import 'package:flutter/material.dart';

class AppTypography {
  static const fontFamily = 'Inter';

  // Tailwind sizes equivalentes:
  // xs 12, sm 14, base 16, lg 18, xl 20, 2xl 24, 3xl 30, 4xl 36, 5xl 48
  static TextTheme textTheme(Color textColor) => TextTheme(
        bodySmall:  TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
        bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, color: textColor),
        bodyLarge:  TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w400, color: textColor),

        labelSmall:  TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
        labelMedium: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
        labelLarge:  TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, color: textColor),

        titleSmall:  TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
        titleMedium: TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w700, color: textColor),
        titleLarge:  TextStyle(fontFamily: fontFamily, fontSize: 26, fontWeight: FontWeight.w700, color: textColor),

        headlineSmall:  TextStyle(fontFamily: fontFamily, fontSize: 36, fontWeight: FontWeight.w800, color: textColor),
        headlineMedium: TextStyle(fontFamily: fontFamily, fontSize: 48, fontWeight: FontWeight.w800, color: textColor),
      );
}
