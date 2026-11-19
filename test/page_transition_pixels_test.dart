// ترنزیشنِ صفحه با «عکسِ» صفحه نقاشی می‌شود. اینجا پیکسلِ واقعی خوانده
// می‌شود تا مطمئن شویم وسطِ راه هر دو صفحه با شفافیتِ درست دیده می‌شوند و در
// پایان فقط صفحه‌ی مقصد می‌ماند (نه صفحه‌ی سیاه، نه عکسِ جامانده).
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/core/fade_page_transitions.dart';

void main() {
  testWidgets('پیکسل‌ها: وسطِ راه ترکیبِ دو صفحه، پایان فقط مقصد', (tester) async {
    tester.view.physicalSize = const Size(200, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final boundary = GlobalKey();
    final nav = GlobalKey<NavigatorState>();
    Widget page(Color c) => Scaffold(
          backgroundColor: Colors.transparent,
          body: SizedBox.expand(child: ColoredBox(color: c)),
        );

    await tester.pumpWidget(RepaintBoundary(
      key: boundary,
      child: ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: MaterialApp(
          navigatorKey: nav,
          color: const Color(0xFFFFFFFF),
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.transparent,
            canvasColor: Colors.transparent,
            pageTransitionsTheme: PageTransitionsTheme(builders: {
              for (final p in TargetPlatform.values)
                p: const FadeThroughTopPageTransitionsBuilder(),
            }),
          ),
          home: page(const Color(0xFFFF0000)),
        ),
      ),
    ));

    Future<Color> centre() async {
      late ByteData data;
      await tester.runAsync(() async {
        final render = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final ui.Image img = await render.toImage();
        data = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        img.dispose();
      });
      final i = (200 * 200 + 100) * 4; // وسطِ صفحه
      return Color.fromARGB(data.getUint8(i + 3), data.getUint8(i),
          data.getUint8(i + 1), data.getUint8(i + 2));
    }

    int r(Color c) => (c.r * 255).round();
    int b(Color c) => (c.b * 255).round();

    var c = await centre();
    expect([r(c), b(c)], [255, 0], reason: 'شروع: فقط صفحه‌ی اول');

    nav.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => page(const Color(0xFF0000FF))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    c = await centre();
    // هر دو صفحه نیمه‌شفاف روی سفید: نه قرمزِ خالص، نه آبیِ خالص، نه سیاه
    expect(b(c), greaterThan(120), reason: 'صفحه‌ی تازه در حالِ پیدا شدن');
    expect(r(c), greaterThan(20), reason: 'صفحه‌ی قبلی هنوز کمی پیداست');
    expect(c.g * 255, greaterThan(5), reason: 'سفیدِ زیر دیده می‌شود، نه سیاه');

    await tester.pumpAndSettle();
    c = await centre();
    expect([r(c), (c.g * 255).round(), b(c)], [0, 0, 255],
        reason: 'پایان: فقط صفحه‌ی مقصد');

    nav.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 95));
    c = await centre();
    expect(r(c), greaterThan(20));
    expect(b(c), greaterThan(20));

    await tester.pumpAndSettle();
    c = await centre();
    expect([r(c), (c.g * 255).round(), b(c)], [255, 0, 0],
        reason: 'برگشت: صفحه‌ی اول کامل و زنده');
    expect(tester.takeException(), isNull);
  });
}
