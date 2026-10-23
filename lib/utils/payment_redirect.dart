// lib/utils/payment_redirect.dart
//
// آدرسِ درگاه از پاسخِ ساختِ سفارش.
//
// v1 آن را در `redirect_url` برمی‌گرداند. در اسکیمای v2 (`POST /v2/order/order/`
// → 201 با شمای Order) فیلدی برای آدرسِ درگاه مستند نشده، پس چند نامِ رایج
// و یک سطح تودرتو (payment / data) هم بررسی می‌شود.
const List<String> _keys = [
  'redirect_url',
  'payment_url',
  'gateway_url',
  'url',
  'link',
];

String? paymentRedirectUrl(dynamic json) {
  if (json is! Map) return null;
  for (final k in _keys) {
    final v = json[k];
    if (v is String && v.trim().startsWith('http')) return v.trim();
  }
  for (final nested in const ['payment', 'data']) {
    final r = paymentRedirectUrl(json[nested]);
    if (r != null) return r;
  }
  return null;
}
