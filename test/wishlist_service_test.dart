import 'package:flutter_test/flutter_test.dart';
import 'package:marketky/services/wishlist_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('علاقه‌مندی‌ها', () {
    test('در ابتدا خالی است', () async {
      expect(await WishlistService.favorites(), isEmpty);
      expect(await WishlistService.isFavorite(5), isFalse);
    });

    test('toggle اضافه و حذف می‌کند', () async {
      expect(await WishlistService.toggle(5), isTrue);
      expect(await WishlistService.isFavorite(5), isTrue);

      expect(await WishlistService.toggle(5), isFalse);
      expect(await WishlistService.isFavorite(5), isFalse);
    });

    test('جدیدترین علاقه‌مندی اول لیست است', () async {
      await WishlistService.toggle(1);
      await WishlistService.toggle(2);
      expect(await WishlistService.favorites(), [2, 1]);
    });

    test('remove فقط همان کالا را حذف می‌کند', () async {
      await WishlistService.toggle(1);
      await WishlistService.toggle(2);
      await WishlistService.remove(1);
      expect(await WishlistService.favorites(), [2]);
    });
  });

  group('بازدیدهای اخیر', () {
    test('آخرین بازدید ابتدای لیست می‌آید', () async {
      await WishlistService.markViewed(1);
      await WishlistService.markViewed(2);
      expect(await WishlistService.recentlyViewed(), [2, 1]);
    });

    test('بازدید تکراری جابه‌جا می‌شود نه تکرار', () async {
      await WishlistService.markViewed(1);
      await WishlistService.markViewed(2);
      await WishlistService.markViewed(1);
      expect(await WishlistService.recentlyViewed(), [1, 2]);
    });

    test('حداکثر ۲۰ مورد نگه داشته می‌شود', () async {
      for (int i = 1; i <= 25; i++) {
        await WishlistService.markViewed(i);
      }
      final recent = await WishlistService.recentlyViewed();
      expect(recent.length, 20);
      expect(recent.first, 25);
    });
  });
}
