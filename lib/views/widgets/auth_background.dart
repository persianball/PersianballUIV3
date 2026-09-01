// lib/views/widgets/auth_background.dart
//
// پس‌زمینه‌ی تصویریِ صفحات.
//
// برای هر پس‌زمینه دو تصویر جدا داریم چون کادربندی‌شان فرق دارد: نسخه‌ی
// موبایل عمودی و نسخه‌ی دسکتاپ افقی است. کشیدنِ یکی روی دیگری هم کیفیت را
// خراب می‌کند و هم مرکزِ آرامِ تصویر را از وسط خارج می‌کند.
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_breakpoints.dart';
import 'package:marketky/constant/app_color.dart';

/// کدام پس‌زمینه: صفحات ورود، یا پوسته‌ی اصلی اپ.
enum AppBackdrop { auth, main }

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.backdrop = AppBackdrop.auth,
  });

  final Widget child;
  final AppBackdrop backdrop;

  static const _assets = {
    AppBackdrop.auth: (
      mobile: 'assets/images/Mobile_login_background.jpeg',
      desktop: 'assets/images/Desktop_login_background.jpeg',
    ),
    AppBackdrop.main: (
      mobile: 'assets/images/Mobile_main_background.jpeg',
      desktop: 'assets/images/Desktop_main_background.jpeg',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final bool desktop = AppBreakpoints.isDesktop(context);
    final paths = _assets[backdrop]!;

    return Stack(
      fit: StackFit.expand,
      children: [
        // رنگ پایه تا اگر تصویر هنوز نیامده صفحه سفیدِ خالی نباشد
        const ColoredBox(color: AppColor.milk),
        Image.asset(
          desktop ? paths.desktop : paths.mobile,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          // خطای بارگذاری نباید صفحه را از کار بیندازد
          errorBuilder: (_, __, ___) => const ColoredBox(color: AppColor.milk),
        ),
        // پرده‌ی بسیار ملایم شیری: تضمین می‌کند متن تیره و کارت‌ها روی هر
        // نقطه‌ی تصویر خوانا بمانند. پس‌زمینه‌ی اصلی چون محتوای زیادی رویش
        // اسکرول می‌شود پرده‌ی پررنگ‌تری می‌گیرد.
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColor.milk.withValues(
              alpha: backdrop == AppBackdrop.main ? 0.55 : (desktop ? 0.0 : 0.25),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// نام قبلی — برای سازگاری با فراخوانی‌های موجود صفحات ورود.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      AppBackground(backdrop: AppBackdrop.auth, child: child);
}
