// core/fade_page_transitions.dart
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// ترنزیشن ورود/خروج یکدست برای همه‌ی صفحات اپ: محو (fade) همراه با
/// سر خوردن ملایم از بالا. چون `MaterialPageRoute` (که همه‌جای اپ چه در
/// app_router.dart و چه در push‌های مستقیم استفاده می‌شود) وقتی خودش
/// ترنزیشن سفارشی ندارد به `Theme.pageTransitionsTheme` رجوع می‌کند، با
/// ست‌کردن این builder برای همه‌ی پلتفرم‌ها در main.dart، بدون دست‌زدن به
/// تک‌تک صفحه‌ها روی کل اپ اعمال می‌شود.
///
/// کارایی: در طولِ ترنزیشن هر دو صفحه دیده می‌شوند. نسخه‌ی قبلی هر دو را در
/// هر فریم از نو و با شفافیت می‌کشید (یعنی دو بار کلِ صفحه، هر کدام در یک
/// بافتِ جدا)؛ روی گوشیِ میان‌رده رفتن به صفحه‌ی جزییات و برگشتن پرلکنت بود.
/// حالا مثلِ ترنزیشنِ پیش‌فرضِ خودِ اندروید در فلاتر، هر صفحه یک‌بار «عکس»
/// می‌شود و در طولِ انیمیشن فقط همان عکس جابه‌جا و محو می‌شود؛ هزینه‌ی هر
/// فریم دیگر به سنگینیِ صفحه بستگی ندارد.
class FadeThroughTopPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeThroughTopPageTransitionsBuilder();

  /// پیش‌فرضِ متریال ۳۰۰ms است؛ کوتاه‌تر، سریع‌تر حس می‌شود.
  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 190);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FrozenFadeSlideTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      // روی وب رستر و منطق روی یک نخ‌اند؛ خودِ عکس‌گرفتن یک فریمِ طولانی
      // می‌سازد (اندازه‌گیری‌شده: ۳۰۰ms در برابرِ ۱۲۰ms) و سودی ندارد. خودِ
      // فلاتر هم به همین دلیل روی وب این کار را نمی‌کند.
      allowSnapshotting: !kIsWeb && route.allowSnapshotting,
      child: child,
    );
  }
}

/// صفحه‌ی واردشونده: محو + سر خوردنِ ملایم از بالا. صفحه‌ی زیری (وقتی صفحه‌ای
/// رویش باز یا از رویش بسته می‌شود): فقط محو. تا وقتی انیمیشن در جریان است
/// به‌جای خودِ صفحه، عکسِ آن کشیده می‌شود.
class FrozenFadeSlideTransition extends StatefulWidget {
  const FrozenFadeSlideTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    this.allowSnapshotting = true,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final bool allowSnapshotting;
  final Widget child;

  /// کسری از ارتفاع که صفحه‌ی تازه از بالاتر شروع می‌کند.
  static const double slideFraction = 0.04;

  @override
  State<FrozenFadeSlideTransition> createState() =>
      _FrozenFadeSlideTransitionState();
}

class _FrozenFadeSlideTransitionState
    extends State<FrozenFadeSlideTransition> {
  final SnapshotController _controller = SnapshotController();
  late CurvedAnimation _enter;
  late CurvedAnimation _exit;
  late _FadeSlidePainter _painter;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    _enter = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _exit = CurvedAnimation(
      parent: widget.secondaryAnimation,
      curve: Curves.easeIn,
      reverseCurve: Curves.easeOut,
    );
    _painter = _FadeSlidePainter(enter: _enter, exit: _exit);
    widget.animation.addStatusListener(_onStatus);
    widget.secondaryAnimation.addStatusListener(_onStatus);
    _sync();
  }

  void _detach(FrozenFadeSlideTransition from) {
    from.animation.removeStatusListener(_onStatus);
    from.secondaryAnimation.removeStatusListener(_onStatus);
    _painter.dispose();
    _enter.dispose();
    _exit.dispose();
  }

  void _onStatus(AnimationStatus _) => _sync();

  /// فقط وسطِ انیمیشن عکس گرفته می‌شود؛ صفحه‌ی ساکن همیشه زنده است.
  void _sync() {
    _controller.allowSnapshotting = widget.allowSnapshotting &&
        (widget.animation.isAnimating ||
            widget.secondaryAnimation.isAnimating);
  }

  @override
  void didUpdateWidget(FrozenFadeSlideTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation ||
        oldWidget.secondaryAnimation != widget.secondaryAnimation) {
      _detach(oldWidget);
      _attach();
    } else if (oldWidget.allowSnapshotting != widget.allowSnapshotting) {
      _sync();
    }
  }

  @override
  void dispose() {
    _detach(widget);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SnapshotWidget(
      painter: _painter,
      controller: _controller,
      // صفحه‌ای که ویدیو/وب‌ویوِ بومی دارد عکس‌شدنی نیست؛ همان‌جا خودکار به
      // کشیدنِ معمولی برمی‌گردد.
      mode: SnapshotMode.permissive,
      autoresize: true,
      child: widget.child,
    );
  }
}

class _FadeSlidePainter extends SnapshotPainter {
  _FadeSlidePainter({required this.enter, required this.exit}) {
    enter.addListener(notifyListeners);
    exit.addListener(notifyListeners);
    enter.addStatusListener(_onStatus);
    exit.addStatusListener(_onStatus);
  }

  final Animation<double> enter;
  final Animation<double> exit;

  final LayerHandle<OpacityLayer> _opacityHandle = LayerHandle<OpacityLayer>();

  void _onStatus(AnimationStatus _) => notifyListeners();

  double get _opacity => (enter.value * (1 - exit.value)).clamp(0.0, 1.0);

  double _dy(Size size) =>
      (enter.value - 1) *
      FrozenFadeSlideTransition.slideFraction *
      size.height;

  /// مسیرِ بدونِ عکس (ساکن، یا صفحه‌ای که عکس‌شدنی نیست).
  @override
  void paint(
    PaintingContext context,
    Offset offset,
    Size size,
    PaintingContextCallback painter,
  ) {
    final double opacity = _opacity;
    if (opacity <= 0) {
      _opacityHandle.layer = null;
      return;
    }
    final Offset shifted = offset.translate(0, _dy(size));
    if (opacity >= 1) {
      _opacityHandle.layer = null;
      painter(context, shifted);
      return;
    }
    _opacityHandle.layer = context.pushOpacity(
      shifted,
      (opacity * 255).round(),
      painter,
      oldLayer: _opacityHandle.layer,
    );
  }

  @override
  void paintSnapshot(
    PaintingContext context,
    Offset offset,
    Size size,
    ui.Image image,
    Size sourceSize,
    double pixelRatio,
  ) {
    final double opacity = _opacity;
    if (opacity <= 0) return;
    final Rect src =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final Rect dst = (offset & size).translate(0, _dy(size));
    final Paint paint = Paint()
      ..color = Color.fromRGBO(0, 0, 0, opacity)
      ..filterQuality = FilterQuality.low;
    context.canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  void dispose() {
    enter.removeListener(notifyListeners);
    exit.removeListener(notifyListeners);
    enter.removeStatusListener(_onStatus);
    exit.removeStatusListener(_onStatus);
    _opacityHandle.layer = null;
    super.dispose();
  }

  @override
  bool shouldRepaint(covariant _FadeSlidePainter oldDelegate) => true;
}
