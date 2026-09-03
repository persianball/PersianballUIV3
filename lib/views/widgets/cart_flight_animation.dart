// lib/views/widgets/cart_flight_animation.dart
//
// انیمیشن «افزودن به سبد»:
//  ۱) شیت پایین بسته می‌شود و تصویر کالا از داخل آن جدا می‌ماند
//  ۲) تصویر با مسیر منحنی به مرکز صفحه می‌آید و داخل یک قاب دایره‌ای می‌نشیند
//  ۳) حلقه‌ی نوری دور دایره کشیده می‌شود و سبدِ برداری از پایین بالا می‌آید
//  ۴) کالا با شتاب جاذبه داخل سبد می‌افتد، سبد جمع/باز می‌شود و ذرات می‌پاشند
//
// همه‌چیز روی Overlay ریشه اجرا می‌شود، پس مستقل از صفحه‌ی جاری است و با
// بسته‌شدن شیت از بین نمی‌رود.
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/views/widgets/app_network_image.dart';

/// مدت کل نمایش انیمیشن
const Duration _kFlightDuration = Duration(milliseconds: 2150);

class CartFlightOverlay {
  CartFlightOverlay._();

  static OverlayEntry? _entry;
  static DateTime _busyUntil = DateTime.fromMillisecondsSinceEpoch(0);

  /// تا وقتی انیمیشن در جریان است (به‌علاوه‌ی کمی مهلت) دیالوگ «افزوده شد»
  /// نباید روی انیمیشن بیفتد.
  static bool get isRunning => DateTime.now().isBefore(_busyUntil);

