// lib/models/order_models.dart
//
// مدل‌های سفارش برای /v2/order/order/ (لیست) و /v2/order/order/<id>/ (جزئیات).
// هر دو دقیقاً یک شکل برمی‌گردانند، پس یک مدل برای هر دو کافی است.
//
// نکته‌های اندازه‌گیری‌شده از پاسخ واقعی سرور:
//   • price.price = جمعِ قیمتِ اقلام *قبل از* تخفیف.
//   • price.discounted_price = «مبلغِ تخفیف»، نه قیمتِ نهایی. (سفارش ۲۰۹۷:
//     ۷٬۵۰۰٬۰۰۰ − ۲۷۲٬۰۰۰ = ۷٬۲۲۸٬۰۰۰ که همان مبلغِ پرداختِ متناظر است.)
//   • order_shipping_price = کرایه‌ای که واقعاً گرفته شده (۰ در ارسال رایگان).
//     post_/peyk_shipping_price و free_shipping_threshold فقط تنظیماتِ فروشگاه‌اند.
//   • هر قلم یا product دارد یا course؛ classes و support_coach تا امروز
//     همیشه null بوده‌اند.
//   • آدرس یک رشته‌ی تخت است با فیلدهای برچسب‌دار داخلش (postal code، …).

import 'package:marketky/utils/jalali_date.dart';

/// وضعیت سفارش — مقادیر دیده‌شده: pending، failed، wait_for_admin.
enum OrderStatus { pending, waitForAdmin, paid, sent, delivered, failed, canceled, unknown }

extension OrderStatusInfo on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'در انتظار پرداخت';
      case OrderStatus.waitForAdmin:
        return 'در انتظار تأیید';
      case OrderStatus.paid:
        return 'پرداخت شد';
      case OrderStatus.sent:
        return 'ارسال شد';
      case OrderStatus.delivered:
        return 'تحویل داده شد';
      case OrderStatus.failed:
        return 'ناموفق';
      case OrderStatus.canceled:
        return 'لغو شد';
      case OrderStatus.unknown:
        return 'نامشخص';
    }
  }

  /// جایگاه روی خط زمانیِ سفارش؛ -۱ یعنی سفارش از مسیر خارج شده.
  int get timelineIndex {
    switch (this) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.waitForAdmin:
      case OrderStatus.paid:
        return 1;
      case OrderStatus.sent:
        return 2;
      case OrderStatus.delivered:
        return 3;
      case OrderStatus.failed:
      case OrderStatus.canceled:
      case OrderStatus.unknown:
        return -1;
    }
  }

  bool get isTerminalFailure =>
      this == OrderStatus.failed || this == OrderStatus.canceled;

  static OrderStatus parse(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'wait_for_admin':
        return OrderStatus.waitForAdmin;
      case 'paid':
      case 'success':
      case 'completed':
        return OrderStatus.paid;
      case 'sent':
      case 'shipped':
        return OrderStatus.sent;
      case 'delivered':
        return OrderStatus.delivered;
      case 'failed':
        return OrderStatus.failed;
      case 'canceled':
      case 'cancelled':
        return OrderStatus.canceled;
      default:
        return OrderStatus.unknown;
    }
  }
}

/// مراحل خط زمانیِ سفارش، به ترتیب.
const List<String> kOrderTimeline = [
  'ثبت سفارش',
  'پرداخت و تأیید',
  'ارسال',
  'تحویل',
];

class OrderPrice {
  /// جمعِ قیمتِ اقلام قبل از تخفیف
  final int subtotal;

  /// مبلغِ تخفیف (نه قیمتِ نهایی)
  final int discount;

  /// مالیات/عوارض؛ تا امروز همیشه صفر بوده
  final int nat;
  final int shipping;
  final bool isFreeShipping;
  final int freeShippingThreshold;
  final int postShippingPrice;
  final int peykShippingPrice;

