import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/models/ProductModel.dart';

ProductComment _c(String username) => ProductComment.fromJson({
      'text': 'متن نظر',
      'admin_response': '',
      'created_at': '2024-12-13T11:58:37.974007+03:30',
      'username': username,
    });

void main() {
  group('نام کاربریِ نظر', () {
    test('نام عادی دست‌نخورده نمایش داده می‌شود', () {
      expect(_c('iman').displayName, 'iman');
      expect(_c('omidrazzaghi').displayName, 'omidrazzaghi');
      expect(_c('saman111').displayName, 'saman111');
    });

    test('شماره‌ی موبایل ماسک می‌شود تا زیر نظرِ عمومی لو نرود', () {
      final masked = _c('09034024306').displayName;
      expect(masked, '0903***306');
      expect(masked.contains('09034024306'), isFalse);
    });

    test('نام خالی به نامِ پیش‌فرض تبدیل می‌شود', () {
      expect(_c('').displayName, 'کاربر پرشین بال');
      expect(_c('   ').displayName, 'کاربر پرشین بال');
    });

    test('نبودِ فیلد username کرش نمی‌کند', () {
      final c = ProductComment.fromJson({
        'text': 'بدون نام',
        'admin_response': '',
        'created_at': '2024-12-13T11:58:37+03:30',
      });
      expect(c.username, '');
      expect(c.displayName, 'کاربر پرشین بال');
    });

    test('حرف اول برای آواتار درست است (فارسی و لاتین)', () {
      expect(_c('iman').initial, 'i');
      expect(_c('امید').initial, 'ا');
      expect(_c('').initial, 'ک');
    });
  });

  group('تفکیک ستاره‌ای امتیاز (rating_distribution)', () {
    ProductDetail _detail(dynamic dist) => ProductDetail.fromJson({
          'id': 9,
          'variants': [],
          'name_farsi': 'محصول',
          'description': '',
          'image': '',
          'published': true,
          'images': [],
          'category': {'name_farsi': 'دسته', 'image': null, 'id': 1},
          'simillar_products': [],
          'faqs': [],
          'comments': [],
          'avg_rate': 1.0,
          'rating_distribution': dist,
        });

    test('کلیدهای رشته‌ای به عدد تبدیل می‌شوند', () {
      final d = _detail({'1': 1, '2': 0, '3': 0, '4': 0, '5': 2});
      expect(d.ratingDistribution[1], 1);
      expect(d.ratingDistribution[5], 2);
      expect(d.ratingDistribution.values.fold<int>(0, (a, b) => a + b), 3);
    });

    test('نبودِ فیلد یا مقدار نامعتبر، نقشه‌ی خالی می‌دهد', () {
      expect(_detail(null).ratingDistribution, isEmpty);
      expect(_detail('bad').ratingDistribution, isEmpty);
    });

    test('ستاره‌های خارج از بازه‌ی ۱..۵ نادیده گرفته می‌شوند', () {
      final d = _detail({'0': 5, '6': 9, '3': 2});
      expect(d.ratingDistribution.keys.toList(), [3]);
    });
  });
}
