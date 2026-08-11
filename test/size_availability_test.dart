import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketky/views/widgets/selectable_circle_size.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('سایز ناموجود قابل انتخاب نیست و کال‌بک را صدا نمی‌زند',
      (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(_host(SelectableCircleSize(
      productSize: const ['39', '40', '41'],
      sizeAvailability: const [true, false, true],
      onSizeSelected: selected.add,
    )));

    await tester.tap(find.text('40'));
    await tester.pump();
    expect(selected, isEmpty);

    await tester.tap(find.text('41'));
    await tester.pump();
    expect(selected, [2]);
  });

  testWidgets('انتخاب اولیه روی اولین سایز موجود می‌افتد', (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(_host(SelectableCircleSize(
      productSize: const ['39', '40'],
      sizeAvailability: const [false, true],
      onSizeSelected: selected.add,
    )));

    // سایز ناموجود اول نباید انتخاب‌شده به نظر برسد
    await tester.tap(find.text('39'));
    await tester.pump();
    expect(selected, isEmpty);
  });

  testWidgets('بدون لیست موجودی، همه سایزها فعال‌اند', (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(_host(SelectableCircleSize(
      productSize: const ['39', '40'],
      onSizeSelected: selected.add,
    )));

    await tester.tap(find.text('39'));
    await tester.pump();
    await tester.tap(find.text('40'));
    await tester.pump();
    expect(selected, [0, 1]);
  });
}
