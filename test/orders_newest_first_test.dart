// سفارش‌ها از جدید به قدیم، با اینکه سرور از قدیم به جدید صفحه می‌دهد.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:persian_ball/services/order_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// سرورِ ساختگی مثلِ واقعی: limit/offset، از قدیم به جدید، ordering نادیده.
MockClient _server(int total, List<String> calls) => MockClient((req) async {
      calls.add(req.url.query);
      final limit = int.parse(req.url.queryParameters['limit'] ?? '10');
      final offset = int.parse(req.url.queryParameters['offset'] ?? '0');
      final all = [
        for (var i = 0; i < total; i++)
          {
            'id': 2100 + i,
            'created_at': DateTime(2026, 10, 1).add(Duration(hours: i)).toIso8601String(),
            'order_status': 'pending',
          }
      ];
      final page = all.skip(offset).take(limit).toList();
      return http.Response.bytes(
          utf8.encode(jsonEncode({
            'count': total,
            'next': offset + limit < total ? 'http://x/v2/order/order/?limit=$limit&offset=${offset + limit}' : null,
            'previous': null,
            'results': page,
          })),
          200);
    });

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'auth_token': 'tok'}));

  test('۲۴ سفارش: سه صفحه، جدیدترین اول، بدونِ تکرار یا جاافتادگی', () async {
    final calls = <String>[];
    final ids = <int>[];
    await http.runWithClient(() async {
      var page = await OrderService.fetchOrders();
      ids.addAll(page.results.map((o) => o.id));
      while (page.next != null) {
        page = await OrderService.fetchOrders(nextUrl: page.next);
        ids.addAll(page.results.map((o) => o.id));
      }
    }, () => _server(24, calls));
    expect(ids, [for (var i = 23; i >= 0; i--) 2100 + i]);
    expect(ids.first, 2123);
    // صفحه‌ی اول: یک درخواست برای count و یکی برای انتهای لیست
    expect(calls.take(2), ['limit=10&offset=0', 'limit=10&offset=14']);
  });

  test('کمتر از یک صفحه: یک درخواست، وارونه', () async {
    final calls = <String>[];
    final page = await http.runWithClient(() => OrderService.fetchOrders(), () => _server(3, calls));
    expect(page.results.map((o) => o.id), [2102, 2101, 2100]);
    expect(page.next, isNull);
    expect(calls, hasLength(1));
  });

  test('بدونِ سفارش', () async {
    final page = await http.runWithClient(() => OrderService.fetchOrders(), () => _server(0, []));
    expect(page.results, isEmpty);
    expect(page.next, isNull);
  });
}
