// lib/views/widgets/shimmer.dart
//
// افکتِ «شیمر»: یک نوارِ نورِ متحرک روی اسکلتونِ صفحه که دقیقاً ساختارِ
// صفحه‌ی بارگذاری‌شده را تقلید می‌کند. برای ساختنِ اسکلتون از [Bone] استفاده
// کنید و کلِ درخت را داخل یک [Shimmer] بگذارید.
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';

class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  static const Color _base = AppColor.cardMuted;
  static const Color _highlight = Color(0xFFF7FAF8);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      // بدونِ حرکت: فقط رنگِ پایه (Bone خودش همین رنگ را دارد)
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          final double t = _c.value;
          final double dx = (t * 2.4 - 1.2) * bounds.width;
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [_base, _highlight, _base],
            stops: const [0.35, 0.5, 0.65],
            transform: _SlideTransform(dx),
          ).createShader(bounds);
        },
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _SlideTransform extends GradientTransform {
  const _SlideTransform(this.dx);
  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, 0, 0);
}

/// یک شکلِ توپُرِ اسکلتون. حتماً باید فرزندِ یک [Shimmer] باشد.
class Bone extends StatelessWidget {
  const Bone({
    super.key,
    this.width,
    this.height,
    this.radius = 8,
    this.shape = BoxShape.rectangle,
  });

  const Bone.circle({super.key, required double size})
      : width = size,
        height = size,
        radius = 0,
        shape = BoxShape.circle;

  final double? width;
  final double? height;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColor.cardMuted,
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}
