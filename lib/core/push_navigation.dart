// lib/core/push_navigation.dart
//
// پوش → صفحه‌ی داخل اپ.
//
// قراردادِ دیتای پوش با بک‌اند (همه‌ی کلیدها اختیاری، به همین ترتیبِ اولویت):
//   route       مسیرِ داخلی، مثل "/order/2097" یا "/product/9"
//   link | url  لینکِ کامل، مثل "https://pball.ah8ad3.ir/product/9"
//               یا "persianball://order/2097"
//   order_id    → /order/<id>
//   product_id  → /product/<id>
//   course_id   → /course/<id>
// اگر هیچ‌کدام نبود یا مسیر جزو روت‌های اپ نبود، صندوقِ اعلان‌ها باز می‌شود؛
// چون هر پوش همراهِ یک پیام در صندوق است، کاربر دست‌خالی نمی‌ماند.
//
// عنوان و متن از بخشِ notification می‌آید و اگر نبود از data['title'] و
// data['body'] (پوش‌های data-only).
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:persian_ball/core/deep_link_resolver.dart';

class PushNavigation {
  PushNavigation._();

  static const String fallbackRoute = '/notifications';

  static String routeFor(Map<String, dynamic> data) {
    final route = data['route'];
    if (route is String) {
      final r = DeepLinkResolver.resolvePath(route);
      if (r != null) return r;
    }

    for (final key in const ['link', 'url']) {
      final v = data[key];
      if (v is String && v.trim().isNotEmpty) {
        final uri = Uri.tryParse(v.trim());
        final r = uri == null ? null : DeepLinkResolver.resolve(uri);
        if (r != null) return r;
      }
    }

    const ids = {
      'order_id': 'order',
      'product_id': 'product',
      'course_id': 'course',
    };
    for (final e in ids.entries) {
      final id = int.tryParse('${data[e.key] ?? ''}'.trim());
      if (id != null && id > 0) return '/${e.value}/$id';
    }

    return fallbackRoute;
  }

  static String? titleOf(RemoteMessage m) =>
      _nonEmpty(m.notification?.title) ?? _nonEmpty(m.data['title']);

  static String? bodyOf(RemoteMessage m) =>
      _nonEmpty(m.notification?.body) ?? _nonEmpty(m.data['body']);

  static String? _nonEmpty(Object? v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  /// پوشی که وقتِ باز بودنِ اپ می‌رسد: اندروید برایش نوتیفیکیشنِ سیستمی
  /// نشان نمی‌دهد، پس داخلِ اپ با یک اسنک‌بار دیده می‌شود.
  static SnackBar foregroundSnackBar(RemoteMessage m,
      {required VoidCallback onOpen}) {
    final title = titleOf(m) ?? 'پیام جدید';
    final body = bodyOf(m);
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 6),
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontFamily: 'Estedad', fontWeight: FontWeight.w700)),
            if (body != null)
              Text(body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Estedad', fontSize: 12)),
          ],
        ),
      ),
      action: SnackBarAction(label: 'مشاهده', onPressed: onOpen),
    );
  }
}
