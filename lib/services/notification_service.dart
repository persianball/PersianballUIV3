// lib/services/notification_service.dart
//
// اعلان‌های درون‌برنامه‌ای و بنرهای هوم.
//
// وضعیت بک‌اند: هیچ endpointی برای اعلان یا بنر وجود ندارد و کاروسل هوم از
// تصاویر ثابت assets پر می‌شود.
//
// پیشنهاد برای بک‌اند (وقتی آماده شد فقط همین فایل عوض می‌شود):
//   GET  /v1/notification/notifications/     → {count, results:[{id, type, title,
//        body, created_at, is_read, target: {kind: "product|order|url", id|url}}]}
//   POST /v1/notification/notifications/<id>/read/
//   POST /v1/notification/devices/           {token, platform}   ← برای FCM
//   GET  /v1/marketing/banners/              → [{id, image, title, subtitle,
//        target: {kind, id|url}, starts_at, ends_at}]
//
// برای push واقعی به firebase_messaging نیاز است؛ اینجا فقط لایه داده آماده شده
// تا وقتی بک‌اند و کلید FCM آماده شد، فقط منبع داده عوض شود.
import 'package:shared_preferences/shared_preferences.dart';

enum AppNotificationType { order, promo, system }

class AppNotification {
  final int id;
  final AppNotificationType type;
  final String title;
  final String body;
  final String createdAt;

  /// مقصد کلیک: '/product/12' یا '/orders' و…
  final String? route;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.route,
  });
}

class HomeBanner {
  final int id;
  final String title;
  final String subtitle;

  /// تصویر assets تا زمانی که بک‌اند بنر بدهد
  final String assetImage;
  final String? route;

  const HomeBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetImage,
    this.route,
  });
}

class NotificationService {
  static const String _readKey = 'read_notification_ids';

  static bool get isMock => true;

  static final List<AppNotification> _mock = const [
    AppNotification(
      id: 1,
      type: AppNotificationType.order,
      title: 'سفارش شما ارسال شد',
      body: 'مرسوله سفارش #۱۲ تحویل پست شد و کد رهگیری صادر گردید.',
      createdAt: 'امروز، ۱۰:۲۴',
      route: '/orders',
    ),
    AppNotification(
      id: 2,
      type: AppNotificationType.promo,
      title: 'فروش ویژه تابستان',
      body: 'تا ۳۰٪ تخفیف روی کفش‌های ورزشی، فقط تا پایان هفته.',
      createdAt: 'دیروز، ۱۸:۰۰',
      route: '/catalog',
    ),
    AppNotification(
      id: 3,
      type: AppNotificationType.system,
      title: 'ورود جدید به حساب کاربری',
      body: 'ورود موفق از دستگاه اندروید ثبت شد. اگر شما نبودید رمز را تغییر دهید.',
      createdAt: '۱۴۰۴/۰۵/۱۰',
    ),
  ];

  static Future<List<AppNotification>> fetch() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_mock);
  }

  static Future<Set<int>> readIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_readKey) ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  static Future<void> markRead(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await readIds()..add(id);
    await prefs.setStringList(_readKey, ids.map((e) => e.toString()).toList());
  }

  static Future<void> markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final all = (await fetch()).map((n) => n.id.toString()).toList();
    await prefs.setStringList(_readKey, all);
  }

  static Future<int> unreadCount() async {
    final read = await readIds();
    final all = await fetch();
    return all.where((n) => !read.contains(n.id)).length;
  }

  /// بنرهای هوم؛ فعلاً از assets، بعداً از /v1/marketing/banners/
  static List<HomeBanner> banners() => const [
        HomeBanner(
          id: 1,
          title: 'بهترین‌ها را برای خود پیدا کنید',
          subtitle: 'جدیدترین محصولات پرشین‌بال',
          assetImage: 'assets/images/background.jpg',
        ),
        HomeBanner(
          id: 2,
          title: 'فروش ویژه',
          subtitle: 'تا ۳۰٪ تخفیف روی کالاهای منتخب',
          assetImage: 'assets/images/background.png',
        ),
        HomeBanner(
          id: 3,
          title: 'دوره‌های آموزشی',
          subtitle: 'با مربیان حرفه‌ای تمرین کنید',
          assetImage: 'assets/images/background2.png',
        ),
      ];
}
