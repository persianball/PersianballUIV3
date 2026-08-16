import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';

/// مقیاس تایپوگرافی طرح Obsidian Gold Athletics (stitch_elite_football_hub)،
/// با فونت Estedad به‌جای Vazirmatn طرح اصلی.
/// فقط توسط صفحاتی که بازطراحی شده‌اند استفاده می‌شود.
class AppTextStyles {
  static const String _font = 'Estedad';

  static const TextStyle displayLg = TextStyle(
    fontFamily: _font,
    fontSize: 42,
    fontWeight: FontWeight.w800,
    height: 52 / 42,
    letterSpacing: -0.02 * 42,
    color: AppColor.onSurface,
  );

  static const TextStyle headlineLg = TextStyle(
    fontFamily: _font,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    color: AppColor.onSurface,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: _font,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    color: AppColor.onSurface,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 28 / 18,
    color: AppColor.onSurface,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColor.onSurfaceVariant,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.05 * 12,
    color: AppColor.onSurfaceVariant,
  );
}
