// تب‌های صفحه‌ی جزئیاتِ دوره («برنامه هفتگی» / «زمان و مکان برگزاری»)
// همان نوارِ دسته‌بندیِ فروشگاه را دارند: یک قرصِ سبزِ واحد که بین تب‌ها
// سُر می‌خورد، نه اینکه هر چیپ جداگانه رنگ عوض کند.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/views/widgets/detail_tabs.dart';

Widget _host() => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DetailTabs(tabs: [
            DetailTab(
                title: 'برنامه هفتگی',
                icon: Icons.calendar_month_rounded,
                builder: (_) => const Text('محتوای هفته‌ها')),
            DetailTab(
                title: 'زمان و مکان برگزاری',
                icon: Icons.place_rounded,
                builder: (_) => const Text('محتوای زمان و مکان')),
          ]),
        ),
      ),
    );

void main() {
  testWidgets('یک نشانگرِ واحد بینِ تب‌ها جابه‌جا می‌شود', (t) async {
    await t.pumpWidget(_host());
    await t.pumpAndSettle();
    final indicator = find.byType(AnimatedPositioned);
    expect(indicator, findsOneWidget);
    final before = t.getTopLeft(indicator).dx;

    await t.tap(find.text('زمان و مکان برگزاری'));
    await t.pumpAndSettle();

    expect(find.byType(AnimatedPositioned), findsOneWidget);
    expect(t.getTopLeft(find.byType(AnimatedPositioned)).dx,
        isNot(closeTo(before, 1)));
  });

  testWidgets('محتوای تبِ انتخاب‌شده نمایش داده می‌شود', (t) async {
    await t.pumpWidget(_host());
    await t.pumpAndSettle();
    expect(find.text('محتوای هفته‌ها'), findsOneWidget);
    await t.tap(find.text('زمان و مکان برگزاری'));
    await t.pumpAndSettle();
    expect(find.text('محتوای زمان و مکان'), findsOneWidget);
    expect(find.text('محتوای هفته‌ها'), findsNothing);
  });

  testWidgets('آیکنِ تب‌ها حفظ شده', (t) async {
    await t.pumpWidget(_host());
    await t.pumpAndSettle();
    expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
    expect(find.byIcon(Icons.place_rounded), findsOneWidget);
  });
}
