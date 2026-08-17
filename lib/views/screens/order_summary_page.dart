// lib/views/screens/order_summary_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/urls.dart';
import 'package:marketky/models/CartModel.dart';
import 'package:marketky/models/address_model.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/views/widgets/checkout_timeline.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderSummaryPage extends StatefulWidget {
  final AllCartFromBackend cart;
  final AddressModel address;
  final String deliveryMethod; // 'post' | 'peyk' | 'free'

  const OrderSummaryPage({
    super.key,
    required this.cart,
    required this.address,
    required this.deliveryMethod,
  });

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  final TextEditingController _discountCtrl = TextEditingController();
  bool _useWallet = false;
  bool _posting = false;
  int _discountPercent = 0;
  bool _applyingDiscount = false;

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Ask user to login if token is missing, then return token if available
  Future<String?> _requireToken() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      await _showLoginDialog();
      return null;
    }
    return token;
  }

  Future<void> _showLoginDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('نیاز به ورود دارید'),
          content:
              const Text('برای ادامه، لطفاً ابتدا وارد حساب کاربری خود شوید.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('انصراف'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushNamed(
                  '/login',
                  arguments: {'popOnSuccess': true},
                );
              },
              child: const Text('ورود'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyDiscountCode() async {
    if (_discountCtrl.text.trim().isEmpty) {
      _showSnack('لطفاً کد تخفیف را وارد کنید');
      return;
    }

    if (_applyingDiscount) return;

    setState(() => _applyingDiscount = true);

    try {
      final token = await _requireToken();
      if (token == null || token.isEmpty)
        return; // user canceled or not logged in
      final body = {
        'code': _discountCtrl.text.trim(),
      };

      final resp = await http.post(
        Uri.parse('${URLs.baseUrl}/v1/payment/voucher/verify/'),
        headers: {
          'Authorization': 'token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final discountPercent = data['discount_percent'] as int? ?? 0;

        setState(() => _discountPercent = discountPercent);

        if (discountPercent > 0) {
          _showSnack('کد تخفیف اعمال شد - ${discountPercent}% تخفیف');
        } else {
          _showSnack('کد تخفیف نامعتبر است');
        }
      } else {
        _showSnack('خطا در اعمال کد تخفیف (${resp.statusCode})');
      }
    } catch (e) {
      _showSnack('خطای شبکه/سرور: $e');
    } finally {
      if (mounted) setState(() => _applyingDiscount = false);
    }
  }

  Future<void> _submitOrder() async {
    if (_posting) return;
    setState(() => _posting = true);
    try {
      final token = await _requireToken();
      if (token == null || token.isEmpty) {
        setState(() => _posting = false);
        return;
      }
      final body = {
        'delivery_method': widget.deliveryMethod,
        'address': widget.address.id,
        'discount_code': _discountCtrl.text.trim().isEmpty
            ? null
            : _discountCtrl.text.trim(),
        'is_browser_view': true,
        'use_wallet': _useWallet,
      }..removeWhere((k, v) => v == null);

      final resp = await http.post(
        Uri.parse('${URLs.baseUrl}/v1/order/order/'),
        headers: {
          'Authorization': 'token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final redirectUrl = data['redirect_url'] as String?;
        if (redirectUrl != null && redirectUrl.isNotEmpty) {
          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (_) => PaymentWebViewPage(paymentUrl: redirectUrl),
          //   ),
          // );
          if (await canLaunchUrl(Uri.parse(redirectUrl))) {
            await launchUrl(Uri.parse(redirectUrl));
          }

          Navigator.pop(context);
        } else {
          _showSnack('پاسخ نامعتبر از سرور');
        }
      } else {
        _showSnack('خطا در ایجاد سفارش (${resp.statusCode})');
      }
    } catch (e) {
      _showSnack('خطای شبکه/سرور: $e');
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final hasCart = widget.cart.results.isNotEmpty;
    final items =
        hasCart ? widget.cart.results[0].items : <CartItemFromBackend>[];
    final price = hasCart ? widget.cart.results[0].price : TotalPriceFromBack();

    final base = price.price ?? 0;
    final discounted = price.discountedPrice ?? base;
    final tax = price.nat ?? 0;

    // Delivery cost based on chosen method
    final postPrice = price.postShippingPrice ?? 0;
    final peykPrice = price.peykShippingPrice ?? 0;
    final isFree =
        widget.deliveryMethod == 'free' || (price.isFreeShipping ?? false);
    final shippingCost =
        isFree ? 0 : (widget.deliveryMethod == 'peyk' ? peykPrice : postPrice);

    // اگر کد تخفیف اعمال شده باشد جای مقدار تخفیف بک‌اند می‌نشیند
    final discountBase = _discountPercent > 0
        ? base - (base * _discountPercent / 100)
        : discounted;

    // مقداری که در ردیف «تخفیف» نمایش داده می‌شود
    final displayedDiscount = discountBase + tax + shippingCost;

    // مبلغی که کاربر باید بپردازد
    final payable = base - discountBase;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.obsidianBg,
        appBar: AppBar(
          backgroundColor: AppColor.obsidianBg,
          foregroundColor: AppColor.onSurface,
          elevation: 0,
          title: const Text('خلاصه سفارش',
              style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface)),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: CheckoutTimeline(currentStep: 2),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Items summary
                    Container(
                      decoration: BoxDecoration(
                        color: AppColor.surfaceContainer,
                        border: Border.all(color: AppColor.outlineVariantDark),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('محصولات',
                                style: TextStyle(
                                    fontFamily: 'Estedad',
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.onSurface)),
                            const SizedBox(height: 8),
                            ...items.map((it) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          it.product?.productVariant
                                                  ?.productName ??
                                              'محصول',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontFamily: 'Estedad',
                                              color: AppColor.onSurface),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('x${it.quantity}',
                                          style: const TextStyle(
                                              fontFamily: 'Estedad',
                                              color: AppColor.onSurfaceVariant)),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Address and shipping summary
                    Container(
                      decoration: BoxDecoration(
                        color: AppColor.surfaceContainer,
                        border: Border.all(color: AppColor.outlineVariantDark),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('آدرس و ارسال',
                                style: TextStyle(
                                    fontFamily: 'Estedad',
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.onSurface)),
                            const SizedBox(height: 8),
                            Text(widget.address.addressName ?? 'آدرس انتخابی',
                                style: const TextStyle(
                                    fontFamily: 'Estedad', color: AppColor.onSurface)),
                            const SizedBox(height: 6),
                            Text(widget.address.address,
                                style: const TextStyle(
                                    fontFamily: 'Estedad',
                                    color: AppColor.onSurfaceVariant)),
                            const SizedBox(height: 6),
                            Wrap(spacing: 12, runSpacing: 6, children: [
                              if (widget.address.city != null)
                                _infoChip('شهر: ${widget.address.city}'),
                              if (widget.address.province != null)
                                _infoChip('استان: ${widget.address.province}'),
                              _infoChip(
                                  'روش ارسال: ${_deliveryLabel(widget.deliveryMethod)}'),
                            ]),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Discount code input
                    Container(
                      decoration: BoxDecoration(
                        color: AppColor.surfaceContainer,
                        border: Border.all(color: AppColor.outlineVariantDark),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('کد تخفیف',
                                style: TextStyle(
                                    fontFamily: 'Estedad',
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.onSurface)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _discountCtrl,
                                    style: const TextStyle(
                                        fontFamily: 'Estedad', color: AppColor.onSurface),
                                    decoration: InputDecoration(
                                      hintText: 'کد تخفیف خود را وارد کنید',
                                      hintStyle: const TextStyle(
                                          fontFamily: 'Estedad',
                                          color: AppColor.onSurfaceVariant),
                                      filled: true,
                                      fillColor: AppColor.obsidianBg,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.zero,
                                        borderSide:
                                            BorderSide(color: AppColor.outlineVariantDark),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.zero,
                                        borderSide:
                                            BorderSide(color: AppColor.outlineVariantDark),
                                      ),
                                      focusedBorder: const OutlineInputBorder(
                                        borderRadius: BorderRadius.zero,
                                        borderSide:
                                            BorderSide(color: AppColor.goldEnd, width: 2),
                                      ),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _applyingDiscount
                                      ? null
                                      : _applyDiscountCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColor.goldEnd,
                                    shape: const RoundedRectangleBorder(),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  child: _applyingDiscount
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColor.onGold,
                                          ),
                                        )
                                      : const Text('اعمال',
                                          style: TextStyle(
                                              fontFamily: 'Estedad',
                                              color: AppColor.onGold)),
                                ),
                              ],
                            ),
                            if (_discountPercent > 0) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColor.successDark.withOpacity(0.08),
                                  border: Border.all(
                                      color: AppColor.successDark.withOpacity(0.4)),
                                ),
                                child: Text(
                                  'کد تخفیف اعمال شد: ${_discountPercent}% تخفیف',
                                  style: const TextStyle(
                                    fontFamily: 'Estedad',
                                    color: AppColor.successDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Checkbox(
                                  value: _useWallet,
                                  activeColor: AppColor.goldEnd,
                                  onChanged: (v) =>
                                      setState(() => _useWallet = v ?? false),
                                ),
                                const Text('استفاده از کیف پول',
                                    style: TextStyle(
                                        fontFamily: 'Estedad', color: AppColor.onSurface)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Totals
                    Container(
                      decoration: BoxDecoration(
                        color: AppColor.surfaceContainer,
                        border: Border.all(color: AppColor.outlineVariantDark),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _priceRow('قیمت کل',
                                '${thousandSeparator(base)} تومان'),
                            _priceRow('تخفیف',
                                '${thousandSeparator(displayedDiscount.toInt())}- تومان',
                                valueColor: AppColor.errorDark),
                            _priceRow(
                                'مالیات', '${thousandSeparator(tax)} تومان'),
                            _priceRow(
                                'هزینه ارسال',
                                isFree
                                    ? 'رایگان'
                                    : '${thousandSeparator(shippingCost)} تومان',
                                valueColor: isFree ? AppColor.successDark : null),
                            Divider(height: 24, color: AppColor.outlineVariantDark),
                            _priceRow('مبلغ قابل پرداخت',
                                '${thousandSeparator(payable.toInt())} تومان',
                                valueColor: AppColor.goldEnd),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _posting ? null : _submitOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.goldEnd,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: _posting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColor.onGold))
                            : const Text('رفتن به درگاه پرداخت',
                                style: TextStyle(
                                    fontFamily: 'Estedad', color: AppColor.onGold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.obsidianBg,
        border: Border.all(color: AppColor.outlineVariantDark),
      ),
      child: Text(label,
          style: const TextStyle(
              fontFamily: 'Estedad', fontSize: 12, color: AppColor.onSurfaceVariant)),
    );
  }

  Widget _priceRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Estedad', fontSize: 14, color: AppColor.onSurfaceVariant)),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColor.onSurface)),
        ],
      ),
    );
  }

  String _deliveryLabel(String method) {
    switch (method) {
      case 'post':
        return 'پست';
      case 'peyk':
        return 'پیک';
      case 'free':
        return 'ارسال رایگان';
      default:
        return method;
    }
  }
}
