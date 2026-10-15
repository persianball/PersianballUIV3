import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/core/deep_link_resolver.dart';

String? _r(String url) => DeepLinkResolver.resolve(Uri.parse(url));

void main() {
  group('لینک وب سرور فعلی', () {
    test('لینک محصول به روت محصول تبدیل می‌شود', () {
      expect(_r('http://2.144.27.195:8000/product/9'), '/product/9');
    });

    test('اسلش انتهایی نادیده گرفته می‌شود', () {
      expect(_r('http://2.144.27.195:8000/product/9/'), '/product/9');
    });

    test('https همان هاست هم کار می‌کند', () {
      expect(_r('https://2.144.27.195:8000/course/3'), '/course/3');
    });

    test('بدون پورت هم پذیرفته می‌شود', () {
      expect(_r('http://2.144.27.195/product/1'), '/product/1');
    });

    test('روت ثابت مثل سبد خرید', () {
      expect(_r('http://2.144.27.195:8000/cart'), '/cart');
    });
  });

  group('لینک‌هایی که نباید اپ را باز کنند', () {
    test('مسیر رسانه سرور', () {
      expect(_r('http://2.144.27.195:8000/media/images/a.png'), isNull);
    });

    test('مسیر API', () {
      expect(_r('http://2.144.27.195:8000/v2/product/product/'), isNull);
    });

    test('هاست غریبه', () {
      expect(_r('https://example.com/product/9'), isNull);
    });

    test('شناسه غیرعددی محصول', () {
      expect(_r('http://2.144.27.195:8000/product/abc'), isNull);
    });

    test('اسکیم ناشناخته', () {
      expect(_r('ftp://2.144.27.195/product/9'), isNull);
    });
  });

  group('اسکیم اختصاصی اپ', () {
    test('persianball://product/12', () {
      expect(_r('persianball://product/12'), '/product/12');
    });

    test('persianball://orders', () {
      expect(_r('persianball://orders'), '/orders');
    });

    test('مسیر ناشناخته در اسکیم اختصاصی رد می‌شود', () {
      expect(_r('persianball://unknown/5'), isNull);
    });
  });

  test('دامنه آینده از قبل پشتیبانی می‌شود', () {
    expect(_r('https://api2.persianball.ir/product/9'), '/product/9');
  });
}