  const OrderPrice({
    required this.subtotal,
    required this.discount,
    required this.nat,
    required this.shipping,
    required this.isFreeShipping,
    required this.freeShippingThreshold,
    required this.postShippingPrice,
    required this.peykShippingPrice,
  });

  int get payable => subtotal - discount + nat + shipping;

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v == null) return 0;
    return double.tryParse('$v')?.round() ?? 0;
  }

  factory OrderPrice.fromJson(Map<String, dynamic>? json) {
    final j = json ?? const <String, dynamic>{};
    return OrderPrice(
      subtotal: _int(j['price']),
      discount: _int(j['discounted_price']),
      nat: _int(j['nat']),
      shipping: _int(j['order_shipping_price']),
      isFreeShipping: j['is_free_shipping'] == true,
      freeShippingThreshold: _int(j['free_shipping_threshold']),
      postShippingPrice: _int(j['post_shipping_price']),
      peykShippingPrice: _int(j['peyk_shipping_price']),
    );
  }
}

/// یک قلم سفارش: یا محصول است یا دوره.
class OrderLine {
  final int id;
  final int quantity;

  final String title;
  final String? image;

  /// قیمتِ واحد قبل از تخفیف
  final int unitPrice;
  final int discountPercentage;

  /// فقط برای محصول
  final String? size;
  final String? color;
  final String? colorRgb;

  /// فقط برای دوره
  final String? location;
  final String? time;

  final bool isCourse;

  const OrderLine({
    required this.id,
    required this.quantity,
    required this.title,
    required this.image,
    required this.unitPrice,
    required this.discountPercentage,
    required this.isCourse,
    this.size,
    this.color,
    this.colorRgb,
    this.location,
    this.time,
  });

  int get finalUnitPrice => discountPercentage > 0 && discountPercentage < 100
      ? (unitPrice * (100 - discountPercentage) / 100).round()
      : unitPrice;

  int get lineTotal => finalUnitPrice * quantity;

  bool get hasDiscount => discountPercentage > 0 && discountPercentage < 100;

  static int _int(dynamic v) => OrderPrice._int(v);

  static String _str(dynamic v) => v == null ? '' : '$v';

  static OrderLine? fromJson(Map<String, dynamic> json) {
    final int id = _int(json['id']);
    final int qty = _int(json['quantity']) == 0 ? 1 : _int(json['quantity']);

    final product = json['product'];
    if (product is Map<String, dynamic>) {
      final variant = product['product_variant'];
      final v = variant is Map<String, dynamic> ? variant : const <String, dynamic>{};
      return OrderLine(
        id: id,
        quantity: qty,
        title: _str(v['product_name']),
        image: v['image'] as String? ?? v['icon'] as String?,
        unitPrice: _int(product['price']),
        discountPercentage: _int(product['discount_percentage']),
        size: product['size'] == null ? null : _str(product['size']),
        color: v['color'] as String?,
        colorRgb: v['color_rgb'] as String?,
        isCourse: false,
      );
    }

    final course = json['course'];
    if (course is Map<String, dynamic>) {
      return OrderLine(
        id: id,
        quantity: qty,
        title: _str(course['course_name']),
        image: course['image'] as String?,
        unitPrice: _int(course['price']),
        discountPercentage: _int(course['discount_percentage']),
        location: course['location'] as String?,
        time: course['time'] as String?,
        isCourse: true,
      );
    }

    // classes / support_coach هنوز از سرور نیامده‌اند؛ قلمِ ناشناخته نمایش
    // داده نمی‌شود تا کارتِ خالی و بی‌معنی ساخته نشود.
    return null;
  }
}

/// آدرسِ سفارش. سرور یک رشته‌ی تخت می‌دهد؛ اینجا به بخش‌های خوانا شکسته می‌شود.
class OrderAddress {
  final String line;
  final String? postalCode;
  final String? receiverPhone;
  final String? homePhone;
  final String? name;
  final String raw;

  const OrderAddress({
    required this.line,
    required this.raw,
    this.postalCode,
    this.receiverPhone,
    this.homePhone,
    this.name,
  });

