// نشانِ تعدادِ دکمه‌ی سبد.
//
// باگِ قبلی: مقدارِ «در انتظار» به شمارنده‌ی سرور *اضافه* می‌شد تا دکمه
// فوراً پر دیده شود. ولی انیمیشنِ افتادنِ کالا داخل سبد چند صد میلی‌ثانیه
// طول می‌کشد و شمارنده‌ی واقعی معمولاً قبل از pop() می‌رسید؛ آن‌وقت یکی
// روی عددِ درست سوار می‌شد و نشان یکی بیشتر نشان می‌داد.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/views/widgets/cart_pop_button.dart';

void main() {
  final key = GlobalKey<CartPopButtonState>();

  Widget host(int count) => MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: CartPopButton(key: key, count: count, onTap: () {}),
            ),
          ),
        ),
      );

  testWidgets('سبدِ خالی: بعد از افزودن، نشان ۱ است نه ۲', (t) async {
    await t.pumpWidget(host(0));
    expect(find.text('۰'), findsNothing);

    // ترتیبِ واقعی: شمارنده‌ی سرور اول می‌رسد…
    await t.pumpWidget(host(1));
    // …و بعد انیمیشن فرود می‌آید و pop صدا زده می‌شود
    key.currentState!.pop();
    await t.pumpAndSettle();

    expect(find.text('۱'), findsOneWidget);
    expect(find.text('۲'), findsNothing);
  });

  testWidgets('ترتیبِ برعکس هم درست است (pop قبل از رسیدن شمارنده)',
      (t) async {
    await t.pumpWidget(host(0));
    key.currentState!.pop();
    await t.pump(const Duration(milliseconds: 100));
    // هنوز عددی از سرور نرسیده: نباید «۰» نشان داده شود
    expect(find.text('۰'), findsNothing);

    await t.pumpWidget(host(1));
    await t.pumpAndSettle();
    expect(find.text('۱'), findsOneWidget);
    expect(find.text('۲'), findsNothing);
  });

  testWidgets('افزودن دوم هم یکی جلو می‌رود، نه دو تا', (t) async {
    await t.pumpWidget(host(1));
    await t.pumpAndSettle();
    expect(find.text('۱'), findsOneWidget);

    await t.pumpWidget(host(2));
    key.currentState!.pop();
    await t.pumpAndSettle();
    expect(find.text('۲'), findsOneWidget);
    expect(find.text('۳'), findsNothing);
  });

  testWidgets('سبد خالی هیچ نشانی ندارد', (t) async {
    await t.pumpWidget(host(0));
    await t.pumpAndSettle();
    expect(find.text('۰'), findsNothing);
  });
}
