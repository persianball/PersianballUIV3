import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/services/recently_viewed_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('بازدیدهای اخیر', () {
    test('در ابتدا خالی است', () async {
      expect(await RecentlyViewedService.recentlyViewed(), isEmpty);
    });

    test('جدیدترین بازدید اول لیست می‌آید', () async {
      await RecentlyViewedService.markViewed(1);
      await RecentlyViewedService.markViewed(2);
      expect(await RecentlyViewedService.recentlyViewed(), [2, 1]);
    });

    test('بازدید دوباره‌ی یک محصول آن را به ابتدا می‌برد، نه تکراری', () async {
      await RecentlyViewedService.markViewed(1);
      await RecentlyViewedService.markViewed(2);
      await RecentlyViewedService.markViewed(1);
      expect(await RecentlyViewedService.recentlyViewed(), [1, 2]);
    });

    test('حداکثر ۲۰ مورد نگه داشته می‌شود', () async {
      for (var i = 1; i <= 25; i++) {
        await RecentlyViewedService.markViewed(i);
      }
      final ids = await RecentlyViewedService.recentlyViewed();
      expect(ids, hasLength(20));
      expect(ids.first, 25);
    });
  });
}
