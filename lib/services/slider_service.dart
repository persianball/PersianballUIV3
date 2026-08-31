import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:marketky/models/slider_item.dart';

/// دریافت اسلایدهای گالری از بک‌اند، با پیمایشِ کاملِ صفحه‌بندی و کشِ کوتاه‌مدت.
///
/// بک‌اند برای هر صفحه یک «دسته» جدا دارد و فیلتر سمتِ سرور با
/// `?category=<num>` انجام می‌شود (نه سمتِ کلاینت):
///   ۱ app_home_page  ۲ app_academy_page  ۴ site_academy_page
///   ۵ site_main_home_page
/// نگاشتِ صفحه/اندازه‌ی نمایشگر به این اعداد در [SliderCategory] است.
class SliderService {
  SliderService._();

  /// سرورِ گالری (جدا از baseUrl اصلی اپ).
  static const String host = 'http://2.144.27.195:8000';
  static const String _endpoint = '$host/v1/gallery/slider/';

  static const Duration _ttl = Duration(minutes: 5);

  /// کش و درخواستِ در جریان، به تفکیکِ دسته.
  static final Map<int, List<SliderItem>> _cache = {};
  static final Map<int, DateTime> _cacheAt = {};
  static final Map<int, Future<List<SliderItem>>> _inFlight = {};

  static bool _fresh(int category) {
    final at = _cacheAt[category];
    return _cache.containsKey(category) &&
        at != null &&
        DateTime.now().difference(at) < _ttl;
  }

  /// اسلایدهای یک دسته، مرتب‌شده بر اساس `sorting_order`.
  static Future<List<SliderItem>> fetchCategory(
    int category, {
    bool forceRefresh = false,
  }) {
    if (!forceRefresh && _fresh(category)) {
      return Future.value(_cache[category]!);
    }
    return _inFlight[category] ??= _load(category)
        .whenComplete(() => _inFlight.remove(category));
  }

  /// اسلایدهای یک صفحه؛ نسخه‌ی `site_…` یا `app_…` بر اساس اندازه‌ی نمایشگر.
  static Future<List<SliderItem>> forPage(
    SliderPage page, {
    required bool desktop,
    bool forceRefresh = false,
  }) =>
      fetchCategory(SliderCategory.of(page, desktop: desktop),
          forceRefresh: forceRefresh);

  static Future<List<SliderItem>> _load(int category) async {
    final items = <SliderItem>[];
    String? url = '$_endpoint?category=$category';
    var guard = 0;
    try {
      while (url != null && url.isNotEmpty && guard++ < 25) {
        final res = await http
            .get(Uri.parse(url), headers: {'accept': 'application/json'})
            .timeout(const Duration(seconds: 12));
        if (res.statusCode < 200 || res.statusCode >= 300) break;
        final data =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        for (final r in (data['results'] as List? ?? const [])) {
          if (r is Map<String, dynamic>) {
            final item = SliderItem.fromJson(r, host);
            // اسلاید ویدیویی تصویر لازم ندارد؛ بقیه بدون تصویر بی‌معنی‌اند.
            if (item.imageUrl.isNotEmpty || item.isVideo) items.add(item);
          }
        }
        url = data['next'] as String?;
      }
    } catch (_) {
      // شبکه/سرور در دسترس نیست: اگر کشِ قدیمی داریم همان را بده، وگرنه خالی.
      return _cache[category] ?? const [];
    }
    items.sort((a, b) => a.sortingOrder.compareTo(b.sortingOrder));
    _cache[category] = items;
    _cacheAt[category] = DateTime.now();
    return items;
  }
}
