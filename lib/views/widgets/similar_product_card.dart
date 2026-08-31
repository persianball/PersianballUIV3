import 'package:flutter/material.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/views/widgets/motion.dart';

import '../../constant/app_color.dart';
import '../../constant/app_shapes.dart';
import '../../constant/urls.dart';
import '../../models/ProductModel.dart';

class SimilarProductCard extends StatelessWidget {
  final SimilarProduct product;

  const SimilarProductCard({Key? key, required this.product}) : super(key: key);

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${thousandSeparator(finalPrice)} تومان',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Estedad',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColor.ink,
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
                          color: AppColor.inkMuted,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColor.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed('/product/${product.id}');
      },
      child: Container(
        width: 160, // عرض ثابت برای اسلایدر افقی
        margin: const EdgeInsetsDirectional.only(start: 4, end: 8, bottom: 8),
        decoration: ShapeDecoration(
          color: AppColor.card,
          shape: AppShapes.border(AppShapes.rMd),
          shadows: AppColor.cardShadow,
        ),
        child: SquircleClip(
          radius: AppShapes.rMd,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // تصویر محصول
            Image.network(
                '${URLs.baseUrl}${product.image}',
                fit: BoxFit.cover,
                height: 128,
                width: 160,
                // اگر عکس لود نشد، تصویر پیش‌فرض نمایش داده می‌شود
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/placeholder.jpg',
                  fit: BoxFit.cover,
                  height: 128,
                  width: 160,
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 128,
                    width: 160,
                    color: AppColor.surfaceContainer,
                    child: const Center(child: CircularProgressIndicator(color: AppColor.goldEnd)),
                  );
                },
              ),
            // نام محصول
            Padding(
              padding: EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: SizedBox(
                height: 34,
                child: Text(
                  product.nameFarsi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    color: AppColor.onSurface,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            // قیمت و تخفیف
            Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: _buildPrice(),
            ),
          ],
        ),
        ),
      ),
    );
  }
}