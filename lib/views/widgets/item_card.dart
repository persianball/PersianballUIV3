import 'package:flutter/material.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:persian_ball/utils/ThousandsFormatter.dart';
import 'package:persian_ball/views/widgets/app_network_image.dart';
import 'package:persian_ball/views/widgets/motion.dart';

import '../../constant/urls.dart';
import '../../models/ProductModel.dart';

class ItemCard extends StatelessWidget {
  final Product product;
  final Color? titleColor;
  final Color? priceColor;

  /// مقدار اضافه‌شده به عرض/ارتفاع کارت نسبت به اندازه پیش‌فرض
  final double extraSize;

  /// دیگر اثری بر ظاهر ندارد؛ فقط برای سازگاری با فراخوانی‌های قدیمی
  /// نگه داشته شده است.
  final bool dark;

  /// دکمه «افزودن به سبد» زیر قیمت نمایش داده شود (طرح فروشگاه).
  /// چون مدل لیست محصول (Product) رنگ/سایز ندارد و بدون انتخاب واریانت
  /// نمی‌توان مطمئن به سبد افزود، این دکمه همیشه به صفحه جزئیات هدایت می‌کند
  /// (همان‌جا که انتخاب رنگ/سایز واقعی و افزودن واقعی انجام می‌شود).
  final bool showAddToCartButton;

  ItemCard({
    required this.product,
    this.titleColor,
    this.priceColor,
    this.extraSize = 0,
    this.dark = false,
    this.showAddToCartButton = false,
  });

  // ارتفاع ثابت ردیف بج تخفیف + قیمت خط‌خورده
  static const double _discountRowHeight = 16;

  Widget _buildPrice() {
    final int originalPrice = product.price ?? 0;
    final int? percent = product.discountPercentage;
    final bool hasDiscount =
        percent != null && percent > 0 && percent < 100 && originalPrice > 0;

    final int finalPrice = hasDiscount
        ? (originalPrice * (1 - percent / 100)).toInt()
        : originalPrice;

    const Color mutedColor = AppColor.inkMuted;
    final Color resolvedPriceColor = priceColor ?? AppColor.pitchGreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // اگر API قیمت نداده باشد، به‌جای صفر متن راهنما نمایش داده می‌شود
        SizedBox(
          height: 22,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              originalPrice > 0 ? thousandSeparator(finalPrice) : 'مشاهده قیمت',
              style: TextStyle(
                fontSize: originalPrice > 0 ? 16 : 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'Estedad',
                color: originalPrice > 0 ? resolvedPriceColor : mutedColor,
              ),
            ),
          ),
        ),
        // ارتفاع ثابت تا کارت‌های با تخفیف و بدون تخفیف هم‌تراز بمانند
        SizedBox(
          height: _discountRowHeight,
          child: !hasDiscount
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: const ShapeDecoration(
                        color: AppColor.danger,
                        shape: StadiumBorder(),
                      ),
                      child: Text(
                        '٪$percent',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Estedad',
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        thousandSeparator(originalPrice),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Estedad',
                          color: mutedColor,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: mutedColor,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  void _goToDetail(BuildContext context) {
    Navigator.of(context).pushNamed('/product/${product.id}');
  }

  @override
  Widget build(BuildContext context) {
    final double rawWidth =
        MediaQuery.of(context).size.width / 2 - 16 - 8 + extraSize;
    // Clamped so cards keep a sane, catalog-like size on tablet/desktop
    // instead of scaling up with the full screen width.
    final double cardWidth = rawWidth.clamp(130.0, 200.0);
    final Color resolvedTitleColor = titleColor ?? AppColor.ink;

    return PressableScale(
      onTap: () => _goToDetail(context),
      child: Container(
        width: cardWidth,
        decoration: ShapeDecoration(
          color: AppColor.card,
          shape: AppShapes.border(AppShapes.rMd),
          shadows: AppColor.cardShadow,
        ),
        child: SquircleClip(
          radius: AppShapes.rMd,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // تصویر مربع کامل تا کارت‌ها در گرید هم‌اندازه بمانند
              AspectRatio(
                aspectRatio: 1,
                child: AppNetworkImage(
                  url: '${URLs.baseUrl}${product.image ?? ''}',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),

              // item details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 30,
                      child: Text(
                        '${product.nameFarsi}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: resolvedTitleColor,
                        ),
                      ),
                    ),
                    _buildPrice(),
                    if (showAddToCartButton) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _goToDetail(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColor.pitchGreen,
                            side: const BorderSide(color: AppColor.pitchGreen),
                            shape: AppShapes.pill,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(
                            'افزودن به سبد',
                            style: TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
