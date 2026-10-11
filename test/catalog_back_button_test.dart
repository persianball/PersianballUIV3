// صفحه‌ی فروشگاه دو جور باز می‌شود و فقط یکی‌اش راه برگشت دارد.
//
// باگِ قبلی: automaticallyImplyLeading همیشه false بود چون این صفحه یکی از
// تب‌های نوار پایین است. ولی از فیلترِ صفحه‌ی خانه، از سبدِ خالی و از
// دیپ‌لینک هم به‌صورت یک روتِ مستقل push می‌شود؛ آنجا کاربر بدون هیچ
// دکمه‌ی بازگشتی گیر می‌افتاد — در دسکتاپ که اپ‌بار هم نبود، بدتر.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketky/views/screens/catalog_page.dart';

void main() {
  Finder backButton() => find.byIcon(Icons.arrow_back_rounded);

  testWidgets('به‌عنوان تب (بدون پشته): دکمه‌ی بازگشت ندارد', (t) async {
    await t.pumpWidget(const MaterialApp(home: CatalogPage()));
    await t.pump();
    expect(backButton(), findsNothing);
  });

  testWidgets('وقتی push شده: دکمه‌ی بازگشت دارد', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CatalogPage()),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('go'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));

    expect(backButton(), findsOneWidget);
  });

  testWidgets('دکمه‌ی بازگشت واقعاً برمی‌گردد', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CatalogPage()),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('go'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('go'), findsNothing);

    await t.tap(backButton());
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('go'), findsOneWidget);
  });
}
