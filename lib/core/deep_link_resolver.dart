// lib/core/deep_link_resolver.dart
//
// تبدیل لینک ورودی به روت داخلی اپ.
//
// دو شکل لینک پشتیبانی می‌شود:
//   ۱) اسکیم اختصاصی:  marketky://product/12
//   ۲) لینک وب هاست‌های مجاز: http://2.144.27.195:8000/product/12
//
// هر لینکی که هاستش در URLs.deepLinkHosts نباشد یا مسیرش جزو روت‌های اپ نباشد
// (مثل /media/... یا /v2/product/...) نادیده گرفته می‌شود تا اپ بی‌دلیل باز نشود.
import 'package:marketky/constant/urls.dart';

class DeepLinkResolver {
  /// روت‌های ثابت اپ
  static const Set<String> _staticRoutes = {
    '/',
    '/home',
    '/welcome',
    '/login',
    '/cart',
    '/orders',
    '/addresses',
    '/wishlist',
    '/notifications',
    '/catalog',
    '/compare',
    '/account-security',
    '/terms',
    '/privacy',
    '/about',
    '/support',
  };

  /// روت‌های پویا: /product/<id> و /course/<id>
  static final RegExp _dynamicRoute = RegExp(r'^/(product|course)/\d+$');

  /// اگر لینک قابل هندل باشد روت داخلی را برمی‌گرداند، وگرنه null
  static String? resolve(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    String path;

    if (scheme == URLs.appScheme) {
      // marketky://product/12  →  host=product ، path=/12
      path = uri.host.isEmpty
          ? (uri.path.isEmpty ? '/' : uri.path)
          : '/${uri.host}${uri.path}';
    } else if (scheme == 'http' || scheme == 'https') {
      // فقط هاست‌های خودمان؛ پورت اهمیتی ندارد
      if (!URLs.isDeepLinkHost(uri.host)) return null;
      path = uri.path.isEmpty ? '/' : uri.path;
    } else {
      return null;
    }

    // حذف اسلش انتهایی: /product/12/ → /product/12
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    if (_dynamicRoute.hasMatch(path)) return path;
    if (_staticRoutes.contains(path)) return path;

    return null;
  }
}
