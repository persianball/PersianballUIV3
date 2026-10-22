// ضربه روی پوش باید صفحه‌ی درست را باز کند؛ پوشِ وقتِ باز بودنِ اپ باید دیده شود.
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/core/push_navigation.dart';
import 'package:persian_ball/services/push_notification_service.dart';

void main() {
  group('مسیرِ پوش', () {
    String r(Map<String, dynamic> d) => PushNavigation.routeFor(d);

    test('route مستقیم', () {
      expect(r({'route': '/order/2097'}), '/order/2097');
      expect(r({'route': 'product/9/'}), '/product/9');
      expect(r({'route': '/cart'}), '/cart');
    });

    test('route نامعتبر به کلیدهای بعدی می‌رود', () {
      expect(r({'route': '/media/x.jpg', 'product_id': '9'}), '/product/9');
    });

    test('لینکِ کامل از هاستِ خودمان یا اسکیمِ اپ', () {
      expect(r({'link': 'https://pball.ah8ad3.ir/product/9'}), '/product/9');
      expect(r({'url': 'persianball://order/2097'}), '/order/2097');
    });

    test('لینکِ هاستِ غریبه نادیده گرفته می‌شود', () {
      expect(r({'link': 'https://evil.example/product/9'}), '/notifications');
    });

    test('شناسه‌ها', () {
      expect(r({'order_id': '2097'}), '/order/2097');
      expect(r({'product_id': 9}), '/product/9');
      expect(r({'course_id': '22'}), '/course/22');
      expect(r({'order_id': 'abc'}), '/notifications');
    });

    test('بدونِ مقصد → صندوقِ اعلان‌ها', () {
      expect(r({}), '/notifications');
    });
  });

  test('عنوان و متن از notification یا data', () {
    const withNotif = RemoteMessage(
        notification: RemoteNotification(title: 'سفارش ارسال شد', body: 'کد رهگیری'));
    expect(PushNavigation.titleOf(withNotif), 'سفارش ارسال شد');
    expect(PushNavigation.bodyOf(withNotif), 'کد رهگیری');

    const dataOnly = RemoteMessage(data: {'title': 'تخفیف', 'body': ' '});
    expect(PushNavigation.titleOf(dataOnly), 'تخفیف');
    expect(PushNavigation.bodyOf(dataOnly), isNull);
  });

  testWidgets('پوشِ وقتِ باز بودنِ اپ: اسنک‌بار با «مشاهده»', (t) async {
    final key = GlobalKey<ScaffoldMessengerState>();
    var opened = 0;
    await t.pumpWidget(MaterialApp(
      scaffoldMessengerKey: key,
      home: const Scaffold(body: SizedBox()),
    ));
    key.currentState!.showSnackBar(PushNavigation.foregroundSnackBar(
      const RemoteMessage(
          notification: RemoteNotification(title: 'سفارش ارسال شد', body: 'کد رهگیری ۱۲۳')),
      onOpen: () => opened++,
    ));
    await t.pumpAndSettle();
    expect(find.text('سفارش ارسال شد'), findsOneWidget);
    expect(find.text('کد رهگیری ۱۲۳'), findsOneWidget);
    await t.tap(find.text('مشاهده'));
    await t.pumpAndSettle();
    expect(opened, 1);
  });

  group('ضربه‌ی کلد استارت', () {
    test('قبل از گوش دادنِ اپ نگه داشته می‌شود', () {
      const m = RemoteMessage(data: {'route': '/order/1'});
      PushNotificationService.emitOpenedForTest(m);
      expect(PushNotificationService.takePendingOpened()?.data['route'], '/order/1');
      expect(PushNotificationService.takePendingOpened(), isNull);
    });

    test('وقتی اپ گوش می‌دهد مستقیم تحویل می‌شود', () async {
      final got = <RemoteMessage>[];
      final sub = PushNotificationService.onMessageOpened.listen(got.add);
      PushNotificationService.emitOpenedForTest(const RemoteMessage(data: {'order_id': '5'}));
      await Future<void>.delayed(Duration.zero);
      expect(got.single.data['order_id'], '5');
      expect(PushNotificationService.takePendingOpened(), isNull);
      await sub.cancel();
    });
  });
}
