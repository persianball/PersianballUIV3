import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:persian_ball/constant/urls.dart';
import 'package:persian_ball/models/slider_item.dart';

/// دریافت اسلایدهای گالری از بک‌اند، با پیمایشِ کاملِ صفحه‌بندی و کش.
///
/// بک‌اند برای هر صفحه یک «دسته» جدا دارد و فیلتر سمتِ سرور با
/// `?category=<num>` انجام می‌شود (نه سمتِ کلاینت):
///   ۱ app_home_page  ۲ app_academy_page  ۴ site_academy_page
///   ۵ site_main_home_page
/// نگاشتِ صفحه/اندازه‌ی نمایشگر به این اعداد در [SliderCategory] است.
class SliderService {
  SliderService._();

  /// هاستِ اصلی، هم برای API و هم برای تصاویر.
  ///
  /// پیش‌تر اسلایدرها از `http://2.144.27.195:8000` خوانده می‌شدند. دو
  /// مشکل داشت:
  ///   • HTTP بود و روی نسخه‌ی وبِ میزبانی‌شده (HTTPS) مرورگر کلِ درخواست
  ///     را به‌عنوان mixed content بلاک می‌کرد، پس اسلایدرها خالی می‌ماندند.
  ///   • کند بود؛ اندازه‌گیری‌شده ۲ تا ۶ ثانیه در برابر حدود ۰٫۸ ثانیه اینجا.
  /// همان داده را برمی‌گرداند (تأیید شد: پاسخ‌ها یکسان‌اند) و فایل‌های
  /// `/media/...` هم از ابتدا روی همین هاست سرو می‌شدند.
  static String get host => URLs.baseUrl.endsWith('/')
      ? URLs.baseUrl.substring(0, URLs.baseUrl.length - 1)
      : URLs.baseUrl;

  static String get _endpoint => '$host/v1/gallery/slider/';

  /// تصاویر هم روی همین هاست‌اند.
  static String get mediaBase => URLs.baseUrl;

  static const Duration _ttl = Duration(minutes: 5);

  /// سرور گالری کند است (TTFB اندازه‌گیری‌شده: ۲ تا ۶ ثانیه). برای اینکه
  /// کاربر در هر اجرا منتظر نماند، آخرین پاسخِ موفق روی دستگاه ذخیره می‌شود
  /// و دفعه‌ی بعد فوراً نمایش داده می‌شود؛ به‌روزرسانی در پس‌زمینه انجام
  /// می‌گیرد و وقتی رسید UI خودش تازه می‌شود.
  static const String _diskKeyPrefix = 'slider_cache_v2_';

  /// کش و درخواستِ در جریان، به تفکیکِ دسته.
  static final Map<int, List<SliderItem>> _cache = {};
  static final Map<int, DateTime> _cacheAt = {};
  static final Map<int, Future<List<SliderItem>>> _inFlight = {};

  /// هر بار که کشِ یک دسته عوض شود اینجا اعلام می‌شود تا ویجت‌ها
  /// بدون نیاز به دوباره‌ساختن، محتوای تازه را نشان دهند.
  static final StreamController<int> _updates =
      StreamController<int>.broadcast();
  static Stream<int> get updates => _updates.stream;

  static bool _fresh(int category) {
    final at = _cacheAt[category];
    return _cache.containsKey(category) &&
        at != null &&
        DateTime.now().difference(at) < _ttl;
  }

  /// آنچه همین حالا و بدون انتظار در دسترس است (از حافظه). null یعنی
  /// چیزی نداریم و باید منتظر شبکه ماند.
  static List<SliderItem>? cached(int category) => _cache[category];

  /// اسلایدهای یک دسته، مرتب‌شده بر اساس `sorting_order`.
  static Future<List<SliderItem>> fetchCategory(
    int category, {
    bool forceRefresh = false,
  }) {
    if (!forceRefresh && _fresh(category)) {
      return Future.value(_cache[category]!);
    }
    return _inFlight[category] ??=
        _load(category).whenComplete(() => _inFlight.remove(category));
  }

