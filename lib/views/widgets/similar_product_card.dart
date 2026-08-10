import 'package:flutter/material.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';

import '../../constant/app_color.dart';
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
          style: TextStyle(
            fontFamily: 'Estedad',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColor.primary,
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
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
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
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.grey,
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
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed('/product/${product.id}');
      },
      child: Container(
        width: 160, // عرض ثابت برای اسلایدر افقی
        margin: EdgeInsetsDirectional.only(start: 8, end: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // تصویر محصول
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
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
                    color: Colors.grey[200],
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
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
                    color: AppColor.secondary,
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
    );
  }
}