// نوار دسته‌بندی: بدون عدد تعداد، با یک نشانگرِ متحرک که بین دکمه‌ها
// جابه‌جا می‌شود (نه یک پس‌زمینه‌ی جداگانه برای هر دکمه).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/views/widgets/category_pill_bar.dart';

Widget _host(int selected, ValueChanged<int> onSelected) => MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: CategoryPillBar(
            labels: const ['همه', 'کفش', 'پوشاک'],
            selectedIndex: selected,
            onSelected: onSelected,
          ),
        ),
      ),
    );

void main() {
  testWidgets('برچسب‌ها بدون عدد تعداد رندر می‌شوند', (t) async {
    await t.pumpWidget(_host(0, (_) {}));
    await t.pumpAndSettle();
    expect(find.text('کفش'), findsOneWidget);
    expect(find.textContaining('('), findsNothing);
  });

  testWidgets('ضربه روی دسته، ایندکس آن را برمی‌گرداند', (t) async {
    int? tapped;
    await t.pumpWidget(_host(0, (i) => tapped = i));
    await t.pumpAndSettle();
    await t.tap(find.text('پوشاک'));
    expect(tapped, 2);
  });

  testWidgets('فقط یک نشانگر وجود دارد و با تغییر انتخاب جابه‌جا می‌شود',
      (t) async {
    await t.pumpWidget(_host(0, (_) {}));
    await t.pumpAndSettle();
    final indicator = find.byType(AnimatedPositioned);
    expect(indicator, findsOneWidget);
    final before = t.getTopLeft(indicator).dx;

    await t.pumpWidget(_host(2, (_) {}));
    await t.pumpAndSettle();
    expect(find.byType(AnimatedPositioned), findsOneWidget);
    expect(t.getTopLeft(find.byType(AnimatedPositioned)).dx,
        isNot(closeTo(before, 1)));
  });
}
