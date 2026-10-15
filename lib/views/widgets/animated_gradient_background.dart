import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:persian_ball/constant/app_color.dart';

/// پس‌زمینه‌ی گرادیانِ متحرک و نرمِ سراسری اپ.
///
/// چند تینتِ ملایمِ هم‌خانواده با رنگ «شیری» تم، به‌آرامی در هم محو می‌شوند
/// و زاویه‌ی گرادیان هم آهسته می‌چرخد؛ حس یک پس‌زمینه‌ی «زنده» بدون
/// حواس‌پرتی. اگر کاربر «کاهش حرکت» را فعال کرده باشد، نسخه‌ی ثابت نمایش
/// داده می‌شود.
///
/// کارایی: این لایه زیرِ *همه‌ی* صفحه‌هاست. نسخه‌ی قبلی با یک
/// AnimationController هر فریم (۶۰ بار در ثانیه، همیشه، حتی وقتی کاربر
/// کاری نمی‌کرد) کلِ صفحه را دوباره رنگ می‌کرد؛ روی وب (CanvasKit) این
/// یعنی یک رسمِ تمام‌صفحه در هر فریم که با اسکرول و انیمیشن‌های خودِ
/// صفحه رقابت می‌کرد و حسِ لرزش می‌داد. یک چرخه‌ی ۲۲ ثانیه‌ای با ۸ فریم
/// در ثانیه هم کاملاً نرم دیده می‌شود (هر گام ~۲ درجه چرخش و تغییرِ رنگِ
/// نامحسوس)، پس به‌جای تیکِ هر فریم، یک تایمرِ کم‌سرعت جلو می‌رود و وقتی
/// اپ در پس‌زمینه است کاملاً می‌ایستد.
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key, this.child});

  /// در صورت نیاز می‌توان محتوا را مستقیماً روی پس‌زمینه سوار کرد.
  final Widget? child;

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with WidgetsBindingObserver {
  /// طولِ یک چرخه‌ی کاملِ پالت/چرخش.
  static const Duration _cycle = Duration(seconds: 22);

  /// فاصله‌ی گام‌ها؛ ۱۲۵ms = ۸ فریم در ثانیه.
  static const Duration _step = Duration(milliseconds: 125);

  // پالتِ گرادیان — رنگی و قابل‌دیدن، اما نرم و هم‌خانواده با تمِ برند
  // (سبز چمن + کِرِمِ شیری + آبیِ ملایم).
  static const List<List<Color>> _palette = [
    [Color(0xFFCDE8D5), Color(0xFFEDE6CF), Color(0xFFF3EAD8)],
    [Color(0xFFD7E6EF), Color(0xFFDFEBD9), Color(0xFFCFE6D6)],
    [Color(0xFFEFE6D2), Color(0xFFD9EAD9), Color(0xFFCEE4EC)],
    [Color(0xFFCEE7DD), Color(0xFFE9E7D0), Color(0xFFDDE8F0)],
  ];

  Timer? _timer;

  /// پیشرفتِ چرخه در بازه‌ی [0, 1). از روی ساعتِ واقعی حساب می‌شود، نه
  /// شمارشِ تیک‌ها، تا بعد از مکث (تبِ پنهان) پرش نکند و همیشه هم‌فاز
  /// بماند.
  double _t = 0;
  final Stopwatch _clock = Stopwatch();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock.start();
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // در پس‌زمینه هیچ فریمی نساز؛ برگشت، از همان‌جا که ساعت می‌گوید.
    if (state == AppLifecycleState.resumed) {
      _start();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _start() {
    _timer ??= Timer.periodic(_step, (_) {
      if (!mounted) return;
      setState(() => _t = _progress());
    });
  }

  double _progress() =>
      (_clock.elapsedMilliseconds % _cycle.inMilliseconds) /
      _cycle.inMilliseconds;

  List<Color> _lerpStops(double t) {
    final int count = _palette.length;
    final double scaled = (t * count) % count;
    final int i = scaled.floor();
    final double f = Curves.easeInOut.transform(scaled - i);
    final a = _palette[i % count];
    final b = _palette[(i + 1) % count];
    return [
      Color.lerp(a[0], b[0], f)!,
      Color.lerp(a[1], b[1], f)!,
      Color.lerp(a[2], b[2], f)!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduceMotion) {
      return _StaticLayer(colors: _lerpStops(0), child: widget.child);
    }

    final double angle = _t * 2 * math.pi;
    final Alignment begin = Alignment(
      0.9 * math.cos(angle),
      0.9 * math.sin(angle),
    );
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: -begin,
            colors: _lerpStops(_t),
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: widget.child ?? const SizedBox.expand(),
      ),
    );
  }
}

class _StaticLayer extends StatelessWidget {
  const _StaticLayer({required this.colors, this.child});

  final List<Color> colors;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: colors,
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: child ?? const SizedBox.expand(),
    );
  }
}

/// رنگِ پایه‌ی پس‌زمینه (برای جاهایی که به یک رنگ ثابت نیاز است).
const Color kAppBackgroundBase = AppColor.milk;
