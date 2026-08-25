// lib/views/screens/order_detail_page.dart
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/payment_models.dart';
import 'package:marketky/services/order_detail_service.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';

/// جزئیات یک سفارش: اقلام، پیگیری مرسوله، صورتحساب و اقدامات
class OrderDetailPage extends StatefulWidget {
  final PaymentItem payment;

  const OrderDetailPage({super.key, required this.payment});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  OrderDetail? _detail;
  bool _loading = true;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final detail = await OrderDetailService.fetchDetail(widget.payment);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.obsidianBg,
        appBar: AppBar(
          backgroundColor: AppColor.obsidianBg,
          foregroundColor: AppColor.onSurface,
          elevation: 0,
          title: Text('سفارش #${widget.payment.id}',
              style: const TextStyle(
                  fontFamily: 'Estedad', fontSize: 16, color: AppColor.onSurface)),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColor.goldEnd))
            : _buildContent(_detail!),
      ),
    );
  }

  Widget _buildContent(OrderDetail d) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (d.isMock) _mockBanner(),
          _trackingCard(d),
          const SizedBox(height: 12),
          _itemsCard(d),
          const SizedBox(height: 12),
          _addressCard(d),
          const SizedBox(height: 12),
          _invoiceCard(d),
          const SizedBox(height: 16),
          if (d.canCancel)
            _dangerButton('لغو سفارش', () => _confirmAction(d, isCancel: true)),
          if (d.canReturn)
            _dangerButton(
                'درخواست مرجوعی', () => _confirmAction(d, isCancel: false)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _mockBanner() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColor.goldEnd.withOpacity(0.08),
          border: Border.all(color: AppColor.goldEnd.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: AppColor.goldEnd),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'اقلام و وضعیت مرسوله نمایشی است؛ بک‌اند هنوز endpoint جزئیات سفارش ندارد.',
                style: TextStyle(fontFamily: 'Estedad', fontSize: 11, color: AppColor.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );

  Widget _card({required String title, required Widget child}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColor.surfaceContainer,
          border: Border.all(color: AppColor.outlineVariantDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColor.onSurface)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );

  Widget _trackingCard(OrderDetail d) {
    return _card(
      title: 'پیگیری مرسوله',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...ShipmentStep.values.map((step) {
            final done = step.index <= d.currentStep.index;
            final isLast = step == ShipmentStep.values.last;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(
                        done
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: done ? AppColor.goldEnd : AppColor.onSurfaceVariant,
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color:
                                done ? AppColor.goldEnd : AppColor.outlineVariantDark,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Text(
                      step.title,
                      style: TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 13,
                        fontWeight: done ? FontWeight.w700 : FontWeight.w400,
                        color: done ? AppColor.onSurface : AppColor.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Divider(height: 20, color: AppColor.outlineVariantDark),
          _infoRow('شرکت حمل', d.carrier),
          if (d.shipmentTrackingNumber != null)
            _infoRow('کد رهگیری مرسوله', d.shipmentTrackingNumber!),
          _infoRow('کد پیگیری پرداخت', d.trackingCode),
          _infoRow('تاریخ ثبت', d.createdAt),
        ],
      ),
    );
  }

  Widget _itemsCard(OrderDetail d) {
    return _card(
      title: 'اقلام سفارش',
      child: Column(
        children: d.items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColor.obsidianBg,
                    border: Border.all(color: AppColor.outlineVariantDark),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: AppColor.onSurfaceVariant, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: const TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColor.onSurface)),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (item.color != null) 'رنگ: ${item.color}',
                          if (item.size != null) 'سایز: ${item.size}',
                          'تعداد: ${item.quantity}',
                        ].join('  •  '),
                        style: const TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 11,
                            color: AppColor.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text('${thousandSeparator(item.total)} تومان',
                    style: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColor.goldEnd)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _addressCard(OrderDetail d) => _card(
        title: 'آدرس تحویل',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(d.address,
                style: const TextStyle(
                    fontFamily: 'Estedad', fontSize: 13, color: AppColor.onSurface)),
            const SizedBox(height: 8),
            _infoRow('روش ارسال', d.deliveryMethod == 'peyk' ? 'پیک' : 'پست'),
          ],
        ),
      );

  Widget _invoiceCard(OrderDetail d) => _card(
        title: 'صورتحساب',
        child: Column(
          children: [
            _infoRow('قیمت کل', '${thousandSeparator(d.price)} تومان'),
            _infoRow('تخفیف', '-${thousandSeparator(d.discount)} تومان',
                valueColor: AppColor.errorDark),
            _infoRow('مالیات', '${thousandSeparator(d.tax)} تومان'),
            _infoRow(
                'هزینه ارسال',
                d.shippingPrice == 0
                    ? 'رایگان'
                    : '${thousandSeparator(d.shippingPrice)} تومان',
                valueColor: d.shippingPrice == 0 ? AppColor.successDark : null),
            Divider(height: 20, color: AppColor.outlineVariantDark),
            _infoRow('مبلغ پرداخت‌شده', '${thousandSeparator(d.payable)} تومان',
                bold: true),
          ],
        ),
      );

  Widget _infoRow(String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 12,
                  color: AppColor.onSurfaceVariant)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Estedad',
                fontSize: bold ? 14 : 12,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: valueColor ?? AppColor.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dangerButton(String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _acting ? null : onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: AppShapes.pill,
            ),
            child: Text(label, style: const TextStyle(fontFamily: 'Estedad')),
          ),
        ),
      );

  Future<void> _confirmAction(OrderDetail d, {required bool isCancel}) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColor.surfaceContainerOpaque,
          shape: AppShapes.border(AppShapes.rLg),
          title: Text(isCancel ? 'لغو سفارش' : 'درخواست مرجوعی',
              style: const TextStyle(
                  fontFamily: 'Estedad', fontSize: 16, color: AppColor.onSurface)),
          content: TextField(
            controller: reasonCtrl,
            style: const TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface),
            decoration: const InputDecoration(
              hintText: 'دلیل خود را بنویسید (اختیاری)',
              hintStyle: TextStyle(
                  fontFamily: 'Estedad', fontSize: 12, color: AppColor.onSurfaceVariant),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('انصراف',
                  style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurfaceVariant)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('تأیید',
                  style: TextStyle(fontFamily: 'Estedad', color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    setState(() => _acting = true);
    final ok = isCancel
        ? await OrderDetailService.cancelOrder(d.id, reasonCtrl.text)
        : await OrderDetailService.requestReturn(d.id, reasonCtrl.text);
    if (!mounted) return;
    setState(() => _acting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (isCancel
                  ? 'درخواست لغو ثبت شد (شبیه‌سازی — نیازمند endpoint بک‌اند)'
                  : 'درخواست مرجوعی ثبت شد (شبیه‌سازی — نیازمند endpoint بک‌اند)')
              : 'ثبت درخواست ناموفق بود',
          style: const TextStyle(fontFamily: 'Estedad'),
        ),
      ),
    );
  }
}
