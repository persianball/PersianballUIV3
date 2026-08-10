import 'package:flutter/material.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';

import '../../constant/app_color.dart';
import '../../constant/urls.dart';
import '../../models/ProductModel.dart';

class SimilarProductCard extends StatelessWidget {
  final SimilarProduct product;

  const SimilarProductCard({Key? key, required this.product}) : super(key: key);

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
                height: 120,
                width: 160,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            // نام محصول
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                product.nameFarsi,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColor.secondary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            // قیمت و تخفیف
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (product.discountPercentage != null && product.discountPercentage! > 0)
                    Text(
                      '${thousandSeparator(product.price!)} تومان',
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    product.discountPercentage != null && product.discountPercentage! > 0
                        ? '${thousandSeparator((product.price! * (1 - product.discountPercentage! / 100)).toInt()) } تومان'
                        : '${thousandSeparator(product.price!)} تومان',
                    style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColor.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}