// lib/services/user_message_service.dart
//
// صندوق پیام‌های درون‌اپ.
//
//   GET /v1/user/message/   → {count, next, previous, results:[…]}
//
// ⚠️ در زمان نوشتن این کد صندوقِ حساب تست خالی بود (count: 0) و DRF برای
// متد GET شمای فیلدها را در OPTIONS برنمی‌گرداند، پس نام دقیقِ فیلدهای هر
// پیام از سرور قابل استخراج نبود. برای همین پارسر عمداً «تحمل‌پذیر» نوشته
// شده: چند نامِ رایج را امتحان می‌کند و هرچه پیدا نکرد خالی می‌ماند، تا با
// اولین پیام واقعی بدون کرش کار کند. وقتی یک نمونه‌ی واقعی موجود شد،
// [UserMessage.fromJson] باید دقیق شود.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:marketky/constant/urls.dart';
import 'package:marketky/services/auth_service.dart';
import 'package:marketky/utils/jalali_date.dart';

class UserMessage {
  final int? id;
  final String title;
  final String body;
  final String createdAt;
  final bool isRead;

  const UserMessage({
    this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
  });

  static String _pick(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is num) return '$v';
    }
    return '';
  }

  factory UserMessage.fromJson(Map<String, dynamic> j) {
    final read = j['is_read'] ?? j['is_readed'] ?? j['read'] ?? j['seen'];
    return UserMessage(
      id: j['id'] is int ? j['id'] as int : int.tryParse('${j['id']}'),
      title: _pick(j, ['title', 'subject', 'header', 'name']),
      body: _pick(j, ['body', 'message', 'text', 'content', 'description']),
      createdAt: _pick(j, ['created_at', 'created', 'date', 'timestamp']),
      isRead: read == true,
    );
  }

  /// عنوانِ قابل نمایش؛ اگر سرور عنوان نداده باشد از متن ساخته می‌شود.
  String get displayTitle {
    if (title.isNotEmpty) return title;
    if (body.isEmpty) return 'پیام';
    return body.length <= 40 ? body : '${body.substring(0, 40)}…';
  }

  /// تاریخِ سرور با حفظِ منطقه‌ی زمانیِ خودش؛ اگر قابل خواندن نبود null.
  DateTime? get createdAtDate => parseServerDate(createdAt);
}

class UserMessagesPage {
  final int count;
  final String? next;
  final List<UserMessage> results;

  const UserMessagesPage({
    required this.count,
    required this.next,
    required this.results,
  });

  static const empty = UserMessagesPage(count: 0, next: null, results: []);
}

class UserMessageService {
  UserMessageService._();

  static const String _path = 'v1/user/message/';

  /// تعداد پیام‌های خوانده‌نشده برای بجِ نوار بالای صفحه‌ی خانه.
  ///
  /// نوار بالا داخل آیتم‌های کاروسل ساخته می‌شود و مدام دوباره build می‌شود؛
  /// اگر هر build یک درخواست می‌فرستاد، صفحه‌ی خانه ده‌ها بار به سرور می‌زد.
  /// این نوتیفایر مقدار را نگه می‌دارد و [refreshUnread] فقط وقتی واقعاً
  /// لازم است (باز شدن خانه، تغییر وضعیت ورود، بازگشت از صندوق) صدا زده
  /// می‌شود.
  static final ValueNotifier<int> unreadNotifier = ValueNotifier<int>(0);

  static String get _base => URLs.baseUrl.endsWith('/')
      ? URLs.baseUrl.substring(0, URLs.baseUrl.length - 1)
      : URLs.baseUrl;

  /// سرور در فیلد next آدرسِ http می‌دهد در حالی که خودش https است؛ روی وب
  /// این باعث بلاک شدنِ mixed-content می‌شود.
  static String _normalize(String url) =>
      url.startsWith('http://') ? url.replaceFirst('http://', 'https://') : url;

  /// یک صفحه از پیام‌ها. [nextUrl] را از نتیجه‌ی قبلی بدهید تا صفحه‌بندی شود.
  ///
  /// در خطا استثنا پرتاب می‌کند تا صفحه بتواند «تلاش مجدد» نشان دهد؛
  /// برای مصرف‌کننده‌های بی‌صدا (مثل بج) [fetchOrNull] هست.
  static Future<UserMessagesPage> fetch({String? nextUrl}) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('نیاز به ورود');
    }

    final url = nextUrl != null && nextUrl.isNotEmpty
        ? _normalize(nextUrl)
        : '$_base/$_path';
    final res = await http.get(Uri.parse(url), headers: {
      'Authorization': 'token $token',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 20));

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('نیاز به ورود');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('خطا در دریافت پیام‌ها (${res.statusCode})');
    }

    // سرور charset اعلام نمی‌کند؛ بدون utf8.decode متن فارسی خراب می‌شود.
    final data = jsonDecode(utf8.decode(res.bodyBytes));

    // برخی اندپوینت‌های همین بک‌اند بدون صفحه‌بندی و به شکل آرایه پاسخ
    // می‌دهند؛ هر دو حالت پذیرفته می‌شود.
    if (data is List) {
      final results = <UserMessage>[
        for (final r in data)
          if (r is Map<String, dynamic>) UserMessage.fromJson(r)
      ];
      return UserMessagesPage(
          count: results.length, next: null, results: results);
    }
    if (data is! Map<String, dynamic>) return UserMessagesPage.empty;

    final results = <UserMessage>[];
    for (final r in (data['results'] as List? ?? const [])) {
      if (r is Map<String, dynamic>) results.add(UserMessage.fromJson(r));
    }
    return UserMessagesPage(
      count: data['count'] is int ? data['count'] as int : results.length,
      next: data['next'] as String?,
      results: results,
    );
  }

  /// همان [fetch] ولی بدون استثنا — برای جاهایی که خطا نباید دیده شود.
  static Future<UserMessagesPage?> fetchOrNull({String? nextUrl}) async {
    try {
      return await fetch(nextUrl: nextUrl);
    } catch (_) {
      return null;
    }
  }

  /// تعداد پیام‌های خوانده‌نشده — برای نشانِ روی آیکن پیام‌ها.
  ///
  /// فقط صفحه‌ی اول شمرده می‌شود: سرور شمارنده‌ی جداگانه‌ای برای
  /// خوانده‌نشده‌ها ندارد و پیمایشِ همه‌ی صفحه‌ها برای یک بجِ کوچک
  /// نمی‌ارزد. اگر بعداً فیلدی مثل unread_count اضافه شد، همین‌جا عوض شود.
  static Future<int> unreadCount() async {
    final page = await fetchOrNull();
    if (page == null) return 0;
    return page.results.where((m) => !m.isRead).length;
  }

  /// شمارنده را تازه می‌کند و به شنونده‌های [unreadNotifier] خبر می‌دهد.
  static Future<void> refreshUnread() async {
    final n = await unreadCount();
    if (unreadNotifier.value != n) unreadNotifier.value = n;
  }
}
