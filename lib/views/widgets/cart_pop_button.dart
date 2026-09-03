// lib/views/widgets/cart_pop_button.dart
//
// دکمه‌ی گردِ سبد با میکرو-انیمیشنِ «پر شدن» — دقیقاً مثل دکمه‌ی قلبِ
// علاقه‌مندی در اپ‌های نایکی: تا وقتی کالایی اضافه نشده، دایره‌ی سفید با
// آیکن خطی است؛ به‌محض افزودن، دکمه یک لحظه جمع می‌شود، بعد با فنر باز
// می‌شود، سبز پر می‌شود، آیکن توپر جای آیکن خطی را می‌گیرد، یک حلقه‌ی
// نازک از لبه‌اش بیرون می‌زند و شمارنده‌ی سبد روی گوشه‌اش می‌نشیند.
//
// حالت «پر» می‌ماند (مثل قلبِ قرمزی که قرمز می‌ماند) چون معنی‌اش این است
// که الان کالایی در سبد هست؛ لمس دکمه به صفحه‌ی سبد می‌رود.
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marketky/constant/app_color.dart';

/// مدت میکرو-انیمیشنِ «پر شدن» دکمه‌ی سبد.
const Duration kCartPopDuration = Duration(milliseconds: 1300);

class CartPopButton extends StatefulWidget {
  const CartPopButton({
    super.key,
    required this.count,
    required this.onTap,
    this.size = 50,
  });

  /// تعداد اقلام سبد؛ صفر یعنی حالت خالی (سفید، آیکن خطی).
  final int count;
  final VoidCallback? onTap;
  final double size;

  @override
  State<CartPopButton> createState() => CartPopButtonState();
}

class CartPopButtonState extends State<CartPopButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: kCartPopDuration,
  );

  /// تا وقتی سبد از سرور دوباره خوانده نشده، [widget.count] هنوز قدیمی است؛
  /// این مقدار موقتاً به آن اضافه می‌شود تا دکمه همان لحظه پر شود.
  int _pending = 0;

  /// اجرای انیمیشنِ «پر شدن». از بیرون (بعد از افزودن موفق) صدا زده می‌شود.
  void pop({int added = 1}) {
    HapticFeedback.lightImpact();
    setState(() => _pending = added);
    _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant CartPopButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // شمارنده‌ی واقعی رسید؛ افزایش موقت دیگر لازم نیست.
    if (oldWidget.count != widget.count) _pending = 0;
  }

  int get _count => widget.count + _pending;
  bool get _filled => _count > 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _seg(double t, double a, double b, [Curve curve = Curves.linear]) =>
      curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final running = _c.isAnimating;

        // ۱) فشرده‌شدن پیش از پرش (anticipation) و ۲) باز شدنِ آن.
        //
        // به‌جای elasticOut از easeOutBack استفاده می‌شود: در این سرعتِ
        // کمتر، لرزشِ چندباره‌ی elastic دیده می‌شد و ناآرام بود؛ یک اوج‌گیریِ
        // واحد نرم‌تر است و دقیقاً روی ۱ می‌نشیند.
        const pressEnd = 0.18;
        const releaseEnd = 0.72;
        final press = _seg(t, 0.0, pressEnd, Curves.easeInOutSine);
        final release = _seg(t, pressEnd, releaseEnd, Curves.easeOutBack);
        final double scale;
        if (!running) {
          scale = 1.0;
        } else if (t < pressEnd) {
          scale = lerpDouble(1.0, 0.82, press)!;
        } else {
          scale = lerpDouble(0.82, 1.0, release)!;
        }

        // ۳) حلقه‌ای که از لبه بیرون می‌زند و محو می‌شود
        final ring = _seg(t, 0.20, 0.86, Curves.easeOutSine);

        // ۴) نشانِ تعداد با فنر بالا می‌آید (اینجا فنر کوچک است و اذیت نمی‌کند)
        final badgeIn = _filled
            ? (running ? _seg(t, 0.46, 0.94, Curves.elasticOut) : 1.0)
            : 0.0;

        // ۵) رنگ: سفید → سبز؛ آیکن: خطی → توپر (با اسکیل)
        final fill = _filled
            ? (running ? _seg(t, 0.18, 0.56, Curves.easeInOutSine) : 1.0)
            : 0.0;
        final bg = Color.lerp(AppColor.card, AppColor.pitchGreen, fill)!;
        final iconColor = Color.lerp(AppColor.ink, AppColor.onPitchGreen, fill)!;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (ring > 0 && ring < 1)
                Transform.scale(
                  scale: 1 + 0.9 * ring,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColor.pitchGreenLight
                            .withOpacity((1 - ring) * 0.9),
                        width: 2.2 * (1 - ring) + 0.6,
                      ),
                    ),
                  ),
                ),
              Transform.scale(
                scale: scale,
                child: Material(
                  color: bg,
                  shape: const CircleBorder(),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  child: Ink(
                    decoration: ShapeDecoration(
                      color: bg,
                      // در حالت خالی، دکمه‌ی سفید روی نوار سفید گم می‌شد؛
                      // یک خط مویی لبه‌اش را نگه می‌دارد و با پر شدن محو می‌شود.
                      shape: CircleBorder(
                        side: BorderSide(
                          color: AppColor.line.withOpacity(1 - fill),
                          width: 1,
                        ),
                      ),
                      shadows: _filled ? AppColor.greenShadow : AppColor.cardShadow,
                    ),
                    child: InkWell(
                      onTap: widget.onTap,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: size,
                        height: size,
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // آیکن خطی محو می‌شود…
                              Opacity(
                                opacity: 1 - fill,
                                child: Icon(Icons.shopping_cart_outlined,
                                    size: size * 0.48, color: iconColor),
                              ),
                              // …و آیکن توپر با پرش جایش را می‌گیرد
                              Transform.scale(
                                scale: fill == 0
                                    ? 0
                                    : (running ? 0.6 + 0.4 * release : 1.0),
                                child: Opacity(
                                  opacity: fill,
                                  child: Icon(Icons.shopping_cart_rounded,
                                      size: size * 0.48, color: iconColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // نشان تعداد — بالا-چپ (سمت «انتهای» چیدمان RTL)
              if (badgeIn > 0)
                Positioned(
                  top: -4,
                  left: -4,
                  child: Transform.scale(
                    scale: math.max(0, badgeIn),
                    child: _CountBadge(count: _count),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: const ShapeDecoration(
        color: AppColor.danger,
        shape: StadiumBorder(side: BorderSide(color: AppColor.card, width: 2)),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '۹۹+' : _fa(count),
        style: const TextStyle(
          fontFamily: 'Estedad',
          fontSize: 10,
          height: 1.2,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  static String _fa(int n) {
    const d = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }
}
