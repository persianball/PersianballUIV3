// آیا سبد به مرحله‌ی «انتخاب آدرس» نیاز دارد؟
//
// دوره ارسال فیزیکی ندارد، پس سبدِ فقط-دوره نباید کاربر را به انتخاب آدرس
// بفرستد؛ مگر دوره‌ای که هدیه‌ی فیزیکی دارد یا بک‌اند برایش
// shipment_required فرستاده باشد.
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/models/CartModel.dart';

Map<String, dynamic> _course({
  Object? gift,
  bool shipmentRequired = false,
}) =>
    {
      'id': 3,
      'is_active': true,
      'image': null,
      'price': 250000,
      'location': 'تهران',
      'coach': 9,
      'course_name': 'دوره‌ی پایه',
      'gift_product': gift,
      'shipment_required': shipmentRequired,
      'discount_percentage': 0,
      'capacity': 20,
    };

Map<String, dynamic> _variant() => {
      'id': 5,
      'is_active': true,
      'image': '/m/a.jpg',
      'color': 'مشکی',
      'color_rgb': '#000',
      'product_name': 'کفش',
      'size_variants': [],
      'images': [],
    };

AllCartFromBackend _cart(List<Map<String, dynamic>> items) =>
    AllCartFromBackend.fromJson({
      'count': 1,
      'results': [
        {
          'user': 5,
          'price': {'price': 250000, 'nat': 0, 'discounted_price': 0},
          'items': items,
        }
      ],
    });

Map<String, dynamic> _courseItem(int id, Map<String, dynamic> course) =>
    {'id': id, 'quantity': 1, 'product': null, 'course': course};

void main() {
  group('AllCartFromBackend.requiresAddress', () {
    test('سبدِ فقط-دوره آدرس نمی‌خواهد', () {
      expect(_cart([_courseItem(1, _course())]).requiresAddress, isFalse);
    });

    test('دوره‌ی دارای هدیه آدرس می‌خواهد', () {
      final cart = _cart([_courseItem(1, _course(gift: _variant()))]);
      expect(cart.requiresAddress, isTrue,
          reason: 'هدیه باید جایی تحویل داده شود');
    });

    test('دوره‌ای که بک‌اند shipment_required داده آدرس می‌خواهد', () {
      final cart = _cart([_courseItem(1, _course(shipmentRequired: true))]);
      expect(cart.requiresAddress, isTrue);
    });

    test('وجود حتی یک محصول فیزیکی، آدرس را لازم می‌کند', () {
      final cart = _cart([
        _courseItem(1, _course()),
        {
          'id': 2,
          'quantity': 1,
          'product': {
            'id': 10,
            'product_variant': _variant(),
            'size': '42',
            'count': 3,
            'discount_percentage': 0,
            'is_active': true,
            'price': 500000,
          },
          'course': null,
        },
      ]);
      expect(cart.requiresAddress, isTrue);
    });

    test('سبد خالی آدرس نمی‌خواهد', () {
      expect(_cart([]).requiresAddress, isFalse);
    });
  });
}
