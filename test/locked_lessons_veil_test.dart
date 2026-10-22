// پرده‌ی ویدیوهای قفل روی برنامه‌ی هفتگیِ دوره.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/views/widgets/locked_lessons_veil.dart';

void main() {
  group('پرده‌ی ویدیوهای قفل', () {
    Widget host(Widget child) => MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        );

    testWidgets('تعداد را نشان می‌دهد و ضربه به خرید می‌رود', (t) async {
      var unlocks = 0;
      await t.pumpWidget(host(LockedLessonsVeil(
        count: 8,
        onUnlock: () => unlocks++,
        child: const SizedBox(height: 120),
      )));
      expect(find.text('۸ ویدیو قفل است'), findsOneWidget);
      await t.ensureVisible(find.text('تهیه‌ی دوره'));
      await t.pump();
      await t.tap(find.text('تهیه‌ی دوره'));
      expect(unlocks, 1);
    });

    testWidgets('ردیف‌های زیرِ پرده ضربه نمی‌گیرند', (t) async {
      var lessonTaps = 0, unlocks = 0;
      await t.pumpWidget(host(LockedLessonsVeil(
        count: 1,
        onUnlock: () => unlocks++,
        child: SizedBox(
          height: 220,
          child: Align(
            alignment: Alignment.topCenter,
            child: TextButton(
                onPressed: () => lessonTaps++, child: const Text('جلسه')),
          ),
        ),
      )));
      await t.tap(find.text('جلسه'), warnIfMissed: false);
      expect(lessonTaps, 0, reason: 'عنوانِ تار نباید قابلِ کلیک باشد');
      expect(unlocks, 1, reason: 'هر جای پرده مسیرِ خرید را باز می‌کند');
    });

    testWidgets('گوشیِ باریک با متنِ بزرگ: کارت بریده نمی‌شود', (t) async {
      t.view.physicalSize = const Size(320 * 3, 640 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      var unlocks = 0;
      await t.pumpWidget(MediaQuery(
        data: const MediaQueryData(
            size: Size(320, 640), textScaler: TextScaler.linear(1.4)),
        child: host(LockedLessonsVeil(
          count: 1,
          onUnlock: () => unlocks++,
          child: const SizedBox(height: 56), // یک ردیفِ تنها
        )),
      ));
      final veil = t.getRect(find.byType(LockedLessonsVeil));
      final button = t.getRect(find.text('تهیه‌ی دوره'));
      expect(veil.top <= button.top && button.bottom <= veil.bottom, isTrue,
          reason: 'دکمه باید کاملاً داخلِ کادر باشد، نه بریده');
      await t.ensureVisible(find.text('تهیه‌ی دوره'));
      await t.pump();
      await t.tap(find.text('تهیه‌ی دوره'));
      expect(unlocks, 1);
    });

    testWidgets('فهرستِ بلند فقط یک پیش‌نمایشِ کوتاه است و دکمه بالاست',
        (t) async {
      await t.pumpWidget(host(LockedLessonsVeil(
        count: 17,
        onUnlock: () {},
        child: Column(children: [
          for (int i = 0; i < 17; i++) const SizedBox(height: 60),
        ]),
      )));
      final veil = t.getRect(find.byType(LockedLessonsVeil));
      expect(veil.height, lessThan(400),
          reason: '۱۷ ردیف نباید ~۱۰۰۰ پیکسل تاری بسازد');
      final button = t.getRect(find.text('تهیه‌ی دوره'));
      expect(button.top - veil.top, lessThan(260),
          reason: 'دکمه باید بی‌اسکرول دیده شود، نه وسطِ فهرست');
    });

    testWidgets('بدونِ امکانِ خرید، دکمه نشان داده نمی‌شود', (t) async {
      await t.pumpWidget(host(const LockedLessonsVeil(
        count: 3,
        child: SizedBox(height: 120),
      )));
      expect(find.text('تهیه‌ی دوره'), findsNothing);
      expect(find.text('۳ ویدیو قفل است'), findsOneWidget);
    });
  });
}
