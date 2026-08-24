import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';

/// گوشه‌های «اسکوئرکل» به سبک اپل (continuous curvature).
///
/// اپل گوشه‌ها را با انحنای پیوسته می‌سازد نه کمان دایره‌ای؛ معادل آن در
/// فلاتر [ContinuousRectangleBorder] است. نکته‌ی مهم: ContinuousRectangleBorder
/// برای شعاع یکسان، گوشه‌ی به‌مراتب تیزتری نسبت به BorderRadius.circular
/// می‌سازد، پس شعاع ورودی در [_k] ضرب می‌شود تا برجستگی گوشه با آنچه طراح
/// انتظار دارد یکی شود.
class AppShapes {
  AppShapes._();

  static const double _k = 1.7;

  /// شعاع معادل برای استفاده در [ContinuousRectangleBorder].
  static BorderRadius radius(double r) => BorderRadius.circular(r * _k);

  static BorderRadius radiusTop(double r) =>
      BorderRadius.vertical(top: Radius.circular(r * _k));

  static BorderRadius radiusBottom(double r) =>
      BorderRadius.vertical(bottom: Radius.circular(r * _k));

  /// شکل اسکوئرکل برای Card / Dialog / Button / BottomSheet
  static ContinuousRectangleBorder border(double r, {BorderSide? side}) =>
      ContinuousRectangleBorder(
        borderRadius: radius(r),
        side: side ?? BorderSide.none,
      );

  static ContinuousRectangleBorder borderTop(double r) =>
      ContinuousRectangleBorder(borderRadius: radiusTop(r));

  /// دکمه‌ها و بج‌ها همیشه کاملاً گرد (قرصی) هستند — هیچ گوشه‌ی تیزی در
  /// اپ نباید دیده شود.
  static const StadiumBorder pill = StadiumBorder();

  static BorderRadius pillRadius(double height) =>
      BorderRadius.circular(height);

  /// شعاع‌های متداول اپ
  static const double rSm = 10;
  static const double rMd = 16;
  static const double rLg = 22;
  static const double rXl = 28;
}

/// برش محتوا با گوشه‌ی اسکوئرکل (معادل ClipRRect ولی با انحنای پیوسته).
class SquircleClip extends StatelessWidget {
  const SquircleClip({
    super.key,
    required this.radius,
    required this.child,
    this.clipBehavior = Clip.antiAlias,
  });

  final double radius;
  final Widget child;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: ShapeBorderClipper(
        shape: AppShapes.border(radius),
        textDirection: Directionality.maybeOf(context),
      ),
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

/// کارت برجسته‌ی استاندارد اپ: سطح سفید + گوشه‌ی اسکوئرکل + سایه‌ی نرم.
class RaisedSurface extends StatelessWidget {
  const RaisedSurface({
    super.key,
    required this.child,
    this.radius = AppShapes.rMd,
    this.color,
    this.shadow,
    this.padding,
    this.margin,
    this.side,
    this.clip = false,
  });

  final Widget child;
  final double radius;
  final Color? color;
  final List<BoxShadow>? shadow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderSide? side;

  /// اگر محتوا (مثلاً تصویر) باید داخل گوشه‌ها بریده شود
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: padding,
      margin: margin,
      decoration: ShapeDecoration(
        color: color ?? AppColor.card,
        shape: AppShapes.border(radius, side: side),
        shadows: shadow ?? AppColor.cardShadow,
      ),
      child: clip ? SquircleClip(radius: radius, child: child) : child,
    );
    return body;
  }
}
