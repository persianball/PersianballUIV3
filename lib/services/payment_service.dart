// lib/services/payment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:marketky/constant/urls.dart';
import 'package:marketky/models/payment_models.dart';
import 'package:marketky/services/auth_service.dart';

class PaymentService {
  /// آدرس صفحه بعد را با scheme/host/port همان baseUrl می‌سازد تا اگر بک‌اند
  /// آدرس داخلی یا scheme متفاوتی برگرداند، درخواست به سرور درست برود.
  static Uri _resolveAgainstBase(String url) {
    final base = Uri.parse(URLs.baseUrl);
    final next = Uri.parse(url);
    return next.replace(
      scheme: base.scheme,
      host: base.host,
      port: base.port,
    );
  }

  static Future<PaymentsResponse> fetchPayments({String? nextPageUrl}) async {
    final token = await AuthService.getToken();

    final uri = nextPageUrl != null && nextPageUrl.isNotEmpty
        ? _resolveAgainstBase(nextPageUrl)
        : Uri.parse('${URLs.baseUrl}/v1/payment/payments/');

    final response = await http.get(
      uri,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'token $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return PaymentsResponse.fromJson(data);
    }

    throw Exception('خطا در دریافت سفارش‌ها (${response.statusCode})');
  }
}