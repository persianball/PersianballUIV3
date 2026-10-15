// lib/views/widgets/locked_lessons_veil.dart
//
// پرده‌ی ویدیوهای قفل.
//
// پیش‌تر ویدیوهای قفل مثل بقیه‌ی ردیف‌ها با یک آیکنِ قفلِ کوچک نشان داده
// می‌شدند و فقط با ضربه یک اسنک‌بار می‌گفت «این ویدیو قفل است». حالا خودِ
// فهرست زیرِ یک تاری کامل دیده می‌شود: کاربر حجمِ محتوا را می‌بیند (چند
// جلسه، با کاور) ولی عنوان‌ها خوانا نیستند، و یک کارتِ شیشه‌ای وسطش راهِ
// باز کردن را نشان می‌دهد.
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/views/widgets/app_buttons.dart';

class LockedLessonsVeil extends StatelessWidget {
  const LockedLessonsVeil({
    super.key,
    required this.count,
    required this.child,
    this.onUnlock,
    this.message = 'با تهیه‌ی دوره، همه‌ی این جلسه‌ها باز می‌شوند',
  });

  /// تعداد ویدیوهای قفل زیرِ پرده
  final int count;

  /// خودِ ردیف‌های ویدیو؛ تار رسم می‌شوند و ضربه نمی‌گیرند
  final Widget child;

  /// باز کردنِ مسیرِ خرید. null یعنی فعلاً قابل خرید نیست.
  final VoidCallback? onUnlock;
  final String message;

  /// فقط چند ردیفِ اول تار نشان داده می‌شود، نه کلِ فهرست. یک گروهِ ۱۷
  /// جلسه‌ای ~۱۰۰۰ پیکسل تاری می‌ساخت و کارتِ قفل وسطش گم می‌شد؛ تعدادِ
  /// جلسه‌ها را خودِ کارت می‌گوید.
  static const double _previewMaxHeight = 260;

  static String _fa(int n) {
    const d = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    return n.toString().split('').map((c) {
      final i = c.codeUnitAt(0) - 48;
      return (i >= 0 && i <= 9) ? d[i] : c;
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // عنوان‌های تار نباید از راه صفحه‌خوان «لو» بروند
      excludeSemantics: true,
      button: onUnlock != null,
      label: '${_fa(count)} ویدیوی قفل. $message',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onUnlock,
        child: ClipRRect(
          borderRadius: AppShapes.radius(AppShapes.rLg),
          // ارتفاع = بلندترینِ «فهرستِ تار» و «کارتِ وسط». پیش‌تر کادر یک
          // حداقلِ ثابت داشت و کارت داخلش وسط‌چین و بریده می‌شد؛ روی گوشیِ
          // باریک با متنِ بزرگ‌شده، بالا و پایینِ کارت (و دکمه) از کادر بیرون
          // می‌زد و ناپدید می‌شد.
          // کارت بالای کادر است تا همان لحظه‌ای که تاری شروع می‌شود دیده
          // شود، نه وسطِ یک فهرستِ بلند.
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // ۱) چند ردیفِ اولِ محتوای واقعی، کاملاً تار
              IgnorePointer(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: _previewMaxHeight),
                  // اسکرول‌ویوِ غیرفعال فقط برای اینکه فهرستِ بلندتر بدونِ
                  // خطای سرریز بریده شود.
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: ImageFiltered(
                      // decal: لبه‌ها به سمتِ بیرون کشیده نمی‌شوند و قابِ
                      // تیره دورِ کادر نمی‌افتد
                      imageFilter: ImageFilter.blur(
                          sigmaX: 7, sigmaY: 7, tileMode: TileMode.decal),
                      child: child,
                    ),
                  ),
                ),
              ),
              // ۲) پرده‌ی شیری که پایینش غلیظ‌تر است تا کارت خوانا بماند
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColor.surfaceContainer.withValues(alpha: 0.30),
                        AppColor.surfaceContainer.withValues(alpha: 0.70),
                        AppColor.surfaceContainer.withValues(alpha: 0.96),
                      ],
                      stops: const [0, 0.6, 1],
                    ),
                  ),
                ),
              ),
              // ۳) کارتِ وسط — عمداً Positioned نیست تا خودش هم در ارتفاعِ
              // کادر سهم داشته باشد.
              Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _LockMedallion(),
                        const SizedBox(height: 12),
                        Text(
                          '${_fa(count)} ویدیو قفل است',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColor.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 11.5,
                            height: 1.7,
                            color: AppColor.onSurfaceVariant,
                          ),
                        ),
                        if (onUnlock != null) ...[
                          const SizedBox(height: 12),
                          GradientButton(
                            label: 'تهیه‌ی دوره',
                            icon: const Icon(Icons.lock_open_rounded),
                            expand: false,
                            height: 40,
                            fontSize: 13,
                            onPressed: onUnlock,
                          ),
                        ],
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// قفلِ وسطِ پرده با یک هاله‌ی تپنده‌ی آرام — نگاه را به سمت خودش می‌کشد
/// بدون اینکه شلوغ باشد. با «کاهشِ حرکت» ثابت می‌ماند.
class _LockMedallion extends StatefulWidget {
  const _LockMedallion();

  @override
  State<_LockMedallion> createState() => _LockMedallionState();
}

class _LockMedallionState extends State<_LockMedallion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = 52;
    return SizedBox(
      width: size + 24,
      height: size + 24,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_c.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              // هاله: بزرگ می‌شود و محو می‌شود
              Container(
                width: size + 24 * t,
                height: size + 24 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.pitchGreen.withValues(alpha: 0.22 * (1 - t)),
                ),
              ),
              child!,
            ],
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: const ShapeDecoration(
            gradient: AppColor.greenGradient,
            shape: CircleBorder(),
            shadows: AppColor.greenShadow,
          ),
          child: const Icon(Icons.lock_rounded,
              color: AppColor.onPitchGreen, size: 24),
        ),
      ),
    );
  }
}