  /// اسلایدهای یک صفحه؛ نسخه‌ی `site_…` یا `app_…` بر اساس اندازه‌ی نمایشگر.
  static Future<List<SliderItem>> forPage(
    SliderPage page, {
    required bool desktop,
    bool forceRefresh = false,
  }) =>
      fetchCategory(SliderCategory.of(page, desktop: desktop),
          forceRefresh: forceRefresh);

  /// خواندن کشِ روی دیسک به حافظه. در شروع اپ صدا زده می‌شود تا اولین
  /// نمایشِ اسلایدر منتظر سرورِ کند نماند.
  static Future<void> warmUp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final category in const [
        SliderCategory.appHomePage,
        SliderCategory.appAcademyPage,
        SliderCategory.siteAcademyPage,
        SliderCategory.siteMainHomePage,
      ]) {
        if (_cache.containsKey(category)) continue;
        final raw = prefs.getString('$_diskKeyPrefix$category');
        if (raw == null || raw.isEmpty) continue;
        final decoded = jsonDecode(raw);
        if (decoded is! List) continue;
        final items = <SliderItem>[];
        for (final r in decoded) {
          if (r is Map<String, dynamic>) {
            final item = SliderItem.fromJson(r, mediaBase);
            if (item.imageUrl.isNotEmpty || item.isVideo) items.add(item);
          }
        }
        if (items.isEmpty) continue;
        items.sort((a, b) => a.sortingOrder.compareTo(b.sortingOrder));
        _cache[category] = items;
        // عمداً _cacheAt ست نمی‌شود: داده‌ی دیسک فوراً نشان داده می‌شود
        // ولی «تازه» حساب نمی‌شود، پس در پس‌زمینه به‌روزرسانی می‌گیرد.
      }
    } catch (_) {
      // کشِ خراب نباید جلوی بالا آمدن اپ را بگیرد
    }
  }

  /// واکشیِ همه‌ی دسته‌ها در پس‌زمینه، بدون اینکه کسی منتظرشان بماند.
  static void prefetchAll() {
    for (final category in const [
      SliderCategory.appHomePage,
      SliderCategory.appAcademyPage,
      SliderCategory.siteAcademyPage,
      SliderCategory.siteMainHomePage,
    ]) {
      unawaited(fetchCategory(category).catchError((_) => <SliderItem>[]));
    }
  }

  static Future<List<SliderItem>> _load(int category) async {
    final items = <SliderItem>[];
    final rawResults = <Map<String, dynamic>>[];
    String? url = '$_endpoint?category=$category';
    var guard = 0;
    try {
      while (url != null && url.isNotEmpty && guard++ < 25) {
        final res = await http
            .get(Uri.parse(url), headers: {'accept': 'application/json'})
            // سرور گالری کند است؛ تایم‌اوتِ بلند فقط اسپینر را طولانی می‌کند
            .timeout(const Duration(seconds: 8));
        if (res.statusCode < 200 || res.statusCode >= 300) break;
        final data =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        for (final r in (data['results'] as List? ?? const [])) {
          if (r is Map<String, dynamic>) {
            final item = SliderItem.fromJson(r, mediaBase);
            // اسلاید ویدیویی تصویر لازم ندارد؛ بقیه بدون تصویر بی‌معنی‌اند.
            if (item.imageUrl.isNotEmpty || item.isVideo) {
              items.add(item);
              rawResults.add(r);
            }
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
    unawaited(_saveToDisk(category, rawResults));
    if (!_updates.isClosed) _updates.add(category);
    return items;
  }

  static Future<void> _saveToDisk(
      int category, List<Map<String, dynamic>> raw) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_diskKeyPrefix$category', jsonEncode(raw));
    } catch (_) {
      // ذخیره نشدن کش نباید به کاربر خطا بدهد
    }
  }
}
