// lib/services/rating_service.dart
//
// امتیاز و نظر محصول — متصل به APIهای واقعی v2/rating.
//
// خواندن: بک‌اند endpoint جداگانه‌ای برای گرفتن نظرها ندارد؛ میانگین امتیاز
// (`avg_rate`) و نظرهای *تأییدشده* (`comments`) داخل خود پاسخ
// GET /v2/product/product/<id>/ می‌آیند و صفحه‌ی محصول از همان‌ها استفاده
// می‌کند.
//
// نوشتن:
//   POST /v2/rating/comment/  {text, user, product}  → 201، با authorized:false
//                                                      یعنی منتظر تأیید ادمین
//   POST /v2/rating/rate/     {product, rating}      → ثبت امتیاز ۱ تا ۵
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:marketky/constant/urls.dart';
import 'package:marketky/services/auth_service.dart';

/// نتیجه‌ی ارسال امتیاز/نظر
class RatingResult {
  final bool success;

  /// برای نظر: true یعنی ثبت شد ولی هنوز تأیید نشده و در لیست دیده نمی‌شود
  final bool pendingApproval;
  final String message;

  const RatingResult({
    required this.success,
    required this.message,
    this.pendingApproval = false,
  });
}

class RatingService {
  static const String _rateEndpoint = '/v2/rating/rate/';
  static const String _commentEndpoint = '/v2/rating/comment/';
  static const String _userEndpoint = '/v1/user/';

  /// شناسه‌ی کاربر لاگین‌شده؛ سریالایزر نظر آن را لازم دارد.
  /// یک‌بار گرفته و تا پایان اجرای اپ نگه داشته می‌شود.
  static int? _cachedUserId;

  static Future<int?> currentUserId() async {
    if (_cachedUserId != null) return _cachedUserId;
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return null;
    final response = await http.get(
      Uri.parse('${URLs.baseUrl}$_userEndpoint'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) return null;
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is Map && body['id'] is int) {
      return _cachedUserId = body['id'] as int;
    }
    return null;
  }

  /// بعد از خروج از حساب باید پاک شود
  static void clearCache() => _cachedUserId = null;

  static Map<String, String> _headers(String token) => {
        'Authorization': 'token $token',
        'Content-Type': 'application/json',
      };

  /// ثبت امتیاز ۱ تا ۵ برای یک محصول
  static Future<RatingResult> rateProduct({
    required int productId,
    required int rating,
  }) async {
    assert(rating >= 1 && rating <= 5);
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return const RatingResult(
          success: false, message: 'برای ثبت امتیاز ابتدا وارد شوید');
    }
    try {
      final response = await http.post(
        Uri.parse('${URLs.baseUrl}$_rateEndpoint'),
        headers: _headers(token),
        body: utf8.encode(jsonEncode({'product': productId, 'rating': rating})),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return const RatingResult(success: true, message: 'امتیاز شما ثبت شد');
      }
      return RatingResult(success: false, message: errorMessageFor(response));
    } catch (_) {
      return const RatingResult(
          success: false, message: 'ارتباط با سرور برقرار نشد');
    }
  }

  /// ثبت نظر متنی برای یک محصول
  static Future<RatingResult> commentOnProduct({
    required int productId,
    required String text,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return const RatingResult(
          success: false, message: 'برای ثبت نظر ابتدا وارد شوید');
    }
    final userId = await currentUserId();
    if (userId == null) {
      return const RatingResult(
          success: false, message: 'دریافت اطلاعات کاربر ناموفق بود');
    }
    try {
      final response = await http.post(
        Uri.parse('${URLs.baseUrl}$_commentEndpoint'),
        headers: _headers(token),
        body: utf8.encode(jsonEncode({
          'text': text,
          'user': userId,
          'product': productId,
        })),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        // بک‌اند نظر را با authorized:false می‌سازد؛ تا تأیید ادمین در
        // لیست محصول دیده نمی‌شود و باید به کاربر گفته شود.
        final pending = body is Map && body['authorized'] != true;
        return RatingResult(
          success: true,
          pendingApproval: pending,
          message: pending
              ? 'نظر شما ثبت شد و پس از تأیید نمایش داده می‌شود'
              : 'نظر شما ثبت شد',
        );
      }
      return RatingResult(success: false, message: errorMessageFor(response));
    } catch (_) {
      return const RatingResult(
          success: false, message: 'ارتباط با سرور برقرار نشد');
    }
  }

  /// پیام خطای قابل‌نمایش از پاسخ سرور
  static String errorMessageFor(http.Response response) {
    if (response.statusCode >= 500) {
      return 'خطای سرور در ثبت امتیاز (${response.statusCode})';
    }
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map) {
        final detail = body['detail'] ?? body['message'];
        if (detail is String && detail.isNotEmpty) return detail;
        // خطاهای اعتبارسنجی DRF: {"field": ["پیام"]}
        final first = body.values.first;
        if (first is List && first.isNotEmpty) return '${first.first}';
        if (first is String && first.isNotEmpty) return first;
      }
    } catch (_) {
      // بدنه‌ی HTML (صفحه‌ی خطای جنگو) یا غیر JSON
    }
    return 'ثبت ناموفق بود (${response.statusCode})';
  }
}
