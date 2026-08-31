// lib/core/slider_link.dart
//
// مدیریت مقصدِ `click_url` اسلایدها:
//   • اگر لینک به سایت/هاست‌های خودِ اپ اشاره کند → ناوبری داخلی
//     (مثلاً https://persianball.ir/course/21 → روت /course/21)
//   • در غیر این صورت → باز شدن در مرورگر دستگاه
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SliderLink {
  SliderLink._();

  /// هاست‌هایی که لینکشان «ارجاع به آیتمی داخل اپ» تلقی می‌شود.
  static const Set<String> _inAppHosts = {
    'persianball.ir',
    'www.persianball.ir',
    'api2.persianball.ir',
    'pball.ah8ad3.ir',
    '2.144.27.195',
  };

  static bool hasTarget(String? clickUrl) =>
      clickUrl != null && clickUrl.trim().isNotEmpty;

  /// اجرای مقصدِ لینک. اگر لینک خالی باشد کاری نمی‌کند.
  static Future<void> open(BuildContext context, String? clickUrl) async {
    if (!hasTarget(clickUrl)) return;
    final uri = Uri.tryParse(clickUrl!.trim());
    if (uri == null) return;

    final route = _inAppRoute(uri);
    if (route != null) {
      Navigator.of(context).pushNamed(route);
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// اگر لینک به یک آیتمِ قابل‌ناوبری داخل اپ اشاره کند، روت داخلی را
  /// برمی‌گرداند؛ وگرنه null (یعنی باید در مرورگر باز شود).
  static String? _inAppRoute(Uri uri) {
    if (!_inAppHosts.contains(uri.host.toLowerCase())) return null;

    var path = uri.path;
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    final item = RegExp(r'^/(product|course)/(\d+)$').firstMatch(path);
    if (item != null) return '/${item.group(1)}/${item.group(2)}';

    switch (path) {
      case '/products':
      case '/product':
      case '/shop':
        return '/catalog';
      case '':
      case '/':
      case '/home':
        return '/home';
    }
    // هاستِ خودی ولی مسیرِ ناشناخته → بگذار در مرورگر باز شود.
    return null;
  }
}
