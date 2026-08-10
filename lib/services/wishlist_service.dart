// lib/services/wishlist_service.dart
//
// علاقه‌مندی‌ها و بازدیدهای اخیر.
//
// وضعیت بک‌اند: هیچ endpointی برای wishlist وجود ندارد، بنابراین داده روی
// دستگاه (SharedPreferences) نگه داشته می‌شود.
//
// پیشنهاد برای بک‌اند (پس از آماده شدن فقط همین فایل عوض می‌شود):
//   GET    /v1/user/wishlist/            → [{product_id, created_at}]
//   POST   /v1/user/wishlist/            {product_id}
//   DELETE /v1/user/wishlist/<product_id>/
//   GET    /v1/user/recently-viewed/     → [{product_id, viewed_at}]
//   POST   /v1/user/recently-viewed/     {product_id}
import 'package:shared_preferences/shared_preferences.dart';

class WishlistService {
  static const String _wishlistKey = 'wishlist_product_ids';
  static const String _recentKey = 'recently_viewed_product_ids';
  static const int _recentLimit = 20;

  static Future<List<int>> favorites() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_wishlistKey) ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toList();
  }

  static Future<bool> isFavorite(int productId) async {
    final ids = await favorites();
    return ids.contains(productId);
  }

  /// وضعیت جدید را برمی‌گرداند: true یعنی الان در علاقه‌مندی‌هاست
  static Future<bool> toggle(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await favorites();
    final bool nowFavorite;
    if (ids.contains(productId)) {
      ids.remove(productId);
      nowFavorite = false;
    } else {
      ids.insert(0, productId);
      nowFavorite = true;
    }
    await prefs.setStringList(
        _wishlistKey, ids.map((e) => e.toString()).toList());
    return nowFavorite;
  }

  static Future<void> remove(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await favorites()..remove(productId);
    await prefs.setStringList(
        _wishlistKey, ids.map((e) => e.toString()).toList());
  }

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
