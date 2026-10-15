import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/views/widgets/app_buttons.dart';

void main() {
  testWidgets('trailingIcon در RTL سمتِ چپِ متن می‌نشیند', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: GradientButton(
            label: 'مشاهده دوره',
            expand: false,
            trailingIcon: const Icon(Icons.arrow_forward_rounded),
            onPressed: () {},
          ),
        ),
      ),
    ));
    final icon = tester.getCenter(find.byIcon(Icons.arrow_forward_rounded));
    final text = tester.getCenter(find.text('مشاهده دوره'));
    expect(icon.dx, lessThan(text.dx));
  });
}
