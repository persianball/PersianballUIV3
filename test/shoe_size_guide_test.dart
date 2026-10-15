import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/constant/shoe_size_chart.dart';
import 'package:persian_ball/views/widgets/shoe_size_guide.dart';

void main() {
  group('جدول', () {
    test('پای بین دو سایز به سایزِ بزرگ‌تر می‌رود', () {
      expect(ShoeSizeChart.forFoot(26)!.eu, 40);
      expect(ShoeSizeChart.forFoot(26.2)!.eu, 41);
      expect(ShoeSizeChart.forFoot(29)!.eu, 46);
      expect(ShoeSizeChart.forFoot(23)!.eu, 36);
      expect(ShoeSizeChart.forFoot(30), isNull);
    });

    test('فقط کفش راهنما دارد، نه توپِ سایز ۵', () {
      expect(
          ShoeSizeChart.appliesTo(
              categoryName: 'کفش', productName: 'کفش فلو', sizes: ['40', '41']),
          isTrue);
      expect(
          ShoeSizeChart.appliesTo(
              categoryName: 'توپ', productName: 'توپ فریستایل', sizes: ['5']),
          isFalse);
      // کفش ولی با سایزهایی بیرون از جدول
      expect(
          ShoeSizeChart.appliesTo(
              categoryName: 'کفش', productName: null, sizes: ['S', 'M']),
          isFalse);
    });
  });

  Future<void> pump(WidgetTester t, {String? selected, ValueChanged<String>? onPick}) async {
    t.view.physicalSize = const Size(420, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ShoeSizeGuide(
          availability: const {'40': true, '41': false, '42': true},
          selectedSize: selected,
          onPick: onPick,
        ),
      ),
    ));
  }

  testWidgets('از سایزِ فعلی شروع می‌کند و با ضربه روی ردیف پیشنهاد عوض می‌شود',
      (t) async {
    await pump(t, selected: '40', onPick: (_) {});
    expect(find.text('۴۰ EU'), findsOneWidget);
    expect(find.text('در این مدل موجود است'), findsOneWidget);
    expect(find.text('انتخاب شده'), findsOneWidget);

    // ردیفِ ۴۱ (ناموجود در این مدل)
    await t.tap(find.text('۲۶٫۵'));
    await t.pumpAndSettle();
    expect(find.text('۴۱ EU'), findsOneWidget);
    expect(find.text('در این مدل فعلاً ناموجود است'), findsOneWidget);
    expect(find.textContaining('انتخابِ سایزِ'), findsNothing);

    // ردیفِ ۴۴ (این مدل ندارد)
    await t.tap(find.text('۲۸'));
    await t.pumpAndSettle();
    expect(find.text('این مدل در این سایز تولید نمی‌شود'), findsOneWidget);
  });

  testWidgets('دکمه‌ی + طول را نیم سانت زیاد می‌کند و انتخاب را برمی‌گرداند',
      (t) async {
    String? picked;
    await pump(t, selected: '41', onPick: (s) => picked = s);
    // ۲۶٫۵ → ۲۷ یعنی سایزِ ۴۲
    await t.tap(find.bySemanticsLabel('زیاد کردن'));
    await t.pumpAndSettle();
    expect(find.text('۲۷ سانت'), findsOneWidget);
    await t.tap(find.text('انتخابِ سایزِ ۴۲'));
    await t.pumpAndSettle();
    expect(picked, '42');
  });
}
