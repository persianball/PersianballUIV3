// lib/views/widgets/app_logo.dart
//
// لوگوی برند داخل اپ.
//
// از assets/icons/app_logo.png می‌خواند، نه pers_icon.png: آن فایل برای آیکنِ
// لانچر است (۱۲۵۴ پیکسل، ~۱ مگابایت، با مربعِ سفید پشتش). این یکی برش‌خورده،
// شفاف و ۵۱۲ پیکسلی است، پس روی پس‌زمینه‌ی شیری قابِ سفید نمی‌اندازد.
//
// روی سبزِ برند نگذارید: نوارِ سبزِ لوگو روی آن محو می‌شود.
import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40});

  final double size;

  static const String asset = 'assets/icons/app_logo.png';

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2;
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // فقط به اندازه‌ی نمایش دیکد شود، نه ۵۱۲ پیکسلِ کامل
      cacheWidth: (size * dpr).round(),
      filterQuality: FilterQuality.medium,
      semanticLabel: 'پرشین شاپ',
    );
  }
}
