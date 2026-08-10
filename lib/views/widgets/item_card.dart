import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';

import '../../constant/urls.dart';
import '../../models/ProductModel.dart';

class ItemCard extends StatelessWidget {
  final Product product;
  final Color titleColor;
  final Color priceColor;

  ItemCard({
    required this.product,
    this.titleColor = Colors.black,
    this.priceColor = AppColor.primary,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          thousandSeparator(finalPrice),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Estedad',
            color: priceColor,
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
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed('/product/${product.id}');
      },
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 16 - 8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.border),
          boxShadow: [
            BoxShadow(
              color: AppColor.secondary.withOpacity(0.06),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // item image
            Container(
              width: MediaQuery.of(context).size.width / 2 - 16 - 8,
              height: (MediaQuery.of(context).size.width / 2 - 16 - 8) * 0.8,
              alignment: Alignment.topLeft,
              child: Stack(
                children: [
                  // پس‌زمینه: تصویر از شبکه یا assets
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                    child: Image.network(
                      '${URLs.baseUrl}${product.image!}',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        // اگر لود نشد، تصویر assets را نمایش بده
                        return Image.asset(
                          'assets/images/placeholder.jpg', // یا png
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        );
                      },
                      // اختیاری: نمایش لودینگ
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  ),
                  // محتوای جلو: RatingTag
                  // Positioned(
                  //   top: 0,
                  //   left: 0,
                  //   child: RatingTag(value: product.),
                  // ),
                ],
              ),
            ),

            // item details
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(8, 6, 8, 8),
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
                        color: titleColor,
                      ),
                    ),
                  ),
                  _buildPrice(),
                  // Text(
                  //   '${product.description}',
                  //   style: TextStyle(
                  //     color: Colors.grey,
                  //     fontSize: 10,
                  //   ),
                  // )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
