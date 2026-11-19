import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:persian_ball/constant/app_color.dart';

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
      SafeContinuousBorder(
        borderRadius: radius(r),
        side: side ?? BorderSide.none,
      );

  static ContinuousRectangleBorder borderTop(double r) =>
      SafeContinuousBorder(borderRadius: radiusTop(r));

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

/// [ContinuousRectangleBorder] که شعاعش هرگز از نصفِ ضلعِ کوتاه بیشتر نمی‌شود.
///
/// خودِ فلاتر شعاع را فقط به «کلِ» ضلعِ کوتاه محدود می‌کند، نه نصفش. روی یک
/// ویجتِ کوتاه (مثلاً دکمه‌ی ۳۸ پیکسلی با شعاعِ ۲۲×۱٫۷≈۳۷) منحنیِ گوشه‌ی بالا
/// و پایین از روی هم رد می‌شوند و وقتی کادر خط دارد، یک خطِ صافِ عمودی در
/// تمامِ ارتفاع از دو سرِ آن بیرون می‌زند — همان «خط»هایی که روی دکمه‌ی
/// «انتخاب شد» دیده می‌شد. اینجا شعاع موقعِ رسم با اندازه‌ی واقعی محدود
/// می‌شود؛ ویجتِ بلند هیچ تغییری نمی‌کند.
class SafeContinuousBorder extends ContinuousRectangleBorder {
  const SafeContinuousBorder({super.side, super.borderRadius});

  ContinuousRectangleBorder _fitted(Rect rect, TextDirection? textDirection) {
    final r = borderRadius.resolve(textDirection);
    final limit = rect.shortestSide / 2;
    Radius fit(Radius x) =>
        Radius.elliptical(math.min(x.x, limit), math.min(x.y, limit));
    return ContinuousRectangleBorder(
      side: side,
      borderRadius: BorderRadius.only(
        topLeft: fit(r.topLeft),
        topRight: fit(r.topRight),
        bottomLeft: fit(r.bottomLeft),
        bottomRight: fit(r.bottomRight),
      ),
    );
  }

  /// سایه‌ها با مستطیلِ گوشه‌گرد کشیده شوند، نه با مسیرِ اسکوئرکل.
  ///
  /// سایه‌ی محو روی یک «مسیرِ دلخواه» برای GPU گران است: موتور باید شکل را
  /// در یک بافتِ جدا بکشد و چند گذرِ تاری رویش بزند، برای هر سایه و در هر
  /// فریم. تقریباً همه‌ی کارت‌های اپ چنین سایه‌ای دارند (هر صفحه ده‌ها عدد)
  /// و همین اسکرول و ترنزیشن را روی گوشیِ میان‌رده پرلکنت می‌کرد. برای
  /// مستطیلِ گوشه‌گرد موتور فرمولِ مستقیم دارد و بافتِ جدا لازم نیست. خودِ
  /// سطحِ کارت همچنان اسکوئرکلِ دقیق است؛ فقط سایه‌ی محوش تقریبی است و با
  /// تاریِ ۱۶ پیکسلی تفاوتی دیده نمی‌شود.
  static bool fastShadows = true;

  // ShapeDecoration وقتی این true باشد سایه و سطح را با paintInterior می‌کشد.
  @override
  bool get preferPaintInterior => true;

  @override
  void paintInterior(Canvas canvas, Rect rect, Paint paint,
      {TextDirection? textDirection}) {
    // رنگِ سایه همیشه maskFilter دارد (BoxShadow.toPaint)؛ سطحِ کارت ندارد.
    if (fastShadows && paint.maskFilter != null) {
      final r = borderRadius.resolve(textDirection);
      final limit = rect.shortestSide / 2;
      // شعاعِ ذخیره‌شده در _k ضرب شده؛ معادلِ دایره‌ای‌اش همان شعاعِ طراحی است.
      Radius c(Radius x) =>
          Radius.circular(math.min(x.x / AppShapes._k, limit));
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: c(r.topLeft),
          topRight: c(r.topRight),
          bottomLeft: c(r.bottomLeft),
          bottomRight: c(r.bottomRight),
        ),
        paint,
      );
      return;
    }
    canvas.drawPath(getOuterPath(rect, textDirection: textDirection), paint);
  }

  // paint ـِ والد از getOuterPath استفاده می‌کند، پس خط هم محدود رسم می‌شود.
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _fitted(rect, textDirection)
          .getOuterPath(rect, textDirection: textDirection);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _fitted(rect, textDirection)
          .getInnerPath(rect, textDirection: textDirection);

  // بدونِ این‌ها، انیمیشن (مثلاً AnimatedContainer) در میانه‌ی راه یک
  // ContinuousRectangleBorder معمولی می‌سازد و خطِ اضافه چشمک می‌زند.
  @override
  ShapeBorder scale(double t) =>
      SafeContinuousBorder(side: side.scale(t), borderRadius: borderRadius * t);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is ContinuousRectangleBorder) {
      return SafeContinuousBorder(
        side: BorderSide.lerp(a.side, side, t),
        borderRadius:
            BorderRadiusGeometry.lerp(a.borderRadius, borderRadius, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is ContinuousRectangleBorder) {
      return SafeContinuousBorder(
        side: BorderSide.lerp(side, b.side, t),
        borderRadius:
            BorderRadiusGeometry.lerp(borderRadius, b.borderRadius, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  SafeContinuousBorder copyWith(
          {BorderSide? side, BorderRadiusGeometry? borderRadius}) =>
      SafeContinuousBorder(
        side: side ?? this.side,
        borderRadius: borderRadius ?? this.borderRadius,
      );
}
