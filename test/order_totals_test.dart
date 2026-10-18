import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/utils/api_error.dart';
import 'package:persian_ball/utils/order_totals.dart';

void main() {
  group('OrderTotals (ورودی‌ها از price ِ سبد)', () {
    test('بدونِ کد: ۱۰٬۰۰۰ − ۹٬۰۰۰ = ۱٬۰۰۰', () {
      final t = OrderTotals.compute(
          base: 10000, productDiscount: 9000, tax: 0, shipping: 30000, freeShipping: true);
      expect(t.subtotal, 1000);
      expect(t.voucherAmount, 0);
      expect(t.payable, 1000);
    });

    test('کدِ ۱۰۰٪ (omidiman): تخفیفِ کد = کلِ مبلغ، پرداختی صفر — نه قیمتِ کامل', () {
      final t = OrderTotals.compute(
          base: 10000, productDiscount: 9000, tax: 0, shipping: 30000, freeShipping: true,
          voucherPercent: 100);
      expect(t.voucherAmount, 1000);
      expect(t.payable, 0);
    });

    test('کدِ ۳۰٪ روی مبلغِ بعد از تخفیفِ کالا، گرد به نفعِ مشتری', () {
      final t = OrderTotals.compute(
          base: 10000, productDiscount: 9000, tax: 0, shipping: 30000, freeShipping: false,
          voucherPercent: 33);
      expect(t.voucherAmount, 330);
      expect(t.payable, 1000 - 330 + 30000);
    });

    test('مالیات و ارسال به ردیفِ تخفیف اضافه نمی‌شوند؛ پرداختی منفی نمی‌شود', () {
      final t = OrderTotals.compute(
          base: 10000, productDiscount: 12000, tax: 500, shipping: 0, freeShipping: true,
          voucherPercent: 100);
      expect(t.subtotal, 0);
      expect(t.voucherAmount, 0);
      expect(t.payable, 500);
    });
  });

  group('ApiError (پاسخ‌های واقعیِ سرور)', () {
    test('کدِ اشتباه', () {
      final e = ApiError.fromResponse(400,
          '{"code":"invalid_data","status":null,"messages":"Discount does not exist"}');
      expect(e.message, 'کد تخفیف وجود ندارد');
      expect(e.status, 400);
    });
    test('کدِ خالی (خطای فیلد)', () {
      final e = ApiError.fromResponse(400, '{"code":["این مقدار نباید خالی باشد."]}');
      expect(e.message, 'code: این مقدار نباید خالی باشد.');
    });
    test('بدونِ ورود', () {
      final e = ApiError.fromResponse(401, '{"detail":"اطلاعات برای اعتبارسنجی ارسال نشده است."}');
      expect(e.message, 'اطلاعات برای اعتبارسنجی ارسال نشده است.');
    });
    test('بدنه‌ی غیرِ JSON', () {
      final e = ApiError.fromResponse(502, '<html>Bad Gateway</html>');
      expect(e.message, 'خطای سرور (502)');
      expect(e.raw, contains('Bad Gateway'));
    });
  });
}
