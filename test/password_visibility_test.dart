import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/views/screens/account_security_page.dart';

/// وضعیت مخفی‌بودن فیلد رمزی که این لیبل را دارد
bool _obscured(WidgetTester tester, String label) {
  final field = tester.widget<TextField>(
    find.ancestor(of: find.text(label), matching: find.byType(TextField)),
  );
  return field.obscureText;
}

/// آیکن چشمِ همان فیلد
Finder _eyeOf(String label) => find.descendant(
      of: find.ancestor(
          of: find.text(label), matching: find.byType(TextField)),
      matching: find.byWidgetPredicate((w) =>
          w is Icon &&
          (w.icon == Icons.visibility_outlined ||
              w.icon == Icons.visibility_off_outlined)),
    );

void main() {
  const labels = ['رمز فعلی', 'رمز جدید', 'تکرار رمز جدید'];

  testWidgets('هر سه فیلد رمز، آیکن قفل و آیکن نمایش رمز دارند',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AccountSecurityPage()));

    expect(find.byIcon(Icons.lock_outline_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(3));

    for (final label in labels) {
      expect(_obscured(tester, label), isTrue,
          reason: 'فیلد «$label» باید در ابتدا مخفی باشد');
    }
  });

  testWidgets('زدن آیکن چشم فقط همان فیلد را نمایان می‌کند', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AccountSecurityPage()));

    await tester.tap(_eyeOf('رمز جدید'));
    await tester.pump();

    expect(_obscured(tester, 'رمز جدید'), isFalse);
    // بقیه‌ی فیلدها نباید تحت تأثیر قرار بگیرند
    expect(_obscured(tester, 'رمز فعلی'), isTrue);
    expect(_obscured(tester, 'تکرار رمز جدید'), isTrue);

    // آیکن هم باید به حالت «پنهان کردن» عوض شود
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));

    // زدن دوباره، دوباره مخفی می‌کند
    await tester.tap(_eyeOf('رمز جدید'));
    await tester.pump();
    expect(_obscured(tester, 'رمز جدید'), isTrue);
    expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(3));
  });

  testWidgets('آیکن قفل و آیکن چشم هم‌اندازه‌اند (۲۰)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AccountSecurityPage()));

    final icons = tester
        .widgetList<Icon>(find.byWidgetPredicate((w) =>
            w is Icon &&
            (w.icon == Icons.lock_outline_rounded ||
                w.icon == Icons.visibility_outlined)))
        .toList();

    expect(icons, hasLength(6));
    for (final icon in icons) {
      expect(icon.size, 20);
    }
  });
}
