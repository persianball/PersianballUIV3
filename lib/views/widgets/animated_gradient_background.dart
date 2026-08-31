import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';

/// پس‌زمینه‌ی گرادیانِ متحرک و نرمِ سراسری اپ.
///
/// چند تینتِ ملایمِ هم‌خانواده با رنگ «شیری» تم، به‌آرامی در هم محو می‌شوند
/// و زاویه‌ی گرادیان هم آهسته می‌چرخد؛ حس یک پس‌زمینه‌ی «زنده» بدون
/// حواس‌پرتی. اگر کاربر «کاهش حرکت» را فعال کرده باشد، نسخه‌ی ثابت نمایش
/// داده می‌شود.
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key, this.child});

  /// در صورت نیاز می‌توان محتوا را مستقیماً روی پس‌زمینه سوار کرد.
  final Widget? child;

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // پالتِ تینت‌های ملایم حول رنگ شیری تم.
  static const List<List<Color>> _palette = [
    [Color(0xFFF2F3E8), Color(0xFFE8F1EA), Color(0xFFF3EEE4)],
    [Color(0xFFEAF0F2), Color(0xFFF2F3E8), Color(0xFFE6F1E9)],
    [Color(0xFFF4EFE6), Color(0xFFEBF2ED), Color(0xFFF2F3E8)],
    [Color(0xFFE9F1EC), Color(0xFFF3F1E7), Color(0xFFEDF1F3)],
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double t = _controller.value;
          final double angle = t * 2 * math.pi;
          final Alignment begin = Alignment(
            0.9 * math.cos(angle),
            0.9 * math.sin(angle),
          );
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: begin,
                end: -begin,
                colors: _lerpStops(t),
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: child,
          );
        },
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
