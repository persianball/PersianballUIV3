// core/fade_page_transitions.dart
import 'package:flutter/material.dart';

/// ترنزیشن ورود/خروج یکدست برای همه‌ی صفحات اپ: محو (fade) همراه با
/// سر خوردن ملایم از بالا. چون `MaterialPageRoute` (که همه‌جای اپ چه در
/// app_router.dart و چه در push‌های مستقیم استفاده می‌شود) وقتی خودش
/// ترنزیشن سفارشی ندارد به `Theme.pageTransitionsTheme` رجوع می‌کند، با
/// ست‌کردن این builder برای همه‌ی پلتفرم‌ها در main.dart، بدون دست‌زدن به
/// تک‌تک صفحه‌ها روی کل اپ اعمال می‌شود.
class FadeThroughTopPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeThroughTopPageTransitionsBuilder();

  /// پیش‌فرضِ متریال ۳۰۰ms است. هر دو صفحه در طولِ ترنزیشن با شفافیت کشیده
  /// می‌شوند (گران‌ترین نوعِ فریم)، پس کوتاه‌تر هم سریع‌تر حس می‌شود و هم
  /// فریم‌های سنگینِ کمتری دارد.
  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 170);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // صفحه‌ی وارد‌شونده: محو به‌همراه سر خوردن ملایم از بالا به جای اصلی.
    final incomingCurve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    // صفحه‌ی قبلی (وقتی این صفحه روی آن باز می‌شود یا این صفحه بسته
    // می‌شود): فقط محو می‌شود، بدون جابه‌جایی، تا تداخل بصری نداشته باشد.
    final outgoingCurve = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeIn,
      reverseCurve: Curves.easeOut,
    );

    return FadeTransition(
      opacity: outgoingCurve.drive(Tween<double>(begin: 1, end: 0)),
      child: FadeTransition(
        opacity: incomingCurve,
        child: SlideTransition(
          position: incomingCurve.drive(
            Tween<Offset>(begin: const Offset(0, -0.04), end: Offset.zero),
          ),
          child: child,
        ),
      ),
    );
  }
}
