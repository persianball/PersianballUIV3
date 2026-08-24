import 'package:flutter/material.dart';

/// پالت رنگ اپ — «چمن و شیر» (Soccer Green / Milky White)
///
/// پس‌زمینه‌ی شیری روشن، کارت‌های سفید برجسته با سایه‌ی نرم سبزفام، و
/// سبز چمن فوتبال به‌عنوان رنگ اصلی/اکشن.
///
/// نام‌های قدیمی تم تیره‌ی طلایی (obsidianBg / goldEnd / onGold / …) عمداً
/// حذف نشده‌اند: ده‌ها فایل از آن‌ها استفاده می‌کنند و به‌عنوان alias به
/// توکن‌های جدید اشاره می‌کنند، پس تغییر پالت با همین یک فایل روی کل اپ
/// اعمال می‌شود. کد جدید باید از نام‌های معنایی جدید استفاده کند.
class AppColor {
  // ==== پالت پایه ====

  /// پس‌زمینه‌ی شیری کل اپ
  static const Color milk = Color(0xFFF4F7F3);

  /// سطح کارت/دیالوگ (سفید خالص تا برجستگی سایه دیده شود)
  static const Color card = Color(0xFFFFFFFF);

  /// سطح کمی تیره‌تر برای فیلد ورودی، چیپ خاموش، ردیف‌های تودرتو
  static const Color cardMuted = Color(0xFFEDF2EC);

  /// سبز چمن فوتبال — رنگ اصلی اکشن‌ها
  static const Color pitchGreen = Color(0xFF1B7A3E);

  /// سبز تیره‌تر (انتهای گرادیان، حالت فشرده‌ی دکمه)
  static const Color pitchGreenDark = Color(0xFF13612F);

  /// سبز روشن‌تر (هایلایت، شروع گرادیان)
  static const Color pitchGreenLight = Color(0xFF2FA45C);

  /// سبز بسیار کم‌رنگ برای پس‌زمینه‌ی بج/چیپ انتخاب‌شده
  static const Color pitchGreenSoft = Color(0xFFE3F2E8);

  /// متن روی سطح سبز
  static const Color onPitchGreen = Color(0xFFFFFFFF);

  /// متن اصلی (مشکی با ته‌رنگ سبز، نه مشکی خالص)
  static const Color ink = Color(0xFF14261B);

  /// متن ثانویه/توضیحی
  static const Color inkMuted = Color(0xFF5D6E63);

  /// خط جداکننده و بوردر ملایم
  static const Color line = Color(0xFFE2EAE3);

  /// بوردر پررنگ‌تر (فیلد فوکوس‌نشده، آیکن غیرفعال)
  static const Color lineStrong = Color(0xFF9FAFA4);

  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);

  /// گرادیان دکمه‌ی اصلی
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [pitchGreenLight, pitchGreen],
  );

  // ==== سایه‌ها (برجستگی) ====

  /// سایه‌ی کارت معمولی — برجستگی ملایم روی پس‌زمینه‌ی شیری
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0F14261B),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// سایه‌ی عناصر شناور (نوار پایین، دکمه‌ی اصلی، باتم‌شیت)
  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color(0x1F14261B),
      blurRadius: 26,
      offset: Offset(0, 10),
    ),
  ];

  /// سایه‌ی سبزفام برای دکمه‌های سبز (تا برجستگی رنگی دیده شود)
  static const List<BoxShadow> greenShadow = [
    BoxShadow(
      color: Color(0x401B7A3E),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  // ==== نام‌های قدیمی (alias) ====
  // این‌ها فقط برای اینکه صفحاتی که هنوز با نام‌های تم قبلی نوشته شده‌اند
  // بدون تغییر، رنگ درست بگیرند. در کد جدید استفاده نشود.

  static const Color primary = pitchGreen;
  static const Color primarySoft = pitchGreenSoft;
  static const Color secondary = pitchGreenDark;
  static const Color accent = pitchGreenLight;
  static const Color border = line;

  static const Color obsidianBg = milk;
  static const Color goldStart = pitchGreenLight;
  static const Color goldEnd = pitchGreen;
  static const Color onGold = onPitchGreen;
  static const Color surfaceContainer = card;
  static const Color surfaceContainerHigh = cardMuted;
  static const Color surfaceContainerOpaque = card;
  static const Color onSurface = ink;
  static const Color onSurfaceVariant = inkMuted;
  static const Color outlineDark = lineStrong;
  static const Color outlineVariantDark = line;
  static const Color successDark = success;
  static const Color errorDark = danger;

  static const LinearGradient goldGradient = greenGradient;
}
