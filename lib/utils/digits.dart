// lib/utils/digits.dart
import 'package:flutter/services.dart';

/// رقم‌های فارسی (۰-۹) و عربی (٠-٩) را به رقمِ لاتین برمی‌گرداند.
///
/// صفحه‌کلیدِ فارسیِ گوشی رقمِ فارسی تایپ می‌کند، ولی کدِ تخفیف در سرور با
/// رقمِ لاتین ذخیره شده؛ «OFF۲۰» و «OFF20» برای سرور دو کدِ متفاوت‌اند و کدِ
/// درست رد می‌شد.
String toEnglishDigits(String input) {
  final out = StringBuffer();
  for (final rune in input.runes) {
    if (rune >= 0x06F0 && rune <= 0x06F9) {
      out.writeCharCode(rune - 0x06F0 + 0x30);
    } else if (rune >= 0x0660 && rune <= 0x0669) {
      out.writeCharCode(rune - 0x0660 + 0x30);
    } else {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}

/// کدی که کاربر تایپ یا پیست کرده، آماده‌ی فرستادن به سرور: رقمِ لاتین، بدونِ
/// فاصله و نویسه‌های نامرئی (نیم‌فاصله، نشانه‌های جهت) که با کپی از پیام‌رسان
/// می‌آیند. بزرگی و کوچکیِ حروف دست نمی‌خورد.
String normalizeCode(String input) => toEnglishDigits(input)
    .replaceAll(RegExp(r'[\s​-‏‪-‮⁦-⁩﻿]'), '');

/// همان تبدیلِ رقم هنگامِ تایپ، تا کاربر همان چیزی را ببیند که فرستاده می‌شود.
class EnglishDigitsFormatter extends TextInputFormatter {
  const EnglishDigitsFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = toEnglishDigits(newValue.text);
    // تبدیل یک‌به‌یک است، پس جای مکان‌نما و انتخاب عوض نمی‌شود.
    return text == newValue.text ? newValue : newValue.copyWith(text: text);
  }
}
