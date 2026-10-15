// lib/services/order_service.dart
//
// سفارش‌های کاربر از بک‌اند واقعی:
//   GET /v2/order/order/        → لیست صفحه‌بندی‌شده
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

  static Future<OrdersPageResult> fetchOrders({String? nextUrl}) async {
    final url = nextUrl != null && nextUrl.isNotEmpty
        ? _normalize(nextUrl)
        : '$_base/v2/order/order/';
    final res = await http
        .get(Uri.parse(url), headers: await _headers())
        .timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('خطا در دریافت سفارش‌ها (${res.statusCode})');
    }
    // سرور بدون charset پاسخ می‌دهد؛ با res.body متن فارسی خراب می‌شود.
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return OrdersPageResult.fromJson(data);
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
