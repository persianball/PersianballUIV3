// lib/utils/order_totals.dart
//
// جمع‌های خلاصه‌ی سفارش. ورودی‌ها عیناً از آبجکتِ price ِ سبد می‌آیند؛ تنها
// چیزی که اینجا حساب می‌شود کدِ تخفیف است، چون بک‌اند برای آن فقط درصد
// برمی‌گرداند ({"discount_percent": 100}) و مبلغی نمی‌دهد.
//
// نسخه‌ی قبلی با «base - base*pct/100» مبلغِ باقی‌مانده را به‌جای تخفیف
// نشان می‌داد: با کدِ ۱۰۰٪ ردیفِ تخفیف ۰ و مبلغِ پرداختی برابرِ قیمتِ کامل
// می‌شد؛ مالیات و ارسال هم به ردیفِ تخفیف اضافه می‌شدند.
class OrderTotals {
  const OrderTotals({
    required this.base,
    required this.productDiscount,
    required this.voucherPercent,
    required this.voucherAmount,
    required this.tax,
    required this.shipping,
    required this.freeShipping,
    required this.payable,
  });

  /// قیمتِ کلِ کالاها (price.price)
  final int base;

  /// تخفیفِ خودِ کالاها (price.discounted_price)
  final int productDiscount;

  final int voucherPercent;

  /// مبلغِ کدِ تخفیف، روی مبلغِ بعد از تخفیفِ کالاها
  final int voucherAmount;
  final int tax;
  final int shipping;
  final bool freeShipping;

  /// base − تخفیفِ کالا − کدِ تخفیف + مالیات + ارسال (هرگز منفی نمی‌شود)
  final int payable;

  int get subtotal => (base - productDiscount).clamp(0, 1 << 62);
  bool get hasVoucher => voucherPercent > 0;

  static OrderTotals compute({
    required int base,
    required int productDiscount,
    required int tax,
    required int shipping,
    required bool freeShipping,
    int voucherPercent = 0,
  }) {
    final int subtotal = (base - productDiscount).clamp(0, 1 << 62);
    final int pct = voucherPercent.clamp(0, 100);
    // گرد به بالا به نفعِ مشتری؛ حسابِ صحیح، نه اعشار
    final int voucher = pct == 0 ? 0 : (subtotal * pct + 99) ~/ 100;
    final int ship = freeShipping ? 0 : shipping;
    final int payable = (subtotal - voucher + tax + ship).clamp(0, 1 << 62);
    return OrderTotals(
      base: base,
      productDiscount: productDiscount,
      voucherPercent: pct,
      voucherAmount: voucher,
      tax: tax,
      shipping: ship,
      freeShipping: freeShipping,
      payable: payable,
    );
  }
}