  /// شروع پرواز کالا از [sourceRect] (مختصات سراسری صفحه) تا سبد.
  static void launch(
    BuildContext context, {
    required String imageUrl,
    required Rect sourceRect,
  }) {
    if (_entry != null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _busyUntil = DateTime.now().add(_kFlightDuration + const Duration(milliseconds: 700));

    final entry = OverlayEntry(
      builder: (_) => _CartFlightLayer(
        imageUrl: imageUrl,
        sourceRect: sourceRect,
        onDone: dismiss,
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    HapticFeedback.lightImpact();
  }

  /// بستن فوری (مثلاً وقتی سرور خطا داد)
  static void dismiss() {
    _entry?.remove();
    _entry = null;
    _busyUntil = DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// مستطیل سراسری یک ویجت از روی کلیدش — برای گرفتن نقطه‌ی شروع پرواز.
  static Rect? rectOf(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

class _CartFlightLayer extends StatefulWidget {
  const _CartFlightLayer({
    required this.imageUrl,
    required this.sourceRect,
    required this.onDone,
  });

  final String imageUrl;
  final Rect sourceRect;
  final VoidCallback onDone;

  @override
  State<_CartFlightLayer> createState() => _CartFlightLayerState();
}

class _CartFlightLayerState extends State<_CartFlightLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  /// زاویه/شعاع تصادفیِ ذرات — یک‌بار ساخته می‌شود تا هر فریم نپرد.
  late final List<_Particle> _particles;

  bool _landed = false;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(7);
    const count = 14;
    _particles = List.generate(count, (i) {
      // زاویه‌ها به‌صورت بادبزنی و متقارن پخش می‌شوند (با کمی لرزش تصادفی)
      // تا انفجار ذرات یک‌طرفه به نظر نرسد.
      final spread = -math.pi / 2 +
          (i / (count - 1) - 0.5) * 2.6 +
          (rnd.nextDouble() - 0.5) * 0.16;
      final a = spread;
      return _Particle(
        angle: a,
        distance: 42 + rnd.nextDouble() * 62,
        size: 3.5 + rnd.nextDouble() * 4.5,
        delay: rnd.nextDouble() * 0.12,
        spin: (rnd.nextDouble() - 0.5) * 6,
        star: i.isEven,
      );
    });

    _c = AnimationController(vsync: this, duration: _kFlightDuration)
      ..addListener(_onTick)
      ..forward().whenComplete(widget.onDone);
  }

  void _onTick() {
    if (!_landed && _c.value >= 0.845) {
      _landed = true;
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onTick);
    _c.dispose();
    super.dispose();
  }

  // ---- کمک‌تابع‌های زمان‌بندی ----

  double _seg(double t, double a, double b, [Curve curve = Curves.linear]) =>
      curve.transform((((t - a) / (b - a))).clamp(0.0, 1.0));

  Offset _bezier(Offset a, Offset ctrl, Offset b, double t) {
    final u = 1 - t;
    return Offset(
      u * u * a.dx + 2 * u * t * ctrl.dx + t * t * b.dx,
      u * u * a.dy + 2 * u * t * ctrl.dy + t * t * b.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;

    // ---- هندسه‌ی ثابت صحنه ----
    final double circleD = math.min(screen.width * 0.46, 176);
    final double basketW = math.min(screen.width * 0.36, 138);
    final double basketH = basketW * 0.94;
    final double basketBottom = screen.height - media.viewPadding.bottom - 54;
    final Offset basketTopCenter =
        Offset(screen.width / 2, basketBottom - basketH);
    // دهانه‌ی سبد: نقطه‌ای که کالا داخلش می‌افتد
    final Offset mouth =
        Offset(basketTopCenter.dx, basketTopCenter.dy + basketH * 0.30);
    final Offset stage = Offset(screen.width / 2, screen.height * 0.36);

    final Offset src = widget.sourceRect.center;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;

          // فازها
          final pLift = _seg(t, 0.00, 0.10, Curves.easeOutBack);
          final pRise = _seg(t, 0.08, 0.42, Curves.easeOutCubic);
          final pMorph = _seg(t, 0.08, 0.34, Curves.easeOutCubic);
          final pRing = _seg(t, 0.32, 0.58, Curves.easeInOutCubic);
          final pHalo = _seg(t, 0.34, 0.62, Curves.easeOutCubic);
          final pAntic = _seg(t, 0.50, 0.58, Curves.easeOutCubic);
          final pDropRaw = _seg(t, 0.58, 0.87);
          final pDrop = Curves.easeInCubic.transform(pDropRaw);
          final pBasket = _seg(t, 0.22, 0.48, Curves.elasticOut);
          final pOpen = _seg(t, 0.56, 0.72, Curves.easeOutBack);
          final pLandRaw = _seg(t, 0.845, 1.0);
          final pBurst = _seg(t, 0.845, 1.0, Curves.easeOutCubic);
          final pBadge = _seg(t, 0.86, 0.98, Curves.elasticOut);
          final pOut = _seg(t, 0.93, 1.0, Curves.easeIn);

          final scrim = _seg(t, 0.02, 0.22, Curves.easeOut) * (1 - pOut);

          // ---- مسیر کالا ----
          Offset itemPos(double rise, double drop) {
            if (drop <= 0) {
              final ctrl = Offset(
                lerpDouble(src.dx, stage.dx, 0.15)!,
                math.min(src.dy, stage.dy) - screen.height * 0.10,
              );
              final p = _bezier(src, ctrl, stage, rise);
              return p.translate(0, -6 * pLift * (1 - rise));
            }
            final ctrl = Offset(
              stage.dx + (mouth.dx - stage.dx) * 0.5 + 26,
              lerpDouble(stage.dy, mouth.dy, 0.35)!,
            );
            return _bezier(stage, ctrl, mouth, drop);
          }

          final Offset pos =
              itemPos(pRise, pDrop).translate(0, -18 * pAntic * (1 - pDropRaw));

          // ---- اندازه/چرخش/شکل کالا ----
          final double riseSize =
              lerpDouble(widget.sourceRect.width, circleD, pRise)!;
          final double pulse =
              1 + 0.09 * math.sin(math.pi * _seg(t, 0.34, 0.60));
          final double dropShrink = lerpDouble(1.0, 0.34, pDrop)!;
          final double itemSize = riseSize * pulse * dropShrink;
          final double radius =
              lerpDouble(widget.sourceRect.width * 0.28, itemSize / 2, pMorph)!;
          final double tilt = 0.55 * pDrop * math.sin(pDropRaw * math.pi * 0.9);

          // نزدیک دهانه، کالا پشت بدنه‌ی سبد محو می‌شود
          final double itemFade =
              (1 - _seg(t, 0.83, 0.90, Curves.easeIn)) * (1 - pOut);

          return Stack(
            children: [
              // ۱) پرده‌ی تیره با نورِ نرم پشت صحنه
              //
              // عمداً از BackdropFilter استفاده نمی‌کنیم: بلورِ تمام‌صفحه در
              // هر فریم گران است و روی گوشی‌های میان‌رده انیمیشن را کند
              // می‌کند. گرادیان شعاعی همان حسِ عمق را با هزینه‌ی ناچیز
              // می‌دهد.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        (stage.dx / screen.width) * 2 - 1,
                        (stage.dy / screen.height) * 2 - 1,
                      ),
                      radius: 0.95,
                      colors: [
                        AppColor.pitchGreenDark.withOpacity(0.30 * scrim),
                        AppColor.ink.withOpacity(0.55 * scrim),
                      ],
                    ),
                  ),
                ),
              ),

              // ۲) هاله‌های نوری پشت قاب دایره‌ای
              if (pHalo > 0 && pDrop < 0.5)
                ..._halos(pos, circleD, pHalo, 1 - pDropRaw),

              // ۳) دنباله‌ی حرکت هنگام سقوط
              if (pDrop > 0.02)
                for (int i = 3; i >= 1; i--)
                  _ghost(
                    pos: itemPos(
                        pRise,
                        Curves.easeInCubic
                            .transform((pDropRaw - i * 0.055).clamp(0.0, 1.0))),
                    size: itemSize * (1 - i * 0.06),
                    radius: radius,
                    opacity: 0.16 * (3 - i + 1) / 3 * itemFade,
                  ),

              // ۴) خودِ کالا داخل قاب دایره‌ای
              Positioned(
                left: pos.dx - itemSize / 2,
                top: pos.dy - itemSize / 2,
                width: itemSize,
                height: itemSize,
                child: Opacity(
                  opacity: itemFade.clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: tilt,
                    child: _ProductBubble(
                      imageUrl: widget.imageUrl,
                      radius: radius,
                      ringProgress: pRing,
                      ringOpacity: 1 - _seg(t, 0.62, 0.78, Curves.easeIn),
                      glow: (1 - pDropRaw).clamp(0.0, 1.0),
                    ),
                  ),
                ),
              ),

              // ۵) سبد (بعد از کالا رسم می‌شود تا کالا پشت آن پنهان شود)
              Positioned(
                left: basketTopCenter.dx - basketW / 2,
                top: basketTopCenter.dy,
                width: basketW,
                height: basketH,
                child: Opacity(
                  opacity: (pBasket.clamp(0.0, 1.0)) * (1 - pOut),
                  child: Transform.translate(
                    offset: Offset(0, (1 - pBasket) * basketH * 1.4),
                    child: _AnimatedBasket(
                      open: pOpen,
                      land: pLandRaw,
                      fill: _seg(t, 0.86, 1.0, Curves.easeOut),
                    ),
                  ),
                ),
              ),

              // ۶) ذرات جشن هنگام فرود
              if (pBurst > 0)
                ..._particles.map((p) => _particleDot(p, mouth, pBurst, pOut)),

              // ۷) نشان «۱+» روی سبد
              if (pBadge > 0)
                Positioned(
                  left: basketTopCenter.dx - 34,
                  top: basketTopCenter.dy - 44 - 18 * pBadge.clamp(0.0, 1.0),
                  width: 68,
                  child: Opacity(
                    opacity: (1 - pOut).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: pBadge.clamp(0.0, 1.4),
                      child: const _PlusOneBadge(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // هاله‌های نبض‌دار دور قاب
  List<Widget> _halos(Offset c, double d, double p, double alive) {
    return List.generate(2, (i) {
      final local = ((p - i * 0.22)).clamp(0.0, 1.0);
      if (local <= 0) return const SizedBox.shrink();
      final size = d * (1 + 0.75 * local);
      return Positioned(
        left: c.dx - size / 2,
        top: c.dy - size / 2,
        width: size,
        height: size,
        child: Opacity(
          opacity: (1 - local) * 0.35 * alive,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColor.pitchGreenLight, width: 2),
            ),
          ),
        ),
      );
    });
  }

  Widget _ghost({
    required Offset pos,
    required double size,
    required double radius,
    required double opacity,
  }) {
    if (opacity <= 0.01) return const SizedBox.shrink();
    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - size / 2,
      width: size,
      height: size,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColor.pitchGreenLight,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }

  Widget _particleDot(_Particle p, Offset origin, double burst, double out) {
    final local = ((burst - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
    if (local <= 0) return const SizedBox.shrink();
    final eased = Curves.easeOutCubic.transform(local);
    final dx = math.cos(p.angle) * p.distance * eased;
    final dy = math.sin(p.angle) * p.distance * eased + 70 * local * local;
    final op = (1 - local) * (1 - out);
    return Positioned(
      left: origin.dx + dx - p.size,
      top: origin.dy + dy - p.size,
      width: p.size * 2,
      height: p.size * 2,
      child: Opacity(
        opacity: op.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: p.spin * local,
          child: CustomPaint(
            painter: _SparkPainter(star: p.star),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
    required this.spin,
    required this.star,
  });

  final double angle;
  final double distance;
  final double size;
  final double delay;
  final double spin;
  final bool star;
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter({required this.star});

  final bool star;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final paint = Paint()
      ..color = star ? AppColor.pitchGreenLight : AppColor.warning
      ..style = PaintingStyle.fill;
    if (!star) {
      canvas.drawCircle(c, r, paint);
      return;
    }
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final rad = i.isEven ? r : r * 0.42;
      final p = Offset(c.dx + math.cos(a) * rad, c.dy + math.sin(a) * rad);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.star != star;
}

/// قاب کالا: از مربعِ گوشه‌گرد به دایره تبدیل می‌شود و حلقه‌ی نوری دورش
/// کشیده می‌شود.
class _ProductBubble extends StatelessWidget {
  const _ProductBubble({
    required this.imageUrl,
    required this.radius,
    required this.ringProgress,
    required this.ringOpacity,
    required this.glow,
  });

  final String imageUrl;
  final double radius;
  final double ringProgress;
  final double ringOpacity;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColor.card,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: AppColor.pitchGreen.withOpacity(0.30 * glow),
                blurRadius: 34 * glow + 8,
                spreadRadius: 2 * glow,
                offset: Offset(0, 10 * glow + 4),
              ),
              BoxShadow(
                color: AppColor.ink.withOpacity(0.14),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.all(6 + 6 * glow),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: AppNetworkImage(url: imageUrl, fit: BoxFit.contain),
          ),
        ),
        if (ringProgress > 0 && ringOpacity > 0.01)
          Opacity(
            opacity: ringOpacity.clamp(0.0, 1.0),
            child: CustomPaint(painter: _RingPainter(progress: ringProgress)),
          ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final r = size.width / 2 - 1.5;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    const start = -math.pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.4
      ..shader = const SweepGradient(
        colors: [
          AppColor.pitchGreenLight,
          AppColor.pitchGreen,
          AppColor.pitchGreenLight,
        ],
        startAngle: 0,
        endAngle: math.pi * 2,
      ).createShader(Rect.fromCircle(center: center, radius: r));

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: r), start, sweep, false, paint);

    // نقطه‌ی نورانی سرِ کمان
    if (progress < 1) {
      final a = start + sweep;
      final head = Offset(center.dx + math.cos(a) * r, center.dy + math.sin(a) * r);
      canvas.drawCircle(
        head,
        4.2,
        Paint()..color = AppColor.pitchGreenLight,
      );
      canvas.drawCircle(
        head,
        8.5,
        Paint()..color = AppColor.pitchGreenLight.withOpacity(0.28),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

/// سبد خرید برداری با انیمیشن باز/بسته‌شدن دسته و جمع‌شدن هنگام دریافت کالا.
class _AnimatedBasket extends StatelessWidget {
  const _AnimatedBasket({
    required this.open,
    required this.land,
    required this.fill,
  });

  /// ۰..۱ — بالا رفتن دسته و باز شدن دهانه پیش از رسیدن کالا
  final double open;

  /// ۰..۱ — ضربه‌ی فرود (اسکواش/استرچ فنری)
  final double land;

  /// ۰..۱ — پر شدن سبد بعد از افتادن کالا
  final double fill;

  @override
  Widget build(BuildContext context) {
    // نوسان میرا برای حس فنری
    final osc = math.sin(land * math.pi * 3) * math.exp(-land * 3.2);
    final sx = 1 + 0.16 * osc;
    final sy = 1 - 0.13 * osc;

    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()..scale(sx, sy),
      child: CustomPaint(painter: _BasketPainter(open: open, fill: fill)),
    );
  }
}

class _BasketPainter extends CustomPainter {
  const _BasketPainter({required this.open, required this.fill});

  final double open;
  final double fill;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // سایه‌ی زیر سبد
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w / 2, h * 0.99), width: w * 0.72, height: h * 0.10),
      Paint()
        ..color = AppColor.ink.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final double rimY = h * 0.26;

    // ---- دسته‌ی سبد (پشت بدنه) ----
    final handlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round
      ..color = AppColor.pitchGreenDark;
    final handleLift = h * 0.06 * open;
    final handlePath = Path()
      ..moveTo(w * 0.26, rimY)
      ..quadraticBezierTo(w * 0.5, -h * 0.16 - handleLift, w * 0.74, rimY);
    canvas.drawPath(handlePath, handlePaint);

    // ---- داخل سبد (دهانه) ----
    final mouthRect = Rect.fromCenter(
      center: Offset(w / 2, rimY),
      width: w * 0.94,
      height: h * 0.20 * (1 + 0.10 * open),
    );
    canvas.drawOval(mouthRect, Paint()..color = const Color(0xFF0E3D22));

    // پر شدن سبد: یک بیضی روشن که بعد از افتادن کالا بالا می‌آید
    if (fill > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, rimY - mouthRect.height / 2, w, h));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w / 2, rimY + mouthRect.height * (0.55 - 0.45 * fill)),
          width: w * 0.74,
          height: h * 0.15,
        ),
        Paint()..color = AppColor.pitchGreenLight.withOpacity(0.85 * fill),
      );
      canvas.restore();
    }

    // ---- بدنه‌ی سبد ----
    final body = Path()
      ..moveTo(w * 0.03, rimY)
      ..lineTo(w * 0.97, rimY)
      ..lineTo(w * 0.845, h * 0.86)
      ..quadraticBezierTo(w * 0.83, h * 0.955, w * 0.735, h * 0.955)
      ..lineTo(w * 0.265, h * 0.955)
      ..quadraticBezierTo(w * 0.17, h * 0.955, w * 0.155, h * 0.86)
      ..close();

    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColor.pitchGreenLight, AppColor.pitchGreen],
        ).createShader(Rect.fromLTWH(0, rimY, w, h - rimY)),
    );

    // ---- بافت حصیری ----
    canvas.save();
    canvas.clipPath(body);
    final weave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.016
      ..color = Colors.white.withOpacity(0.20);
    for (int i = 1; i < 7; i++) {
      final f = i / 7;
      canvas.drawLine(
        Offset(lerpDouble(w * 0.03, w * 0.97, f)!, rimY),
        Offset(lerpDouble(w * 0.155, w * 0.845, f)!, h * 0.96),
        weave,
      );
    }
    for (int i = 1; i < 4; i++) {
      final y = lerpDouble(rimY, h * 0.95, i / 4)!;
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(w / 2, y + h * 0.035, w, y);
      canvas.drawPath(path, weave);
    }
    // برق ملایم سمت چپ
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.10, rimY + h * 0.06)
        ..quadraticBezierTo(w * 0.06, h * 0.55, w * 0.20, h * 0.90),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.05
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.16),
    );
    canvas.restore();

    // ---- لبه‌ی سبد ----
    final rimRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(w / 2, rimY), width: w, height: h * 0.115),
      Radius.circular(h * 0.06),
    );
    canvas.drawRRect(rimRect, Paint()..color = AppColor.pitchGreenDark);
    canvas.drawRRect(
      rimRect.deflate(h * 0.022),
      Paint()..color = Colors.white.withOpacity(0.14),
    );

    // دسته‌ی جلویی (روی لبه) تا حس عمق بدهد
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.26, rimY)
        ..quadraticBezierTo(w * 0.5, -h * 0.16 - handleLift, w * 0.74, rimY),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.022
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.22),
    );
  }

  @override
  bool shouldRepaint(covariant _BasketPainter old) =>
      old.open != open || old.fill != fill;
}

class _PlusOneBadge extends StatelessWidget {
  const _PlusOneBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: const ShapeDecoration(
          gradient: AppColor.greenGradient,
          shape: StadiumBorder(),
          shadows: AppColor.greenShadow,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 15, color: AppColor.onPitchGreen),
            SizedBox(width: 4),
            Text(
              '۱+',
              style: TextStyle(
                fontFamily: 'Estedad',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColor.onPitchGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
