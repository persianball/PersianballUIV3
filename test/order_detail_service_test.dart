import 'package:flutter_test/flutter_test.dart';
import 'package:marketky/models/payment_models.dart';
import 'package:marketky/services/order_detail_service.dart';

PaymentItem _payment({int id = 2, String status = 'success', int price = 1000000}) =>
    PaymentItem(id: id, user: 1, trackingCode: 'TRK$id', status: status, price: price);

void main() {
  test('صورتحساب: مبلغ قابل پرداخت مجموع اجزا است', () async {
    final d = await OrderDetailService.fetchDetail(_payment());
    expect(d.payable, d.price - d.discount + d.tax + d.shippingPrice);
  });

  test('سفارش در انتظار پرداخت، در مرحله اول پیگیری است', () async {
    final d = await OrderDetailService.fetchDetail(_payment(status: 'pending'));
    expect(d.currentStep, ShipmentStep.paid);
  });

  test('سفارش قابل لغو است تا قبل از ارسال', () async {
    final d = await OrderDetailService.fetchDetail(_payment(status: 'pending'));
    expect(d.canCancel, isTrue);
    expect(d.canReturn, isFalse);
  });

  test('سفارش تحویل‌شده فقط مرجوعی دارد نه لغو', () async {
    // id به گونه‌ای انتخاب شده که مرحله delivered شود
    final d = await OrderDetailService.fetchDetail(_payment(id: 5));
    expect(d.currentStep, ShipmentStep.delivered);
    expect(d.canCancel, isFalse);
    expect(d.canReturn, isTrue);
  });

  test('کد رهگیری مرسوله فقط بعد از ارسال ساخته می‌شود', () async {
    final pending = await OrderDetailService.fetchDetail(_payment(status: 'pending'));
    expect(pending.shipmentTrackingNumber, isNull);

    final shipped = await OrderDetailService.fetchDetail(_payment(id: 5));
    expect(shipped.shipmentTrackingNumber, isNotNull);
  });

  test('داده ماک علامت‌گذاری شده تا در UI هشدار داده شود', () async {
    final d = await OrderDetailService.fetchDetail(_payment());
    expect(d.isMock, isTrue);
  });
}
