// lib/services/analytics_service.dart
//
// آنالیتیکس قیف خرید و ثبت خطا.
//
// وضعیت: هیچ SDK آنالیتیکسی در پروژه نصب نیست (نه Firebase، نه Sentry).
// این لایه رویدادها را در حافظه نگه می‌دارد و در حالت دیباگ چاپ می‌کند تا:
//   ۱) نقاط رویداد همین حالا در کد کاشته شود،
//   ۲) با نصب SDK فقط بدنه _send عوض شود.
//
// رویدادهای استاندارد تجارت الکترونیک که اینجا پوشش داده شده‌اند:
//   view_item، add_to_cart، begin_checkout، purchase، search،
//   view_item_list، add_to_wishlist
import 'package:flutter/foundation.dart';

class AnalyticsEvent {
  final String name;
  final Map<String, Object?> params;

  const AnalyticsEvent(this.name, this.params);

  @override
  String toString() => '$name $params';
}

class AnalyticsService {
  /// رویدادهای ثبت‌شده در این نشست (برای دیباگ و تست)
  static final List<AnalyticsEvent> events = [];

  static void _send(String name, [Map<String, Object?> params = const {}]) {
    events.add(AnalyticsEvent(name, params));
    if (kDebugMode) {
      debugPrint('[analytics] $name $params');
    }
    // TODO: با نصب SDK اینجا به FirebaseAnalytics.logEvent وصل شود
  }

  static void viewItem({required int productId, String? name, int? price}) =>
      _send('view_item', {'product_id': productId, 'name': name, 'price': price});

  static void viewItemList({required String listName, required int count}) =>
      _send('view_item_list', {'list': listName, 'count': count});

  static void search({required String query, required int resultCount}) =>
      _send('search', {'query': query, 'results': resultCount});

  static void addToCart({
    required int productId,
    required int quantity,
    int? price,
  }) =>
      _send('add_to_cart',
          {'product_id': productId, 'quantity': quantity, 'price': price});

  static void addToWishlist({required int productId}) =>
      _send('add_to_wishlist', {'product_id': productId});

  static void beginCheckout({required int itemCount, required int value}) =>
      _send('begin_checkout', {'items': itemCount, 'value': value});

  static void purchase({required String trackingCode, required int value}) =>
      _send('purchase', {'transaction_id': trackingCode, 'value': value});

  /// ثبت خطا؛ با نصب Sentry به captureException وصل می‌شود
  static void logError(Object error, {StackTrace? stack, String? context}) {
    events.add(AnalyticsEvent('error', {
      'message': error.toString(),
      'context': context,
    }));
    if (kDebugMode) {
      debugPrint('[analytics:error] ${context ?? ''} $error');
    }
  }

  static void reset() => events.clear();
}
