import 'package:flutter_test/flutter_test.dart';
import 'package:marketky/models/slider_item.dart';

SliderItem _item(String image, String base) =>
    SliderItem.fromJson({'image': image, 'slider_type': 'product'}, base);

void main() {
  group('ساخت آدرس تصویر اسلاید', () {
    test('ته‌اسلشِ baseUrl باعث اسلش دوتایی نمی‌شود', () {
      final i = _item('/media/images/a.jpg', 'https://pball.ah8ad3.ir/');
      expect(i.imageUrl, 'https://pball.ah8ad3.ir/media/images/a.jpg');
      expect(i.imageUrl.contains('//media'), isFalse);
    });

    test('بدونِ ته‌اسلش هم درست جوش می‌خورد', () {
      final i = _item('/media/images/a.jpg', 'https://pball.ah8ad3.ir');
      expect(i.imageUrl, 'https://pball.ah8ad3.ir/media/images/a.jpg');
    });

    test('مسیر بدون اسلشِ ابتدایی', () {
      final i = _item('media/images/a.jpg', 'https://pball.ah8ad3.ir/');
      expect(i.imageUrl, 'https://pball.ah8ad3.ir/media/images/a.jpg');
    });

    test('آدرس مطلق دست‌نخورده می‌ماند', () {
      final i = _item('https://cdn.example.com/x.jpg', 'https://pball.ah8ad3.ir/');
      expect(i.imageUrl, 'https://cdn.example.com/x.jpg');
    });

    test('تصویر خالی، رشته‌ی خالی می‌دهد (نه آدرسِ ناقص)', () {
      final i = _item('', 'https://pball.ah8ad3.ir/');
      expect(i.imageUrl, '');
    });
  });
}
