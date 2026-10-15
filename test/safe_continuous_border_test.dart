// خطِ عمودیِ اضافه روی دکمه‌های کوتاهِ خط‌دار (مثل «انتخاب شد» در زمان و
// مکانِ دوره). ContinuousRectangleBorder ـِ فلاتر شعاع را فقط به کلِ ضلعِ
// کوتاه محدود می‌کند؛ روی کادرِ کوتاه منحنی‌های بالا و پایین از هم رد
// می‌شوند و مسیر از کادر بیرون می‌زند.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/constant/app_shapes.dart';

void main() {
  // همان ابعادِ دکمه‌ی «انتخاب شد»: عریض و کوتاه، با شعاعِ rLg
  const rect = Rect.fromLTWH(0, 0, 300, 38);

  test('مسیر روی کادرِ کوتاه با شعاعِ بزرگ، به لبه‌ها نمی‌چسبد', () {
    final border = AppShapes.border(AppShapes.rLg,
        side: const BorderSide(color: Colors.green));
    final path = border.getOuterPath(rect);
    // با شعاعِ محدودشده، گوشه‌ها گردند: نقطه‌ی کنجِ کادر داخلِ شکل نیست
    expect(path.contains(const Offset(0.5, 0.5)), isFalse);
    expect(path.contains(const Offset(299.5, 37.5)), isFalse);
    // و وسطِ لبه‌ی چپ، روی خودِ شکل است (لبه صاف و پیوسته)
    expect(path.contains(const Offset(1, 19)), isTrue);
  });

  test('ویجتِ بلند هیچ تغییری نمی‌کند', () {
    const tall = Rect.fromLTWH(0, 0, 300, 400);
    final safe = AppShapes.border(AppShapes.rLg).getOuterPath(tall);
    final raw = ContinuousRectangleBorder(
            borderRadius: AppShapes.radius(AppShapes.rLg))
        .getOuterPath(tall);
    for (final p in const [Offset(2, 2), Offset(20, 3), Offset(150, 200)]) {
      expect(safe.contains(p), raw.contains(p));
    }
  });

  test('در میانه‌ی انیمیشن هم نوعِ امن حفظ می‌شود', () {
    final a = AppShapes.border(AppShapes.rLg);
    final b = AppShapes.border(AppShapes.rLg,
        side: const BorderSide(color: Colors.green, width: 2));
    final mid = ShapeBorder.lerp(a, b, 0.5);
    expect(mid, isA<SafeContinuousBorder>());
    expect(a.scale(0.5), isA<SafeContinuousBorder>());
    expect(a.copyWith(side: const BorderSide()), isA<SafeContinuousBorder>());
  });
}
