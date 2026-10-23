// lib/utils/api_error.dart
//
// تبدیلِ پاسخِ خطای بک‌اند به متنِ خوانا. شکل‌های دیده‌شده:
//   {"code":"invalid_data","status":null,"messages":"Discount does not exist"}
//   {"code":["این مقدار نباید خالی باشد."]}            ← خطای فیلد
//   {"detail":"اطلاعات برای اعتبارسنجی ارسال نشده است."}
//   {"non_field_errors":["..."]}  /  {"message":"..."}
import 'dart:convert';

class ApiError {
  const ApiError({required this.status, required this.message, this.raw});

  final int status;

  /// متنِ خلاصه برای نمایش به کاربر
  final String message;

  /// بدنه‌ی خامِ کامل برای نمایشِ فنی تا پیش از انتشار
  final String? raw;

  bool get isHtml => _looksHtml(raw ?? '');

  static bool _looksHtml(String s) {
    final head = s.trimLeft();
    return head.startsWith('<!DOCTYPE') ||
        head.startsWith('<html') ||
        RegExp(r'<html[\s>]', caseSensitive: false).hasMatch(head.substring(0, head.length.clamp(0, 400)));
  }

  /// بدنه‌ی قابلِ نمایش: JSON با تورفتگی، HTML بدونِ script/style، بقیه عیناً
  String get prettyRaw {
    final r = raw ?? '';
    if (isHtml) return sanitizeHtml(r);
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(r));
    } catch (_) {
      return r;
    }
  }

  static String sanitizeHtml(String html) => html
      .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '');

  /// خلاصه‌ی صفحه‌ی خطای جنگو: عنوان + مقدارِ استثنا، اگر باشد.
  static String? htmlSummary(String html) {
    String clean(String v) => v
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#x27;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final title = RegExp(r'<title>([\s\S]*?)</title>', caseSensitive: false)
        .firstMatch(html)
        ?.group(1);
    final exc = RegExp(r'class="exception_value">([\s\S]*?)</pre>', caseSensitive: false)
        .firstMatch(html)
        ?.group(1);
    final parts = [
      if (title != null && clean(title).isNotEmpty) clean(title),
      if (exc != null && clean(exc).isNotEmpty) clean(exc),
    ];
    return parts.isEmpty ? null : parts.join('\n');
  }

  static const Map<String, String> _known = {
    'Discount does not exist': 'کد تخفیف وجود ندارد',
    'Discount expired': 'کد تخفیف منقضی شده است',
    'Discount already used': 'این کد قبلاً استفاده شده است',
    // POST /v2/order/order/ بدونِ آدرس
    'Address is empty': 'آدرسِ ارسال انتخاب نشده است',
  };

  static String _translate(String s) => _known[s.trim()] ?? s.trim();

  /// از بدنه‌ی پاسخ. هرگز خالی برنمی‌گرداند.
  factory ApiError.fromResponse(int status, String body) {
    final raw = body;
    if (_looksHtml(body)) {
      return ApiError(
        status: status,
        message: htmlSummary(body) ?? _statusText(status),
        raw: raw,
      );
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      decoded = null;
    }
    final parts = <String>[];
    void add(dynamic v, {String? field}) {
      if (v == null) return;
      if (v is String) {
        if (v.trim().isEmpty) return;
        parts.add(field == null ? _translate(v) : '$field: ${_translate(v)}');
      } else if (v is List) {
        for (final e in v) {
          add(e, field: field);
        }
      } else if (v is Map) {
        v.forEach((k, val) => add(val, field: k.toString()));
      } else {
        parts.add(v.toString());
      }
    }

    if (decoded is Map) {
      for (final k in ['messages', 'message', 'detail', 'error', 'non_field_errors']) {
        if (decoded.containsKey(k)) add(decoded[k]);
      }
      if (parts.isEmpty) {
        // خطاهای فیلد: {"code": ["…"]} — «code» اینجا نامِ فیلد است نه کدِ خطا
        decoded.forEach((k, v) {
          if (k == 'status') return;
          if (v is String && k == 'code' && decoded.length > 1) return;
          add(v, field: k.toString());
        });
      }
    } else if (decoded is List) {
      add(decoded);
    } else if (decoded is String) {
      add(decoded);
    }

    String message = parts.join('\n');
    if (message.isEmpty) message = _statusText(status);
    return ApiError(status: status, message: message, raw: raw);
  }

  static String _statusText(int s) {
    switch (s) {
      case 400:
        return 'درخواست نامعتبر بود';
      case 401:
        return 'برای این کار باید وارد حساب شوی';
      case 403:
        return 'دسترسی به این عملیات ممکن نیست';
      case 404:
        return 'یافت نشد';
      case 409:
        return 'تداخل با وضعیتِ فعلی';
      case 422:
        return 'اطلاعاتِ ارسالی پذیرفته نشد';
      case 429:
        return 'درخواست‌ها زیاد است؛ کمی بعد دوباره امتحان کن';
    }
    if (s >= 500) return 'خطای سرور ($s)';
    return 'خطای نامشخص ($s)';
  }

  @override
  String toString() => '$message (HTTP $status)';
}
