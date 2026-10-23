// lib/services/order_service.dart
//
// سفارش‌های کاربر از بک‌اند واقعی:
//   GET /v2/order/order/        → لیست صفحه‌بندی‌شده (limit/offset، از قدیم به جدید)
//   GET /v2/order/order/<id>/   → جزئیات یک سفارش
//
// پیش‌تر صفحه‌ی سفارش‌ها از /v1/payment/payments/ می‌خواند که فقط
// {id, user, tracking_code, status, price} دارد — بدون اقلام و آدرس — و
// جزئیات از روی همان «ساخته» می‌شد. مهم‌تر اینکه شناسه‌ی پرداخت با شناسه‌ی
// سفارش یکی نیست (مثلاً پرداختِ ۱۹۸۲ متعلق به سفارشِ ۲۰۹۷ است)، پس نمی‌شد
// با شناسه‌ی پرداخت جزئیات سفارش را گرفت.
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:persian_ball/constant/urls.dart';
import 'package:persian_ball/models/order_models.dart';
import 'package:persian_ball/services/auth_service.dart';

class OrderService {
  OrderService._();

  static String get _base => URLs.baseUrl.endsWith('/')
      ? URLs.baseUrl.substring(0, URLs.baseUrl.length - 1)
      : URLs.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('نیاز به ورود');
    }
    return {
      'Authorization': 'token $token',
      'Accept': 'application/json',
    };
  }

  /// سرور در فیلد next آدرسِ http می‌دهد در حالی که خودش https است؛ روی وب
  /// این باعث بلاک شدنِ mixed-content می‌شود.
  static String _normalize(String url) =>
      url.startsWith('http://') ? url.replaceFirst('http://', 'https://') : url;

  /// اندازه‌ی هر صفحه‌ی لیست.
  static const int pageSize = 10;

  /// سفارش‌ها از جدید به قدیم.
  ///
  /// سرور لیست را از قدیم به جدید می‌دهد و پارامترِ ordering را نادیده
  /// می‌گیرد (فقط limit و offset دارد). پس صفحه‌ها از انتهای لیست خوانده
  /// می‌شوند: صفحه‌ی اول = آخرین [pageSize] سفارش، وارونه؛ [OrdersPageResult.next]
  /// به تکه‌ی قدیمی‌ترِ قبلی اشاره می‌کند. اگر کلِ سفارش‌ها در یک صفحه جا
  /// شوند، همان یک درخواست کافی است.
  static Future<OrdersPageResult> fetchOrders({String? nextUrl}) async {
    int offset;
    int limit;
    int count;
    if (nextUrl != null && nextUrl.isNotEmpty) {
      final q = Uri.parse(_normalize(nextUrl)).queryParameters;
      offset = int.tryParse(q['offset'] ?? '') ?? 0;
      limit = int.tryParse(q['limit'] ?? '') ?? pageSize;
      count = int.tryParse(q['count'] ?? '') ?? 0;
    } else {
      final head = await _page(limit: pageSize, offset: 0);
      if (head.count <= pageSize) {
        return OrdersPageResult(
            count: head.count, next: null, results: _newestFirst(head.results));
      }
      count = head.count;
      offset = count - pageSize;
      limit = pageSize;
    }

    final page = await _page(limit: limit, offset: offset);
    final olderOffset = offset - pageSize < 0 ? 0 : offset - pageSize;
    return OrdersPageResult(
      count: page.count > 0 ? page.count : count,
      next: offset > 0
          ? '$_list?limit=${offset - olderOffset}&offset=$olderOffset&count=$count'
          : null,
      results: _newestFirst(page.results),
    );
  }

  static String get _list => '$_base/v2/order/order/';

  static Future<OrdersPageResult> _page(
      {required int limit, required int offset}) async {
    final res = await http
        .get(Uri.parse('$_list?limit=$limit&offset=$offset'),
            headers: await _headers())
        .timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('خطا در دریافت سفارش‌ها (${res.statusCode})');
    }
    // سرور بدون charset پاسخ می‌دهد؛ با res.body متن فارسی خراب می‌شود.
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return OrdersPageResult.fromJson(data);
  }

  /// جدیدترین بالا: تاریخِ ثبت، و اگر نبود یا برابر بود شناسه.
  static List<Order> _newestFirst(List<Order> list) {
    final sorted = [...list];
    sorted.sort((a, b) {
      final ta = a.createdAt, tb = b.createdAt;
      if (ta != null && tb != null && ta != tb) return tb.compareTo(ta);
      return b.id.compareTo(a.id);
    });
    return sorted;
  }

  static Future<Order> fetchOrder(int id) async {
    final res = await http
        .get(Uri.parse('$_base/v2/order/order/$id/'), headers: await _headers())
        .timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('خطا در دریافت جزئیات سفارش (${res.statusCode})');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return Order.fromJson(data);
  }
}
