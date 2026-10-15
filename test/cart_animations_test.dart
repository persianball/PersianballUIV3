// انیمیشن‌های افزودن به سبد باید تا آخر و بدون خطا اجرا شوند.
//
// این تست‌ها ظاهر را نمی‌سنجند؛ چیزی را می‌گیرند که با اسکرین‌شات سخت دیده
// می‌شود: خطا در میانه‌ی انیمیشن، تمام‌نشدنِ کنترلر، یا نرسیدنِ onLanded.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/views/widgets/cart_drop_animation.dart';
import 'package:persian_ball/views/widgets/cart_pop_button.dart';

void main() {
  group('CartPopButton', () {
    testWidgets('انیمیشنِ پر شدن تا آخر بدون خطا اجرا می‌شود',
        (tester) async {
      final key = GlobalKey<CartPopButtonState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: CartPopButton(key: key, count: 0, onTap: () {}),
          ),
        ),
      ));

      key.currentState!.pop();

      // هر ۵۰ میلی‌ثانیه یک فریم، در کل بیش از مدت انیمیشن
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull,
            reason: 'فریم ${i + 1} انیمیشن خطا داد');
      }
      await tester.pumpAndSettle();
      expect(find.byType(CartPopButton), findsOneWidget);
    });

    test('مدت انیمیشن به‌قدری هست که چشم دنبالش کند', () {
      // اگر کسی دوباره سرعت را زیاد کرد، اینجا می‌شکند.
      expect(kCartPopDuration.inMilliseconds, greaterThanOrEqualTo(1000));
    });
  });

  group('CartDropAnimation', () {
    testWidgets('کالا می‌افتد و onLanded دقیقاً یک‌بار صدا زده می‌شود',
        (tester) async {
      var landed = 0;
      late BuildContext ctx;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (c) {
            ctx = c;
            return const SizedBox.expand();
          }),
        ),
      ));

      CartDropAnimation.run(
        ctx,
        imageUrl: '',
        from: const Rect.fromLTWH(100, 100, 56, 56),
        to: const Rect.fromLTWH(20, 700, 50, 50),
        onLanded: () => landed++,
      );

      await tester.pump();
      expect(CartDropAnimation.isRunning, isTrue);

      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull,
            reason: 'فریم ${i + 1} انیمیشن خطا داد');
      }

      expect(landed, 1, reason: 'onLanded باید دقیقاً یک‌بار اجرا شود');
      expect(CartDropAnimation.isRunning, isFalse,
          reason: 'اورلی باید بعد از فرود برداشته شود');
    });

    testWidgets('cancel وسط راه، انیمیشن را بدون صدا زدن onLanded می‌بندد',
        (tester) async {
      var landed = 0;
      late BuildContext ctx;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (c) {
            ctx = c;
            return const SizedBox.expand();
          }),
        ),
      ));

      CartDropAnimation.run(
        ctx,
        imageUrl: '',
        from: const Rect.fromLTWH(100, 100, 56, 56),
        to: const Rect.fromLTWH(20, 700, 50, 50),
        onLanded: () => landed++,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      CartDropAnimation.cancel();
      await tester.pump();

      expect(CartDropAnimation.isRunning, isFalse);
      expect(landed, 0, reason: 'افزودنِ ناموفق نباید «رسید» حساب شود');
      await tester.pumpAndSettle();
    });

    test('مدت افتادن به‌قدری هست که مسیر دیده شود', () {
      expect(kCartDropDuration.inMilliseconds, greaterThanOrEqualTo(1000));
    });
  });
}
