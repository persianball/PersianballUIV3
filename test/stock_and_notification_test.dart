import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/models/ProductModel.dart';
import 'package:persian_ball/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('موجودی سایز', () {
    test('count از JSON خوانده می‌شود', () {
      final v = SizeVariant.fromJson({
        'id': 11,
        'size': '39',
        'discount_percentage': 20,
        'price': 4200000,
        'count': 10,
      });
      expect(v.count, 10);
      expect(v.inStock, isTrue);
      expect(v.isLowStock, isFalse);
    });

    test('count صفر یعنی ناموجود', () {
      final v = SizeVariant(id: 1, size: '40', discountPercentage: 0, price: 1, count: 0);
      expect(v.inStock, isFalse);
    });

    test('موجودی کمتر از ۴ به عنوان کم علامت می‌خورد', () {
      final v = SizeVariant(id: 1, size: '40', discountPercentage: 0, price: 1, count: 3);
      expect(v.isLowStock, isTrue);
    });

    test('نبود فیلد count باعث خطا نمی‌شود', () {
      final v = SizeVariant.fromJson({
        'id': 11,
        'size': '39',
        'discount_percentage': 0,
        'price': 100,
      });
      expect(v.count, 0);
      expect(v.inStock, isFalse);
    });
  });

  group('اعلان‌ها', () {
    test('در ابتدا همه خوانده‌نشده‌اند', () async {
      final all = await NotificationService.fetch();
      expect(await NotificationService.unreadCount(), all.length);
    });

    test('خواندن یک اعلان شمارنده را کم می‌کند', () async {
      final before = await NotificationService.unreadCount();
      await NotificationService.markRead(1);
      expect(await NotificationService.unreadCount(), before - 1);
    });

    test('خواندن همه، شمارنده را صفر می‌کند', () async {
      await NotificationService.markAllRead();
      expect(await NotificationService.unreadCount(), 0);
    });

    test('بنرهای هوم خالی نیستند', () {
      expect(NotificationService.banners(), isNotEmpty);
    });
  });
}
