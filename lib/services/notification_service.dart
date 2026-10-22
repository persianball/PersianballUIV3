// lib/services/notification_service.dart
//
// بنرهای هوم.
//
// اعلان‌ها دیگر اینجا نیستند: زنگوله و صفحه‌ی اعلان‌ها از صندوق پیامِ واقعیِ
// سرور (/v1/user/messages/) در user_message_service.dart می‌خوانند.
//
// بک‌اند هنوز endpointی برای بنر ندارد و بنرها از assets می‌آیند. پیشنهاد:
//   GET  /v1/marketing/banners/  → [{id, image, title, subtitle,
//        target: {kind, id|url}, starts_at, ends_at}]

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
