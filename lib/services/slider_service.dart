import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:marketky/models/slider_item.dart';

/// دریافت اسلایدهای گالری از بک‌اند، با پیمایشِ کاملِ صفحه‌بندی و کشِ کوتاه‌مدت.
class SliderService {
  SliderService._();

  /// سرورِ گالری (جدا از baseUrl اصلی اپ).
  static const String host = 'http://2.144.27.195:8000';
  static const String _endpoint = '$host/v1/gallery/slider/';

  static List<SliderItem>? _cache;
  static DateTime? _cacheAt;
  static const Duration _ttl = Duration(minutes: 5);
  static Future<List<SliderItem>>? _inFlight;

  static bool get _fresh =>
      _cache != null &&
      _cacheAt != null &&
      DateTime.now().difference(_cacheAt!) < _ttl;

  /// همه‌ی اسلایدها (همه‌ی صفحات)، مرتب‌شده بر اساس `sorting_order`.
  static Future<List<SliderItem>> fetchAll({bool forceRefresh = false}) {
    if (!forceRefresh && _fresh) return Future.value(_cache!);
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  static Future<List<SliderItem>> _load() async {
    final items = <SliderItem>[];
    String? url = _endpoint;
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
            if (item.imageUrl.isNotEmpty) items.add(item);
          }
        }
        url = data['next'] as String?;
      }
    } catch (_) {
      // شبکه/سرور در دسترس نیست: اگر کشِ قدیمی داریم همان را بده، وگرنه خالی.
      if (_cache != null) return _cache!;
      return const [];
    }
    items.sort((a, b) => a.sortingOrder.compareTo(b.sortingOrder));
    _cache = items;
    _cacheAt = DateTime.now();
    return items;
  }

  /// فقط اسلایدهای یک نوع (product / course)؛ null یعنی همه.
  static Future<List<SliderItem>> byKind(SliderKind? kind) async {
    final all = await fetchAll();
    if (kind == null) return all;
    return all.where((s) => s.kind == kind).toList();
  }
}
