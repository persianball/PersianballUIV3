// تست‌های پارس سبد خرید.
//
// انگیزه: سرور برای فیلدهای ارجاعی گاهی فقط شناسه و گاهی کل آبجکت را
// برمی‌گرداند. قبلاً همین باعث می‌شد کل سبد با
// «_JsonMap is not a subtype of type int?» از پارس بیفتد و صفحه‌ی سبد
// پیام «محصول در سبد مشکلی دارد» نشان دهد.
import 'package:flutter_test/flutter_test.dart';
import 'package:marketky/models/CartModel.dart';

Map<String, dynamic> _basket({
  Object? supportCoach,
  Object? classes,
  Object? coach,
  Object? user,
}) {
  return {
    'count': 1,
    'results': [
      {
        'user': user ?? 5,
        'price': {
          'price': 250000,
          'nat': 22500,
          'discounted_price': 0,
          'is_free_shipping': false,
        },
        'items': [
          {
            'id': 12,
            'quantity': 2,
            'product': null,
            'course': {
              'id': 3,
              'is_active': true,
              'image': '/media/c.jpg',
              'price': 250000,
              'location': 'تهران',
              'coach': coach ?? 9,
              'course_name': 'دوره‌ی پایه',
              'gift_product': null,
              'shipment_required': false,
              'discount_percentage': 10,
              'capacity': 20,
            },
            'classes': classes,
            'support_coach': supportCoach,
          },
        ],
      },
    ],
  };
}

void main() {
  group('AllCartFromBackend.fromJson', () {
    test('شکل ساده‌ی پاسخ (فقط شناسه) درست پارس می‌شود', () {
      final cart = AllCartFromBackend.fromJson(_basket(supportCoach: 7));

      expect(cart.count, 1);
      final item = cart.results.single.items.single;
      expect(item.id, 12);
      expect(item.quantity, 2);
      expect(item.support_coach, 7);
      expect(item.course!.coach, 9);
      expect(cart.results.single.price.nat, 22500);
    });

    test('وقتی سرور به‌جای شناسه آبجکت می‌فرستد، شناسه استخراج می‌شود', () {
      final cart = AllCartFromBackend.fromJson(
        _basket(
          supportCoach: {'id': 7, 'name': 'مربی پشتیبان'},
          coach: {'id': 9, 'full_name': 'علی'},
          classes: {'id': 4, 'title': 'کلاس ۱'},
          user: {'id': 5, 'username': 'atom'},
        ),
      );

      final item = cart.results.single.items.single;
      expect(item.support_coach, 7, reason: 'support_coach باید به id تبدیل شود');
      expect(item.classes, 4);
      expect(item.course!.coach, 9);
      expect(cart.results.single.user, 5);
    });

    test('عدد رشته‌ای و اعشاری هم پذیرفته می‌شود', () {
      final json = _basket(supportCoach: '7');
      (json['results'] as List).first['price']['price'] = '250000';
      (json['results'] as List).first['items'].first['quantity'] = 2.0;

      final cart = AllCartFromBackend.fromJson(json);

      expect(cart.results.single.items.single.support_coach, 7);
      expect(cart.results.single.items.single.quantity, 2);
      expect(cart.results.single.price.price, 250000);
    });

    test('نبودِ شناسه با خطای گویا گزارش می‌شود، نه خطای نوع', () {
      final json = _basket();
      (json['results'] as List).first['items'].first.remove('id');

      expect(
        () => AllCartFromBackend.fromJson(json),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('items[].id'))),
      );
    });
  });
}
