// views/widgets/modals/add_to_cart_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/bloc/cart/cart_bloc.dart';
import 'package:marketky/services/analytics_service.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/constant/urls.dart';
import 'package:marketky/models/CartModel.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/utils/login_prompt.dart';
import 'package:marketky/views/widgets/app_buttons.dart';
import 'package:marketky/views/widgets/app_network_image.dart';
import 'package:marketky/views/widgets/page_container.dart';

/// نتیجه‌ی شیت پس از افزودن موفق: مبدأ انیمیشنِ افتادن کالا داخل سبد.
///
/// شیت خودش انیمیشن را اجرا نمی‌کند (با بسته‌شدنش از بین می‌رفت)؛ فقط
/// می‌گوید تصویر کالا کجای صفحه بود و صفحه‌ی محصول بقیه‌اش را انجام می‌دهد.
class AddToCartLaunch {
  const AddToCartLaunch({required this.sourceRect, required this.imageUrl});

  final Rect sourceRect;
  final String imageUrl;
}

class AddToCartModal extends StatefulWidget {
  final CartItem cartItem; // محصولی که کاربر می‌خواهد اضافه کند

  /// تعدادی که کاربر در صفحه‌ی محصول انتخاب کرده است
  final int initialQuantity;

  const AddToCartModal({
    Key? key,
    required this.cartItem,
    this.initialQuantity = 1,
  }) : super(key: key);

  @override
  _AddToCartModalState createState() => _AddToCartModalState();
}

class _AddToCartModalState extends State<AddToCartModal> {
  late int _quantity;

  /// تصویر کالا داخل شیت — مبدأ انیمیشنِ افتادن داخل سبد
  final GlobalKey _thumbKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity < 1 ? 1 : widget.initialQuantity;
  }

  @override
  Widget build(BuildContext context) {
    // محاسبات دقیقاً مثل قبل
    final totalPrice = widget.cartItem.price * _quantity;
    final discoutedPrice = widget.cartItem.discountPrice != null
        ? ((widget.cartItem.discountPrice! / 100) * totalPrice).toInt()
        : 0;
    final payable = totalPrice - discoutedPrice;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        child: PageContainer(
          maxWidth: 700.0,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: ShapeDecoration(
              color: AppColor.milk,
              shape: ContinuousRectangleBorder(
                borderRadius: AppShapes.radiusTop(AppShapes.rXl),
              ),
              shadows: AppColor.floatingShadow,
            ),
            padding: EdgeInsets.only(
              left: 14,
              right: 14,
              top: 10,
              // فضای نوار ناوبری سیستم تا دکمه افزودن زیر آن گیر نکند
              bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // دستگیره‌ی کشیدن
                Container(
                  width: 46,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: const ShapeDecoration(
                    color: AppColor.line,
                    shape: StadiumBorder(),
                  ),
                ),

                // سربرگ: عنوان + میان‌بر به سبد
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
                  child: Row(
                    children: [
                      const Text(
                        'سبد من',
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColor.ink,
                        ),
                      ),
                      const Spacer(),
                      SoftButton(
                        label: 'مشاهده سبد',
                        expand: false,
                        height: 38,
                        icon: const Icon(Icons.shopping_bag_outlined),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed('/cart');
                        },
                      ),
                    ],
                  ),
                ),

                // کارت کالا
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: ShapeDecoration(
                    color: AppColor.card,
                    shape: AppShapes.border(AppShapes.rLg),
                    shadows: AppColor.cardShadow,
                  ),
                  child: Row(
                    children: [
                      SquircleClip(
                        radius: AppShapes.rMd,
                        child: Container(
                          key: _thumbKey,
                          width: 56,
                          height: 56,
                          color: AppColor.cardMuted,
                          padding: const EdgeInsets.all(4),
                          child: AppNetworkImage(
                            url: _imageUrl(widget.cartItem.image),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.cartItem.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Estedad',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColor.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'تعداد: $_quantity',
                              style: const TextStyle(
                                fontFamily: 'Estedad',
                                fontSize: 11,
                                color: AppColor.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: const ShapeDecoration(
                          color: AppColor.darkButton,
                          shape: StadiumBorder(),
                        ),
                        child: Text(
                          thousandSeparator(payable),
                          style: const TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: AppColor.inkMuted),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // تعداد + جمع‌بندی مبلغ
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  decoration: ShapeDecoration(
                    color: AppColor.card,
                    shape: AppShapes.border(AppShapes.rLg),
                    shadows: AppColor.cardShadow,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'تعداد',
                            style: TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 13,
                              color: AppColor.inkMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          _StepperButton(
                            icon: Icons.remove_rounded,
                            onTap: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                          ),
                          Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Estedad',
                                color: AppColor.ink,
                              ),
                            ),
                          ),
                          _StepperButton(
                            icon: Icons.add_rounded,
                            filled: true,
                            onTap: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColor.line),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: 'قیمت',
                        value: '${thousandSeparator(totalPrice)} تومان',
                      ),
                      const SizedBox(height: 8),
                      _SummaryRow(
                        label: 'تخفیف',
                        value:
                            '${widget.cartItem.discountPrice != null ? thousandSeparator(discoutedPrice) : 0} (٪${widget.cartItem.discountPrice ?? 0})',
                        valueColor: discoutedPrice > 0
                            ? AppColor.danger
                            : AppColor.inkMuted,
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColor.line),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: 'مبلغ قابل پرداخت',
                        value: '${thousandSeparator(payable)} تومان',
                        bold: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // دکمه افزودن — همان منطق قبلی
                GradientButton(
                  label: 'افزودن به سبد',
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  onPressed: () {
                    if (!isLoggedIn(context)) {
                      Navigator.of(context).pop();
                      promptLoginIfNeeded(context);
                      return;
                    }
                    AnalyticsService.addToCart(
                      productId: widget.cartItem.productId,
                      quantity: _quantity,
                      price: widget.cartItem.price,
                    );
                    context
                        .read<CartBloc>()
                        .add(AddToCart(context, widget.cartItem.id, _quantity));

                    // مختصات تصویر را پیش از بسته‌شدن شیت برمی‌داریم؛ بعد از
                    // pop دیگر رندرآبجکتی در کار نیست.
                    final box = _thumbKey.currentContext?.findRenderObject();
                    final rect = (box is RenderBox && box.hasSize)
                        ? box.localToGlobal(Offset.zero) & box.size
                        : null;

                    Navigator.of(context).pop(
                      rect == null
                          ? null
                          : AddToCartLaunch(
                              sourceRect: rect,
                              imageUrl: _imageUrl(widget.cartItem.image),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _imageUrl(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    return '${URLs.baseUrl}$raw';
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Container(
        width: 34,
        height: 34,
        decoration: ShapeDecoration(
          color: filled ? null : AppColor.cardMuted,
          gradient: filled ? AppColor.greenGradient : null,
          shape: const CircleBorder(),
          shadows: filled && enabled ? AppColor.greenShadow : null,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Icon(icon,
                size: 18,
                color: filled ? AppColor.onPitchGreen : AppColor.ink),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Estedad',
            fontSize: bold ? 14 : 13,
            color: bold ? AppColor.ink : AppColor.inkMuted,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Estedad',
            fontSize: bold ? 15 : 13,
            color: valueColor ?? (bold ? AppColor.pitchGreen : AppColor.ink),
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
