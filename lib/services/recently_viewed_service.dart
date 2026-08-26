// lib/services/recently_viewed_service.dart
//
// بازدیدهای اخیر کاربر.
//
// وضعیت بک‌اند: endpointی برای این کار وجود ندارد، بنابراین داده روی دستگاه
// (SharedPreferences) نگه داشته می‌شود.
//
// پیشنهاد برای بک‌اند (پس از آماده شدن فقط همین فایل عوض می‌شود):
//   GET    /v1/user/recently-viewed/     → [{product_id, viewed_at}]
//   POST   /v1/user/recently-viewed/     {product_id}
import 'package:shared_preferences/shared_preferences.dart';

class RecentlyViewedService {
  static const String _recentKey = 'recently_viewed_product_ids';
  static const int _recentLimit = 20;

  /// آخرین محصولات دیده‌شده، جدیدترین اول
  static Future<List<int>> recentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_recentKey) ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toList();
  }

  static Future<void> markViewed(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await recentlyViewed();
    ids.remove(productId);
    ids.insert(0, productId);
    final trimmed = ids.take(_recentLimit).toList();
    await prefs.setStringList(
        _recentKey, trimmed.map((e) => e.toString()).toList());
  }
}
