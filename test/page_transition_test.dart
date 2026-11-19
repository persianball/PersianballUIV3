// ترنزیشنِ صفحه با «عکسِ» صفحه کار می‌کند؛ اینجا فقط رفتار بررسی می‌شود:
// رفت و برگشت بدونِ خطا، صفحه‌ی زیری بعد از برگشت دوباره زنده و لمس‌پذیر.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/core/fade_page_transitions.dart';

void main() {
  testWidgets('رفت و برگشت: هر دو صفحه درست نشان داده می‌شوند', (tester) async {
    int taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: PageTransitionsTheme(builders: {
          for (final p in TargetPlatform.values)
            p: const FadeThroughTopPageTransitionsBuilder(),
        }),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () {
                taps++;
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('detail')),
                ));
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pump();
    // وسطِ ترنزیشن: هر دو صفحه در درخت‌اند
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('detail'), findsOneWidget);
    expect(find.text('open'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('detail'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    await tester.pumpAndSettle();
    expect(find.text('detail'), findsNothing);

    // صفحه‌ی اول دوباره زنده است و لمس می‌گیرد
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(taps, 2);
    expect(find.text('detail'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('مدتِ ترنزیشن کوتاه‌تر از پیش‌فرضِ متریال است', () {
    const b = FadeThroughTopPageTransitionsBuilder();
    expect(b.transitionDuration, lessThan(const Duration(milliseconds: 300)));
    expect(b.reverseTransitionDuration, lessThanOrEqualTo(b.transitionDuration));
  });
}
