// lib/views/widgets/motion.dart
//
// جعبه‌ابزار حرکت اپ: چند ویجت کوچک و قابل‌استفاده‌ی مجدد تا همه‌ی صفحات
// زبان انیمیشن یکسانی داشته باشند (همان حس «مورف» صفحه‌ی محصول).
import 'package:flutter/material.dart';

/// بازخورد لمسی کارت‌ها و آیتم‌های قابل‌ضربه: هنگام فشردن کمی جمع می‌شود
/// و با رها شدن با فنر نرم برمی‌گردد. جایگزین GestureDetector خشکِ قبلی.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.965,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: Duration(milliseconds: _pressed ? 90 : 220),
        curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
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

/// تعویض نرم بین تب‌های اصلی، بدون از دست رفتن حالت صفحات: همه‌ی بچه‌ها
/// زنده می‌مانند (مثل IndexedStack) و فقط شفافیت/مقیاسشان انیمیت می‌شود.
class FadeIndexedStack extends StatelessWidget {
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 320),
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

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
              child: AnimatedScale(
                scale: i == index ? 1 : 0.985,
                duration: duration,
                curve: Curves.easeOutCubic,
                // صفحه‌ی غیر فعال نباید فوکوس/اسکرول بگیرد یا هزینه‌ی
                // رندر بدهد؛ وقتی کاملاً محو شد از درخت نقاشی حذف می‌شود.
                child: TickerMode(
                  enabled: i == index,
                  child: ExcludeSemantics(
                    excluding: i != index,
                    child: Visibility(
                      visible: true,
                      maintainState: true,
                      child: children[i],
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
