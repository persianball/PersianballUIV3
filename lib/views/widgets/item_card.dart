import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/bloc/product_detail/product_detail_bloc.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/views/screens/product_detail.dart';
import 'package:marketky/views/widgets/rating_tag.dart';

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => ProductDetailBloc(),
              child: ProductDetailPage(productId: this.product.id,),
            )));
      },
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 16 - 8,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // item image
            Container(
              width: MediaQuery.of(context).size.width / 2 - 16 - 8,
              height: MediaQuery.of(context).size.width / 2 - 16 - 8,
              padding: EdgeInsets.all(10),
              alignment: Alignment.topLeft,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // پس‌زمینه: تصویر از شبکه یا assets
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
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
                  Positioned(
                    top: 0,
                    left: 0,
                    child: RatingTag(value: 0),
                  ),
                ],
              ),
            ),

            // item details
            Container(
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${product.nameFarsi}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 2, bottom: 8),
                    child: Text(
                      '${thousandSeparator(product.price??0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Estedad',
                        color: priceColor,
                      ),
                    ),
                  ),
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