  bool get isEmpty => raw.trim().isEmpty;

  static String? _grab(String s, String label) {
    // «postal code: 1473837515,» → 1473837515
    final re = RegExp('$label\\s*:\\s*([^,]+)', caseSensitive: false);
    final m = re.firstMatch(s);
    final v = m?.group(1)?.trim();
    return (v == null || v.isEmpty || v.toLowerCase() == 'none') ? null : v;
  }

  factory OrderAddress.parse(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) {
      return const OrderAddress(line: '', raw: '');
    }
    // بخش‌های بی‌برچسب (استان، شهر، نشانی) تا اولین فیلدِ برچسب‌دار
    final parts = s.split(',');
    final plain = <String>[];
    for (final p in parts) {
      if (p.contains(':')) break;
      final t = p.trim();
      if (t.isNotEmpty) plain.add(t);
    }
    return OrderAddress(
      line: plain.join('، '),
      raw: s,
      postalCode: _grab(s, 'postal code'),
      receiverPhone: _grab(s, 'receiver phone'),
      homePhone: _grab(s, 'receiver_home_phone'),
      name: _grab(s, 'address name'),
    );
  }
}

class Order {
  final int id;
  final String? trackingCode;
  final OrderStatus status;
  final String deliveryMethod;
  final OrderAddress address;
  final DateTime? createdAt;
  final OrderPrice price;
  final List<OrderLine> items;

  const Order({
    required this.id,
    required this.trackingCode,
    required this.status,
    required this.deliveryMethod,
    required this.address,
    required this.createdAt,
    required this.price,
    required this.items,
  });

  String get deliveryLabel {
    switch (deliveryMethod.trim().toLowerCase()) {
      case 'post':
        return 'پست';
      case 'peyk':
        return 'پیک';
      case 'free':
        return 'ارسال رایگان';
      default:
        return deliveryMethod.isEmpty ? 'نامشخص' : deliveryMethod;
    }
  }

  /// دوره نیاز به ارسال ندارد؛ سفارشِ کاملاً دیجیتال آدرس و مرسوله ندارد.
  bool get needsShipping => items.any((i) => !i.isCourse);

  int get itemCount =>
      items.fold<int>(0, (sum, i) => sum + i.quantity);

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['order_items'];
    final items = <OrderLine>[];
    if (rawItems is List) {
      for (final e in rawItems) {
        if (e is Map<String, dynamic>) {
          final line = OrderLine.fromJson(e);
          if (line != null) items.add(line);
        }
      }
    }
    final tc = json['tracking_code'];
    final tcs = tc == null ? null : '$tc'.trim();
    return Order(
      id: OrderPrice._int(json['id']),
      // سرور برای سفارشِ پرداخت‌نشده رشته‌ی "None" می‌فرستد، نه null
      trackingCode:
          (tcs == null || tcs.isEmpty || tcs.toLowerCase() == 'none') ? null : tcs,
      status: OrderStatusInfo.parse('${json['order_status'] ?? ''}'),
      deliveryMethod: '${json['delivery_method'] ?? ''}',
      address: OrderAddress.parse(json['address'] as String?),
      createdAt: parseServerDate(json['created_at'] as String?),
      price: OrderPrice.fromJson(json['price'] as Map<String, dynamic>?),
      items: items,
    );
  }
}

class OrdersPageResult {
  final int count;
  final String? next;
  final List<Order> results;

  const OrdersPageResult({
    required this.count,
    required this.next,
    required this.results,
  });

  factory OrdersPageResult.fromJson(Map<String, dynamic> json) {
    final list = <Order>[];
    for (final e in (json['results'] as List? ?? const [])) {
      if (e is Map<String, dynamic>) list.add(Order.fromJson(e));
    }
    return OrdersPageResult(
      count: OrderPrice._int(json['count']),
      next: json['next'] as String?,
      results: list,
    );
  }
}
