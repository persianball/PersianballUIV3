// lib/views/widgets/cart_drop_animation.dart
//
// انیمیشنِ «افتادن کالا داخل سبد»: وقتی کاربر در شیت پایین دکمه‌ی افزودن را
// می‌زند، تصویر کوچکِ کالا از داخل شیت جدا می‌شود و همراه با بسته‌شدن شیت،
// با قوسِ جاذبه داخل دکمه‌ی گرد سبد می‌افتد. هدف فقط یک چیز است: کاربر
// *ببیند* کالا کجا رفت.
//
// عمداً سبک است — بدون پرده‌ی تیره، بدون بلورِ تمام‌صفحه — چون فقط یک جسم
// کوچک روی صفحه حرکت می‌کند و باید روی گوشی‌های میان‌رده هم ۶۰ فریم بماند.
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/views/widgets/app_network_image.dart';

/// مدت افتادن کالا داخل سبد. عمداً کند است تا چشم مسیر را دنبال کند.
const Duration kCartDropDuration = Duration(milliseconds: 1250);

class CartDropAnimation {
  CartDropAnimation._();

  static OverlayEntry? _entry;

  static bool get isRunning => _entry != null;

  /// مستطیل سراسری یک ویجت از روی کلیدش (مبدأ/مقصدِ پرش).
  static Rect? rectOf(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// اجرای انیمیشن؛ [onLanded] دقیقاً وقتی صدا زده می‌شود که کالا به سبد
  /// می‌رسد، تا دکمه‌ی سبد همان لحظه «پر» شود.
  static void run(
    BuildContext context, {
    required String imageUrl,
    required Rect from,
    required Rect to,
    required VoidCallback onLanded,
  }) {
    if (_entry != null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      onLanded();
      return;
    }

    final entry = OverlayEntry(
      builder: (_) => _DropLayer(
        imageUrl: imageUrl,
        from: from,
        to: to,
        onLanded: () {
          cancel();
          onLanded();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  /// بستن فوری (مثلاً وقتی سرور افزودن را رد کرد).
  static void cancel() {
    _entry?.remove();
    _entry = null;
  }
}

class _DropLayer extends StatefulWidget {
  const _DropLayer({
    required this.imageUrl,
    required this.from,
    required this.to,
    required this.onLanded,
  });

  final String imageUrl;
  final Rect from;
  final Rect to;
  final VoidCallback onLanded;

  @override
  State<_DropLayer> createState() => _DropLayerState();
}

class _DropLayerState extends State<_DropLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: kCartDropDuration,
  )..forward().whenComplete(widget.onLanded);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _seg(double t, double a, double b, [Curve curve = Curves.linear]) =>
      curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final start = widget.from.center;
    final end = widget.to.center;

    // قوسِ پرتاب: کنترل‌پوینت بالای خطِ مبدأ→مقصد تا کالا اول کمی بالا
    // بپرد و بعد بیفتد؛ همان حسِ انداختن چیزی داخل سبد.
    final control = Offset(
      lerpDouble(start.dx, end.dx, 0.45)!,
      math.min(start.dy, end.dy) - 96,
    );

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;

          // بالا رفتن آرام تا اوج، بعد افتادن با شتاب.
          //
          // منحنی‌ها عمداً sine/quad هستند نه cubic: در این مدتِ طولانی‌تر،
          // cubic باعث می‌شد کالا وسط مسیر معلق بماند و ته مسیر یک‌دفعه شتاب
          // بگیرد. این‌ها همان حسِ پرتاب را می‌دهند ولی یکدست.
          const apex = 0.46;
          final travel = t < apex
              ? Curves.easeOutSine.transform(t / apex) * apex
              : apex +
                  Curves.easeInQuad.transform((t - apex) / (1 - apex)) *
                      (1 - apex);

          final u = 1 - travel;
          final pos = Offset(
            u * u * start.dx + 2 * u * travel * control.dx +
                travel * travel * end.dx,
            u * u * start.dy + 2 * u * travel * control.dy +
                travel * travel * end.dy,
          );

          // کوچک‌شدن در مسیر + جمع‌شدن نهایی داخل سبد
          final size = lerpDouble(widget.from.width, widget.to.width * 0.52,
                  Curves.easeInOutSine.transform(t))! *
              (1 - 0.55 * _seg(t, 0.84, 1.0, Curves.easeInOutSine));

          // چرخش کمتر از قبل: در حرکتِ کندتر، چرخشِ تند شلوغ به نظر می‌رسید.
          final spin = 0.55 * travel;
          final fade = 1 - _seg(t, 0.86, 1.0, Curves.easeInOutSine);

          return Stack(
            children: [
              // دنباله‌ی محو، تا مسیر افتادن خوانده شود
              for (int i = 3; i >= 1; i--)
                _ghost(start, control, end,
                    (travel - i * 0.07).clamp(0.0, 1.0), size * (1 - i * 0.10),
                    0.10 * (4 - i) / 3 * fade),

              Positioned(
                left: pos.dx - size / 2,
                top: pos.dy - size / 2,
                width: size,
                height: size,
                child: Opacity(
                  opacity: fade.clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: spin,
                    child: _Chip(imageUrl: widget.imageUrl),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ghost(Offset a, Offset c, Offset b, double t, double size,
      double opacity) {
    if (opacity <= 0.01 || t <= 0) return const SizedBox.shrink();
    final u = 1 - t;
    final p = Offset(
      u * u * a.dx + 2 * u * t * c.dx + t * t * b.dx,
      u * u * a.dy + 2 * u * t * c.dy + t * t * b.dy,
    );
    return Positioned(
      left: p.dx - size / 2,
      top: p.dy - size / 2,
      width: size,
      height: size,
      child: Opacity(
        opacity: opacity,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: AppColor.pitchGreenLight,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// خودِ کالای در حال افتادن: تصویر داخل یک قاب دایره‌ای سفید.
class _Chip extends StatelessWidget {
  const _Chip({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: AppColor.card,
        shape: const CircleBorder(
          side: BorderSide(color: AppColor.pitchGreenLight, width: 1.5),
        ),
        shadows: AppColor.greenShadow,
      ),
      child: ClipOval(
        child: AppNetworkImage(url: imageUrl, fit: BoxFit.cover),
      ),
    );
  }
}
