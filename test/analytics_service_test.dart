import 'package:flutter_test/flutter_test.dart';
import 'package:marketky/services/analytics_service.dart';

void main() {
  setUp(AnalyticsService.reset);

  test('view_item با شناسه محصول ثبت می‌شود', () {
    AnalyticsService.viewItem(productId: 9, name: 'کفش', price: 100);
    expect(AnalyticsService.events.single.name, 'view_item');
    expect(AnalyticsService.events.single.params['product_id'], 9);
  });

  test('قیف خرید به ترتیب ثبت می‌شود', () {
    AnalyticsService.viewItem(productId: 1);
    AnalyticsService.addToCart(productId: 1, quantity: 2, price: 500);
    AnalyticsService.beginCheckout(itemCount: 2, value: 1000);
    AnalyticsService.purchase(trackingCode: 'TRK1', value: 1000);

    expect(
      AnalyticsService.events.map((e) => e.name).toList(),
      ['view_item', 'add_to_cart', 'begin_checkout', 'purchase'],
    );
  });

  test('search تعداد نتایج را نگه می‌دارد', () {
    AnalyticsService.search(query: 'کفش', resultCount: 2);
    expect(AnalyticsService.events.single.params['results'], 2);
  });

  test('خطا با متن و بستر ثبت می‌شود', () {
    AnalyticsService.logError('boom', context: 'checkout');
    final e = AnalyticsService.events.single;
    expect(e.name, 'error');
    expect(e.params['context'], 'checkout');
  });

  test('reset رویدادها را پاک می‌کند', () {
    AnalyticsService.viewItem(productId: 1);
    AnalyticsService.reset();
    expect(AnalyticsService.events, isEmpty);
  });
}
