// سایه‌ی کارت‌های اسکوئرکل باید با مستطیلِ گوشه‌گرد کشیده شود (مسیرِ سریعِ
// GPU)، ولی خودِ سطحِ کارت همچنان مسیرِ اسکوئرکل بماند.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/constant/app_shapes.dart';

void main() {
  Widget card() => Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Container(
            key: const ValueKey('card'),
            width: 200,
            height: 120,
            decoration: ShapeDecoration(
              color: AppColor.card,
              shape: AppShapes.border(AppShapes.rLg),
              shadows: AppColor.cardShadow,
            ),
          ),
        ),
      );

  // فلاتر در تست سایه‌ها را خاموش می‌کند (بدونِ maskFilter)؛ اینجا رفتارِ واقعیِ
  // اپ لازم است. باید پیش از پایانِ بدنه‌ی تست برگردانده شود.
  Future<void> withRealShadows(Future<void> Function() body) async {
    debugDisableShadows = false;
    try {
      await body();
    } finally {
      debugDisableShadows = true;
      SafeContinuousBorder.fastShadows = true;
    }
  }

  testWidgets('سایه‌ها rrect هستند و سطح مسیرِ اسکوئرکل', (tester) async {
    await withRealShadows(() async {
      await tester.pumpWidget(card());
      expect(
        find.byKey(const ValueKey('card')),
        paints
          ..rrect()
          ..rrect()
          ..path(color: AppColor.card),
      );
    });
  });

  testWidgets('با خاموش بودنِ مسیرِ سریع، سایه‌ها هم مسیر می‌شوند',
      (tester) async {
    await withRealShadows(() async {
      SafeContinuousBorder.fastShadows = false;
      await tester.pumpWidget(card());
      expect(find.byKey(const ValueKey('card')), isNot(paints..rrect()));
      expect(
          find.byKey(const ValueKey('card')), paints..path()..path()..path());
    });
  });
}
