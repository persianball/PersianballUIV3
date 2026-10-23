// ساختِ سفارش با /v2/order/order/: آدرسِ درگاه و پیامِ خطا.
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/utils/api_error.dart';
import 'package:persian_ball/utils/payment_redirect.dart';

void main() {
  test('redirect_url مثل v1', () {
    expect(paymentRedirectUrl({'redirect_url': 'https://pay.example/x'}), 'https://pay.example/x');
  });

  test('نام‌های دیگر و یک سطح تودرتو', () {
    expect(paymentRedirectUrl({'payment_url': ' https://pay.example/a '}), 'https://pay.example/a');
    expect(paymentRedirectUrl({'id': 1, 'payment': {'url': 'https://pay.example/b'}}), 'https://pay.example/b');
    expect(paymentRedirectUrl({'data': {'link': 'https://pay.example/c'}}), 'https://pay.example/c');
  });

  test('بدونِ آدرسِ درگاه یا مقدارِ نامعتبر → null', () {
    expect(paymentRedirectUrl({'id': 5, 'order_status': 'pending', 'price': '1000'}), isNull);
    expect(paymentRedirectUrl({'redirect_url': ''}), isNull);
    expect(paymentRedirectUrl({'url': '/relative'}), isNull);
    expect(paymentRedirectUrl('not a map'), isNull);
  });

  test('خطای v2 بدونِ آدرس فارسی نشان داده می‌شود', () {
    final e = ApiError.fromResponse(400, '{"code":"invalid_data","status":null,"messages":"Address is empty"}');
    expect(e.message, 'آدرسِ ارسال انتخاب نشده است');
  });
}
