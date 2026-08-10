// lib/services/order_detail_service.dart
//
// جزئیات سفارش و پیگیری مرسوله.
//
// وضعیت بک‌اند: لیست پرداخت‌ها (/v1/payment/payments/) فقط
// {id, user, tracking_code, status, price} می‌دهد؛ نه اقلام سفارش، نه آدرس،
// نه وضعیت مرسوله. endpoint جزئیات سفارش هم موجود نیست.
//
// پیشنهاد برای بک‌اند (وقتی آماده شد فقط همین فایل عوض می‌شود):
//   GET /v1/order/order/<id>/  →
//   {
//     "id": 12, "tracking_code": "…", "status": "success",
//     "created_at": "2026-08-01T10:00:00Z",
//     "price": 4200000, "discount": 200000, "tax": 90000, "shipping_price": 60000,
//     "payable": 4150000,
//     "delivery_method": "post", "address": {...},
//     "items": [{"title": "...", "image": "...", "quantity": 1, "unit_price": 0,
//                "discount_percentage": 0, "size": "42", "color": "مشکی"}],
//     "shipment": {"carrier": "پست پیشتاز", "tracking_number": "…",
//                  "steps": [{"code": "paid", "at": "..."}, ...]},
//     "can_cancel": true, "can_return": false
//   }
//   POST /v1/order/order/<id>/cancel/   {reason}
//   POST /v1/order/order/<id>/return/   {reason, items: [...]}
//
// تا آن زمان: داده‌ی نمایشی (ماک) از روی همان اطلاعات واقعی پرداخت ساخته می‌شود
// تا بک‌اند شکل نهایی UI و فیلدهای لازم را ببیند.
import 'package:marketky/models/payment_models.dart';

class OrderItemLine {
  final String title;
  final String? image;
  final int quantity;
  final int unitPrice;
  final String? size;
  final String? color;

  const OrderItemLine({
    required this.title,
    this.image,
    required this.quantity,
    required this.unitPrice,
    this.size,
    this.color,
  });

  int get total => unitPrice * quantity;
}

/// مراحل پیگیری سفارش به ترتیب
enum ShipmentStep { paid, processing, shipped, delivered }

extension ShipmentStepFa on ShipmentStep {
  String get title {
    switch (this) {
      case ShipmentStep.paid:
        return 'پرداخت شد';
      case ShipmentStep.processing:
        return 'در حال آماده‌سازی';
      case ShipmentStep.shipped:
        return 'ارسال شد';
      case ShipmentStep.delivered:
        return 'تحویل داده شد';
    }
  }
}

class OrderDetail {
  final int id;
  final String trackingCode;
  final String status;
  final int price;
  final int discount;
  final int tax;
  final int shippingPrice;
  final String deliveryMethod;
  final String address;
  final String createdAt;
  final List<OrderItemLine> items;
  final String carrier;
  final String? shipmentTrackingNumber;
  final ShipmentStep currentStep;
  final bool canCancel;
  final bool canReturn;

  /// true یعنی این داده ماک است و از بک‌اند نیامده
  final bool isMock;

  const OrderDetail({
    required this.id,
    required this.trackingCode,
    required this.status,
    required this.price,
    required this.discount,
    required this.tax,
    required this.shippingPrice,
    required this.deliveryMethod,
    required this.address,
    required this.createdAt,
    required this.items,
    required this.carrier,
    required this.shipmentTrackingNumber,
    required this.currentStep,
    required this.canCancel,
    required this.canReturn,
    this.isMock = false,
  });

  int get payable => price - discount + tax + shippingPrice;
}

class OrderDetailService {
  /// تا زمانی که endpoint جزئیات سفارش ساخته شود، از روی داده واقعی پرداخت
  /// یک جزئیات نمایشی می‌سازد. مقادیر ماک قطعی (deterministic) هستند تا هر بار
  /// یکسان دیده شوند.
  static Future<OrderDetail> fetchDetail(PaymentItem payment) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final step = _stepFor(payment.status, payment.id);
    final base = payment.price;
    final discount = (base * 0.05).round();
    final tax = (base * 0.09).round();
    final shipping = payment.id.isEven ? 60000 : 0;

    return OrderDetail(
      id: payment.id,
      trackingCode: payment.trackingCode,
      status: payment.status,
      price: base,
      discount: discount,
      tax: tax,
      shippingPrice: shipping,
      deliveryMethod: payment.id.isEven ? 'post' : 'peyk',
      address: 'تهران، خیابان ولیعصر، پلاک ۱۲، واحد ۳',
      createdAt: '۱۴۰۴/۰۵/۱۲',
      carrier: payment.id.isEven ? 'پست پیشتاز' : 'پیک موتوری',
      shipmentTrackingNumber:
          step.index >= ShipmentStep.shipped.index ? '۲۴۰۰${payment.id}۷۷۱' : null,
      currentStep: step,
      canCancel: step.index <= ShipmentStep.processing.index &&
          payment.status.toLowerCase() != 'failed',
      canReturn: step == ShipmentStep.delivered,
      items: [
        OrderItemLine(
          title: 'کفش تروپیک فیل',
          quantity: 1,
          unitPrice: (base * 0.6).round(),
          size: '۴۲',
          color: 'مشکی',
        ),
        OrderItemLine(
          title: 'توپ فریستایل تاچ بال',
          quantity: 2,
          unitPrice: (base * 0.2).round(),
        ),
      ],
      isMock: true,
    );
  }

  static ShipmentStep _stepFor(String status, int id) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ShipmentStep.paid;
      case 'failed':
        return ShipmentStep.paid;
      case 'success':
      case 'paid':
      default:
        // برای اینکه UI همه حالت‌ها را نشان دهد، بر اساس id چرخانده می‌شود
        return ShipmentStep.values[1 + (id % 3)];
    }
  }

  /// لغو سفارش — تا وقتی endpoint ساخته نشده فقط موفقیت شبیه‌سازی می‌شود
  static Future<bool> cancelOrder(int orderId, String reason) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return true;
  }

  /// درخواست مرجوعی — همان وضعیت لغو
  static Future<bool> requestReturn(int orderId, String reason) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return true;
  }
}
