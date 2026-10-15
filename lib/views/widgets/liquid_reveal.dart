// lib/views/widgets/liquid_reveal.dart
//
// گذارِ «مایع» برای عوض شدنِ رنگِ محصول: تصویرِ رنگِ تازه با یک دایره‌ی
// لرزانِ لبه‌موج‌دار از پایینِ قاب (سمتِ انتخاب‌گرِ رنگ) باز می‌شود و
// موج‌ها هرچه دایره بزرگ‌تر می‌شود آرام می‌گیرند. تصویرِ قبلی زیرش می‌ماند.
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// transitionBuilderِ AnimatedSwitcher. خروجی‌ها (reverse) فقط می‌مانند تا
/// ورودیِ تازه رویشان باز شود.
Widget liquidRevealTransition(Widget child, Animation<double> animation,
    {Alignment origin = const Alignment(0, 1.1)}) {
  return AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) {
      if (animation.status == AnimationStatus.reverse) {
        // خروجی: ثابت می‌ماند و فقط در انتها کمی محو می‌شود
        return Opacity(
          opacity: Curves.easeIn.transform(animation.value.clamp(0.0, 1.0)),
          child: child,
        );
      }
      final t = Curves.easeInOutCubic.transform(animation.value);
      if (t >= 1) return child!;
      return ClipPath(
        clipper: _LiquidCircleClipper(progress: t, origin: origin),
        child: child,
      );
    },
  );
}

class _LiquidCircleClipper extends CustomClipper<Path> {
  _LiquidCircleClipper({required this.progress, required this.origin});

  final double progress;
  final Alignment origin;

  @override
  Path getClip(Size size) {
    final c = origin.alongSize(size);
    // شعاعی که از مبدأ تا دورترین گوشه برسد
    final far = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((p) => (p - c).distance).reduce(math.max);
    final r = far * 1.08 * progress;
    // موج: ۷ برآمدگی که با بزرگ شدن آرام می‌گیرند و کمی می‌چرخند
    final amp = r * 0.07 * (1 - progress);
    final phase = progress * math.pi * 2.4;
    const n = 72;
    final path = Path();
    for (int i = 0; i <= n; i++) {
      final a = i / n * math.pi * 2;
      final rr = r + amp * math.sin(a * 7 + phase);
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_LiquidCircleClipper old) =>
      old.progress != progress || old.origin != origin;
}
