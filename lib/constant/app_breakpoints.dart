// lib/constant/app_breakpoints.dart
//
// نقاط شکست واکنش‌گرا برای کل اپ (وب دسکتاپ + تبلت + موبایل).
// قانون: موبایل < 768 ≤ تبلت < 1024 ≤ دسکتاپ.
import 'package:flutter/widgets.dart';

class AppBreakpoints {
  AppBreakpoints._();

  static const double tablet = 768;
  static const double desktop = 1024;

  /// حداکثر عرض محتوای مرکزی در دسکتاپ (مثل max-w-7xl سایت‌های فروشگاهی)
  static const double contentMaxWidth = 1200;

  /// عرض ستون کناری (خلاصه‌ی سبد، فیلترها و…)
  static const double sidebarWidth = 360;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= tablet && w < desktop;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < tablet;

  /// حاشیه‌ی افقی صفحه بر اساس عرض (adaptive gutters)
  static double gutter(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= desktop) return 32;
    if (w >= tablet) return 24;
    return 16;
  }

  /// تعداد ستون گرید محصولات بر اساس عرض موجود
  static int gridColumns(double availableWidth) {
    if (availableWidth >= 1100) return 4;
    if (availableWidth >= 800) return 3;
    return 2;
  }
}

/// پوسته‌ی محتوای مرکزی: در دسکتاپ محتوا را به عرض استاندارد محدود و
/// وسط‌چین می‌کند؛ در موبایل بی‌اثر است (فقط پدینگ لبه).
class CenteredContent extends StatelessWidget {
  const CenteredContent({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.contentMaxWidth,
    this.withGutter = true,
  });

  final Widget child;
  final double maxWidth;
  final bool withGutter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: withGutter
            ? Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: AppBreakpoints.gutter(context)),
                child: child,
              )
            : child,
      ),
    );
  }
}
