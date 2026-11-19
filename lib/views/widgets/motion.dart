// lib/views/widgets/motion.dart
//
// جعبه‌ابزار حرکت اپ: چند ویجت کوچک و قابل‌استفاده‌ی مجدد تا همه‌ی صفحات
// زبان انیمیشن یکسانی داشته باشند (همان حس «مورف» صفحه‌ی محصول).
import 'dart:async';

import 'package:flutter/material.dart';

/// بازخورد لمسی کارت‌ها و آیتم‌های قابل‌ضربه: هنگام فشردن کمی جمع می‌شود
/// و با رها شدن با فنر نرم برمی‌گردد. جایگزین GestureDetector خشکِ قبلی.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.965,
    this.hoverScale = 1.02,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  /// بزرگ‌نماییِ ملایم هنگام hover با ماوس (وب/دسکتاپ). ۱ یعنی بدون افکت.
  final double hoverScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;
  bool _hovered = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  void _setHover(bool value) {
    if (_hovered != value) setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool interactive = widget.onTap != null;
    final double scale = _pressed
        ? widget.pressedScale
        : (_hovered ? widget.hoverScale : 1.0);

    Widget result = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: scale,
        duration: Duration(milliseconds: _pressed ? 90 : 200),
        curve: _pressed ? Curves.easeOut : Curves.easeOutCubic,
        child: widget.child,
      ),
    );

    if (interactive) {
      result = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHover(true),
        onExit: (_) => _setHover(false),
        child: result,
      );
    }
    return result;
  }
}

/// ورود نرم عنصر: محو + سر خوردن کوتاه از پایین، با تأخیر اختیاری تا
/// آیتم‌های یک لیست/گرید پشت‌سرهم (staggered) وارد شوند.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = 0.06,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// جابه‌جایی اولیه نسبت به ارتفاع خود ویجت (کسر)
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final CurvedAnimation _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, widget.offset),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// تعویض نرم بین تب‌های اصلی، بدون از دست رفتن حالت صفحات: تب‌های دیده‌شده
/// زنده می‌مانند (مثل IndexedStack) و فقط شفافیت/مقیاسشان انیمیت می‌شود.
///
/// تنبل: هر تب اولین بار که انتخاب شود ساخته می‌شود. قبلاً هر چهار تب در
/// همان فریمِ اول ساخته می‌شدند؛ یعنی باز شدنِ اپ همزمان درخواست‌ها،
/// چیدمان و دیکودِ تصویرِ خانه + دوره‌ها + فروشگاه + پروفایل را راه
/// می‌انداخت (محصولات و دوره‌ها هر کدام دو بار گرفته می‌شدند) و روی گوشیِ
/// میان‌رده بارگذاریِ اول کند و پرلکنت بود.
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 160),
    this.warmUpAfter,
    this.warmUpGap = const Duration(milliseconds: 1500),
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  /// اگر داده شود، بعد از این مکث تب‌های ندیده یکی‌یکی (با فاصله‌ی
  /// [warmUpGap]) در پس‌زمینه ساخته می‌شوند. بارگذاریِ اول سبک می‌ماند و
  /// اولین ضربه روی هر تب هم دیگر منتظرِ ساختنِ صفحه و درخواستش نمی‌ماند.
  final Duration? warmUpAfter;
  final Duration warmUpGap;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> {
  late final Set<int> _visited = {widget.index};
  Timer? _warmUp;

  @override
  void initState() {
    super.initState();
    final after = widget.warmUpAfter;
    if (after != null) _warmUp = Timer(after, _warmNext);
  }

  void _warmNext() {
    if (!mounted) return;
    for (int i = 0; i < widget.children.length; i++) {
      if (_visited.contains(i)) continue;
      setState(() => _visited.add(i));
      _warmUp = Timer(widget.warmUpGap, _warmNext);
      return;
    }
  }

  @override
  void dispose() {
    _warmUp?.cancel();
    super.dispose();
  }

  int get index => widget.index;
  List<Widget> get children => widget.children;
  Duration get duration => widget.duration;

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visited.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (int i = 0; i < children.length; i++)
          IgnorePointer(
            ignoring: i != index,
            child: AnimatedOpacity(
              opacity: i == index ? 1 : 0,
              duration: duration,
              curve: Curves.easeOutCubic,
              // مقیاس عمداً انیمیت نمی‌شود: تغییرِ مقیاس در هر فریم کلِ صفحه
              // را دوباره رستر می‌کرد و تعویضِ تب را سنگین می‌کرد.
              child: SizedBox.expand(
                // صفحه‌ی غیر فعال نباید فوکوس/اسکرول بگیرد یا هزینه‌ی
                // رندر بدهد؛ وقتی کاملاً محو شد از درخت نقاشی حذف می‌شود.
                child: TickerMode(
                  enabled: i == index,
                  child: ExcludeSemantics(
                    excluding: i != index,
                    child: Visibility(
                      visible: true,
                      maintainState: true,
                      child: _visited.contains(i)
                          ? children[i]
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
