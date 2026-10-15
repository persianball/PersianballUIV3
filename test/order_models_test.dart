// مدل سفارش، بر پایه‌ی پاسخ واقعی /v2/order/order/2097/.
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/models/order_models.dart';

// همان بدنه‌ی واقعی سرور، فقط خلاصه‌شده به فیلدهایی که مدل می‌خواند.
const String _json = '''
{
  "delivery_method": "post",
  "address": "تهران, تهران, جنت آباد جنوبی چهارباغ شرقی, postal code: 1473837515, receiver phone: 09935640514, receiver_home_phone: 02144409176, address name: خانه",
  "id": 2097,
  "created_at": "2025-09-11T14:18:06.045020+03:30",
  "tracking_code": "7899526846",
  "order_status": "failed",
  "price": {
    "price": 7500000, "nat": 0.0, "discounted_price": 272000.0,
    "is_free_shipping": true, "free_shipping_threshold": 7000,
    "post_shipping_price": 30000, "peyk_shipping_price": 50000,
    "order_shipping_price": 0
  },
  "order_items": [
    {"id": 2153, "quantity": 1, "course": null, "classes": null, "support_coach": null,
     "product": {"id": 3, "size": "40", "price": 3400000, "discount_percentage": 8,
       "product_variant": {"product_name": "کفش فلو پرشین بال", "color": "مشکی",
         "color_rgb": "696969", "image": "/media/images/a.png", "id": 29}}},
    {"id": 2154, "quantity": 1, "course": null, "classes": null, "support_coach": null,
     "product": {"id": 13, "size": "41", "price": 4100000, "discount_percentage": 0,
       "product_variant": {"product_name": "کفش تروپیک فیل", "color": "طوسی",
         "color_rgb": "2F4F4F", "image": "/media/images/b.jpg", "id": 83}}}
  ]
}
''';

Order _order() =>
    Order.fromJson(jsonDecode(_json) as Map<String, dynamic>);

void main() {
  test('discounted_price مبلغِ تخفیف است، نه قیمتِ نهایی', () {
    final o = _order();
    expect(o.price.subtotal, 7500000);
    expect(o.price.discount, 272000);
    // همان مبلغی که پرداختِ متناظر (۱۹۸۲) نشان می‌دهد
    expect(o.price.payable, 7228000);
  });

  test('اقلام محصول با سایز، رنگ و تخفیف خوانده می‌شوند', () {
    final items = _order().items;
    expect(items.length, 2);
    expect(items.first.title, 'کفش فلو پرشین بال');
    expect(items.first.size, '40');
    expect(items.first.color, 'مشکی');
    expect(items.first.discountPercentage, 8);
    expect(items.first.finalUnitPrice, 3128000); // ۳٬۴۰۰٬۰۰۰ منهای ۸٪
    expect(items.last.hasDiscount, isFalse);
    expect(items.last.lineTotal, 4100000);
  });

  test('آدرسِ تخت به بخش‌های خوانا شکسته می‌شود', () {
    final a = _order().address;
    expect(a.line, 'تهران، تهران، جنت آباد جنوبی چهارباغ شرقی');
    expect(a.postalCode, '1473837515');
    expect(a.receiverPhone, '09935640514');
    expect(a.homePhone, '02144409176');
    expect(a.name, 'خانه');
  });

  test('وضعیت و روش ارسال', () {
    final o = _order();
    expect(o.status, OrderStatus.failed);
    expect(o.status.isTerminalFailure, isTrue);
    expect(o.deliveryLabel, 'پست');
    expect(o.itemCount, 2);
    expect(o.needsShipping, isTrue);
  });

  test('کد رهگیریِ "None" به null تبدیل می‌شود', () {
    final o = Order.fromJson({
      'id': 2098,
      'order_status': 'pending',
      'tracking_code': 'None',
      'order_items': const [],
    });
    expect(o.trackingCode, isNull);
    expect(o.status.timelineIndex, 0);
  });

  test('قلمِ دوره: مکان و زمان دارد و نیازی به ارسال ندارد', () {
    final o = Order.fromJson({
      'id': 2112,
      'order_status': 'pending',
      'delivery_method': 'free',
      'order_items': [
        {
          'id': 2172,
          'quantity': 1,
          'product': null,
          'course': {
            'course_name': 'کلاس های حضوری تهران',
            'price': 5000000,
            'discount_percentage': 0,
            'location': 'شرق',
            'time': 'یک شنبه و سه شنبه',
            'image': '/media/images/c.png',
          },
        }
      ],
    });
    expect(o.items.single.isCourse, isTrue);
    expect(o.items.single.location, 'شرق');
    expect(o.needsShipping, isFalse);
    expect(o.deliveryLabel, 'ارسال رایگان');
  });

  test('قلمی که نه محصول است نه دوره نادیده گرفته می‌شود', () {
    final o = Order.fromJson({
      'id': 1,
      'order_status': 'pending',
      'order_items': [
        {'id': 9, 'quantity': 1, 'product': null, 'course': null}
      ],
    });
    expect(o.items, isEmpty);
  });
}
