// صفحه‌ی اعلان‌ها و نشانِ زنگوله از صندوق پیامِ واقعیِ سرور می‌خوانند.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:persian_ball/services/user_message_service.dart';
import 'package:persian_ball/views/screens/notification_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// سرورِ ساختگی: دو پیامِ خوانده‌نشده و یکی خوانده‌شده، و ثبتِ PATCHها.
class _FakeServer {
  final patched = <int>[];
  final List<Map<String, dynamic>> messages = [
    {'id': 1, 'text': 'سفارش شما ارسال شد\nکد رهگیری ۱۲۳', 'created_at': '2026-10-20T10:00:00+03:30', 'seen_at': null, 'user': 7},
    {'id': 2, 'text': 'تخفیف ویژه', 'created_at': '2026-10-21T10:00:00+03:30', 'seen_at': null, 'user': 7},
    {'id': 3, 'text': 'پیام قدیمی', 'created_at': '2026-10-01T10:00:00+03:30', 'seen_at': '2026-10-02T10:00:00+03:30', 'user': 7},
  ];

  MockClient get client => MockClient((req) async {
        if (!req.url.path.contains('/v1/user/messages/')) {
          return http.Response('not found', 404);
        }
        if (req.method == 'GET') {
          return http.Response.bytes(
            utf8.encode(jsonEncode({'count': messages.length, 'next': null, 'previous': null, 'results': messages})),
            200,
          );
        }
        if (req.method == 'PATCH') {
          final id = int.parse(req.url.pathSegments.where((s) => s.isNotEmpty).last);
          patched.add(id);
          return http.Response('{}', 200);
        }
        return http.Response('', 405);
      });
}

Widget _app() => const MaterialApp(home: NotificationPage());

void main() {
  setUp(() => UserMessageService.unreadNotifier.value = 0);

  testWidgets('مهمان: به‌جای اعلان، دعوت به ورود نشان داده می‌شود', (t) async {
    SharedPreferences.setMockInitialValues({});
    final server = _FakeServer();
    await http.runWithClient(() async {
      await t.pumpWidget(_app());
      await t.pumpAndSettle();
    }, () => server.client);
    expect(find.text('وارد حساب کاربری نشده‌اید'), findsOneWidget);
    expect(find.text('ورود به حساب کاربری'), findsOneWidget);
    expect(find.text('خواندن همه'), findsNothing);
  });

  testWidgets('پیام‌های سرور نشان داده می‌شوند و نشانِ زنگوله درست است', (t) async {
    SharedPreferences.setMockInitialValues({'auth_token': 'tok'});
    final server = _FakeServer();
    await http.runWithClient(() async {
      await t.pumpWidget(_app());
      await t.pumpAndSettle();
    }, () => server.client);
    expect(find.text('سفارش شما ارسال شد'), findsOneWidget);
    expect(find.text('کد رهگیری ۱۲۳'), findsOneWidget);
    expect(find.text('تخفیف ویژه'), findsOneWidget);
    expect(find.text('پیام قدیمی'), findsOneWidget);
    expect(find.byKey(const ValueKey('unread-dot')), findsNWidgets(2));
    expect(UserMessageService.unreadNotifier.value, 2);
    expect(find.textContaining('نمایشی'), findsNothing);
  });

  testWidgets('«خواندن همه» برای هر پیامِ خوانده‌نشده PATCH می‌فرستد', (t) async {
    SharedPreferences.setMockInitialValues({'auth_token': 'tok'});
    final server = _FakeServer();
    await http.runWithClient(() async {
      await t.pumpWidget(_app());
      await t.pumpAndSettle();
      await t.tap(find.text('خواندن همه'));
      await t.pumpAndSettle();
    }, () => server.client);
    expect(server.patched.toSet(), {1, 2});
    expect(find.byKey(const ValueKey('unread-dot')), findsNothing);
    expect(UserMessageService.unreadNotifier.value, 0);
    expect(find.text('خواندن همه'), findsNothing);
  });

  testWidgets('باز کردنِ یک پیام آن را روی سرور خوانده‌شده می‌کند', (t) async {
    SharedPreferences.setMockInitialValues({'auth_token': 'tok'});
    final server = _FakeServer();
    await http.runWithClient(() async {
      await t.pumpWidget(_app());
      await t.pumpAndSettle();
      await t.tap(find.text('تخفیف ویژه'));
      await t.pumpAndSettle();
    }, () => server.client);
    expect(server.patched, [2]);
    expect(UserMessageService.unreadNotifier.value, 1);
  });
}
