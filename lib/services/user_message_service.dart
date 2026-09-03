// lib/services/user_message_service.dart
//
// صندوق پیام‌های درون‌اپ.
//
//   GET /v1/user/messages/   → {count, next, previous, results:[…]}
//
// ⚠️ در زمان نوشتن این کد صندوقِ حساب تست خالی بود (count: 0) و DRF برای
// متد GET شمای فیلدها را در OPTIONS برنمی‌گرداند، پس نام دقیقِ فیلدهای هر
// پیام از سرور قابل استخراج نبود. برای همین پارسر عمداً «تحمل‌پذیر» نوشته
// شده: چند نامِ رایج را امتحان می‌کند و هرچه پیدا نکرد خالی می‌ماند، تا با
// اولین پیام واقعی بدون کرش کار کند. وقتی یک نمونه‌ی واقعی موجود شد،
// [UserMessage.fromJson] باید دقیق شود.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:marketky/constant/urls.dart';
import 'package:marketky/services/auth_service.dart';

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

  static const String _path = 'v1/user/messages/';

  static String get _base => URLs.baseUrl.endsWith('/')
      ? URLs.baseUrl.substring(0, URLs.baseUrl.length - 1)
      : URLs.baseUrl;

  /// یک صفحه از پیام‌ها. [nextUrl] را از نتیجه‌ی قبلی بدهید تا صفحه‌بندی شود.
  static Future<UserMessagesPage> fetch({String? nextUrl}) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return UserMessagesPage.empty;

    final uri = Uri.parse(
        nextUrl != null && nextUrl.isNotEmpty ? nextUrl : '$_base/$_path');
    try {
      final res = await http.get(uri, headers: {
        'Authorization': 'token $token',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return UserMessagesPage.empty;
      }
      // سرور charset اعلام نمی‌کند؛ بدون utf8.decode متن فارسی خراب می‌شود.
      final data = jsonDecode(utf8.decode(res.bodyBytes));
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
    } catch (_) {
      return UserMessagesPage.empty;
    }
  }

  /// تعداد پیام‌های خوانده‌نشده — برای نشانِ روی آیکن پیام‌ها.
  static Future<int> unreadCount() async {
    final page = await fetch();
    return page.results.where((m) => !m.isRead).length;
  }
}
