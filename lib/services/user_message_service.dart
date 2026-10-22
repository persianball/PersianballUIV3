// lib/services/user_message_service.dart
//
// صندوق پیام‌های درون‌اپ (در بک‌اند: Notification).
//
//   GET   /v1/user/messages/        → {count, next, previous, results:[…]}
//                                     پارامترهای صفحه‌بندی: limit / offset
//   PATCH /v1/user/messages/<id>/   → {seen_at: "<ISO>"}  ← علامتِ «خوانده شد»
//
// شمای هر پیام طبق OpenAPI سرور:
//   {id, text, created_at, seen_at, user}
// همه‌ی فیلدها جز seen_at فقط-خواندنی‌اند؛ یعنی تنها کاری که کلاینت می‌تواند
// روی یک پیام انجام دهد، ثبتِ زمانِ دیده‌شدن است. عنوانِ جدا وجود ندارد،
// پس هرجا عنوان لازم است از خطِ اولِ text ساخته می‌شود.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:persian_ball/constant/urls.dart';
import 'package:persian_ball/services/auth_service.dart';
import 'package:persian_ball/utils/jalali_date.dart';

class UserMessage {
  final int? id;
  final String text;
  final DateTime? createdAt;
  final DateTime? seenAt;
  final int? user;

  const UserMessage({
    this.id,
    required this.text,
    this.createdAt,
    this.seenAt,
    this.user,
  });

  factory UserMessage.fromJson(Map<String, dynamic> j) => UserMessage(
        id: j['id'] is int ? j['id'] as int : int.tryParse('${j['id']}'),
        text: (j['text'] as String?)?.trim() ?? '',
        createdAt: parseServerDate(j['created_at'] as String?),
        seenAt: parseServerDate(j['seen_at'] as String?),
        user: j['user'] is int ? j['user'] as int : int.tryParse('${j['user']}'),
      );

  /// خوانده‌شده = سرور برایش زمانِ دیده‌شدن ثبت کرده است.
  bool get isRead => seenAt != null;

  /// همان پیام با زمانِ دیده‌شدنِ جدید (برای به‌روزرسانیِ خوش‌بینانه‌ی لیست).
  UserMessage copyWithSeen(DateTime when) => UserMessage(
        id: id,
        text: text,
        createdAt: createdAt,
        seenAt: when,
        user: user,
      );

  /// خطِ اولِ متن به‌عنوان تیتر — سرور فیلد عنوان ندارد.
  String get displayTitle {
    if (text.isEmpty) return 'پیام';
    final firstLine = text.split('\n').first.trim();
    final head = firstLine.isEmpty ? text : firstLine;
    return head.length <= 48 ? head : '${head.substring(0, 48)}…';
  }

  /// اگر متن چندخطی/بلند باشد، ادامه‌اش زیر تیتر نشان داده می‌شود؛ وگرنه
  /// تیتر خودش کلِ پیام است و تکرارِ آن در ردیف بی‌معنی است.
  bool get hasMoreThanTitle => text.trim() != displayTitle;
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

  /// یک صفحه از پیام‌ها. [nextUrl] را از نتیجه‌ی قبلی بدهید تا صفحه‌بندی شود.
  ///
  /// در خطا استثنا پرتاب می‌کند تا صفحه بتواند «تلاش مجدد» نشان دهد؛
  /// برای مصرف‌کننده‌های بی‌صدا (مثل بج) [fetchOrNull] هست.
  static Future<UserMessagesPage> fetch({String? nextUrl, int? limit}) async {
    final headers = await _headers();
    final url = nextUrl != null && nextUrl.isNotEmpty
        ? _normalize(nextUrl)
        : '$_base/$_path${limit != null ? '?limit=$limit' : ''}';

    final res = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('نیاز به ورود');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('خطا در دریافت پیام‌ها (${res.statusCode})');
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
  }

  /// همان [fetch] ولی بدون استثنا — برای جاهایی که خطا نباید دیده شود.
  static Future<UserMessagesPage?> fetchOrNull({
    String? nextUrl,
    int? limit,
  }) async {
    try {
      return await fetch(nextUrl: nextUrl, limit: limit);
    } catch (_) {
      return null;
    }
  }

  /// ثبتِ «خوانده شد» با نوشتنِ زمانِ فعلی در seen_at.
  ///
  /// تنها فیلدِ نوشتنیِ سریالایزر همین است، پس PATCH با همین یک کلید کافی
  /// است. اگر ناموفق بود false برمی‌گرداند تا صفحه بتواند حالتِ خوش‌بینانه
  /// را برگرداند؛ استثنا پرتاب نمی‌کند چون باز کردنِ پیام نباید به خاطر
  /// این درخواستِ جانبی خطا نشان دهد.
  static Future<bool> markSeen(int id) async {
    try {
      final res = await http
          .patch(
            Uri.parse('$_base/$_path$id/'),
            headers: {
              ...await _headers(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'seen_at': DateTime.now().toUtc().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// «خواندن همه»: سرور endpointِ گروهی ندارد، پس برای هر پیام یک PATCH
  /// می‌رود. شناسه‌هایی را برمی‌گرداند که ثبت‌شان ناموفق بود.
  static Future<Set<int>> markAllSeen(Iterable<int> ids) async {
    final list = ids.toList();
    final results = await Future.wait(list.map(markSeen));
    return {
      for (var i = 0; i < list.length; i++)
        if (!results[i]) list[i],
    };
  }

  /// تعداد پیام‌های خوانده‌نشده — برای نشانِ روی آیکن پیام‌ها.
  ///
  /// سرور نه فیلترِ خوانده‌نشده دارد نه شمارنده‌ی جدا، پس ناچار باید خودِ
  /// پیام‌ها شمرده شوند. با limit بالا معمولاً همه‌ی صندوق در همین یک
  /// درخواست می‌آید؛ اگر بعداً اندپوینتی مثل unread_count اضافه شد،
  /// همین‌جا عوض شود.
  static Future<int> unreadCount() async {
    final page = await fetchOrNull(limit: 100);
    if (page == null) return 0;
    return page.results.where((m) => !m.isRead).length;
  }

  /// شمارنده را تازه می‌کند و به شنونده‌های [unreadNotifier] خبر می‌دهد.
  static Future<void> refreshUnread() async {
    final n = await unreadCount();
    if (unreadNotifier.value != n) unreadNotifier.value = n;
  }
}
