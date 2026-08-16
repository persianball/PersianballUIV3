import 'package:flutter/material.dart';

class AppColor {
  static const Color primary = Color(0xFF242476);
  static const Color primarySoft = Color(0xFFEAEAF2);
  static const Color secondary = Color(0xFF0A0E2F);
  static const Color accent = Color(0xFFFABA3E);
  static const Color border = Color(0xFFD3D3E4);

  // ==== Obsidian Gold Athletics (stitch_elite_football_hub) ====
  // فقط صفحاتی که بازطراحی شده‌اند از این توکن‌ها استفاده می‌کنند؛
  // توکن‌های بالا برای صفحات هنوز بازطراحی‌نشده دست‌نخورده می‌مانند.
  static const Color obsidianBg = Color(0xFF0A0A0A);
  static const Color goldStart = Color(0xFFEAC249);
  static const Color goldEnd = Color(0xFFD4AF37);
  static const Color onGold = Color(0xFF241A00);
  static const Color surfaceContainer = Color(0x0DFFFFFF); // white @ 5%
  static const Color surfaceContainerHigh = Color(0x1AFFFFFF); // white @ 10%
  static const Color onSurface = Color(0xFFE2E2E2);
  static const Color onSurfaceVariant = Color(0xFFB8B2A6);
  static const Color outlineDark = Color(0xFF99907C);
  static const Color outlineVariantDark = Color(0xFF4D4635);
  static const Color successDark = Color(0xFF4ADE80);
  static const Color errorDark = Color(0xFFFFB4AB);

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [goldStart, goldEnd],
  );
}
