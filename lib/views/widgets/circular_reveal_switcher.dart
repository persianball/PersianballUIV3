import 'dart:math' as math;

import 'package:flutter/material.dart';

/// محتوای جدید را با یک ترنزیشن دایره‌ای از نقطه‌ی [center] (مختصات global،
/// مثلاً محل کلیک کاربر) روی محتوای قبلی باز می‌کند.
/// اگر [center] داده نشود، دایره از وسط باز می‌شود.
class CircularRevealSwitcher extends StatefulWidget {
  final Widget child;
  final Offset? center;
  final Duration duration;

  const CircularRevealSwitcher({
    super.key,
    required this.child,
    this.center,
    this.duration = const Duration(milliseconds: 450),
  });

  @override
  State<CircularRevealSwitcher> createState() => _CircularRevealSwitcherState();
}

class _CircularRevealSwitcherState extends State<CircularRevealSwitcher> {
  final GlobalKey _boxKey = GlobalKey();

  /// تبدیل نقطه‌ی global به مختصات محلی همین ویجت
  Offset? _localCenter() {
    final center = widget.center;
    if (center == null) return null;
    final box = _boxKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.globalToLocal(center);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: _boxKey,
      child: AnimatedSwitcher(
        duration: widget.duration,
        switchInCurve: Curves.easeOutCubic,
        // محتوای قبلی تا پایان انیمیشن زیر محتوای جدید می‌ماند
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.center,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        transitionBuilder: (child, animation) => _CircularReveal(
          animation: animation,
          center: _localCenter(),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class _CircularReveal extends StatelessWidget {
  final Animation<double> animation;
  final Offset? center;
  final Widget child;

  const _CircularReveal({
    required this.animation,
    required this.center,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => ClipPath(
        clipper: _CircleRevealClipper(
          fraction: animation.value,
          center: center,
        ),
        child: child,
      ),
    );
  }
}

class _CircleRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Offset? center;

  _CircleRevealClipper({required this.fraction, this.center});

  @override
  Path getClip(Size size) {
    final c = center ?? Offset(size.width / 2, size.height / 2);
    // شعاع لازم تا دورترین گوشه پوشش داده شود
    final maxRadius = [
      Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((corner) => (corner - c).distance).reduce(math.max);

    return Path()
      ..addOval(Rect.fromCircle(center: c, radius: maxRadius * fraction));
  }

  @override
  bool shouldReclip(_CircleRevealClipper oldClipper) =>
      oldClipper.fraction != fraction || oldClipper.center != center;
}
