import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/CartModel.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';

import '../../constant/urls.dart';

class CartTile extends StatelessWidget {
  final CartItem data;
  final VoidCallback onRemove;
  final ValueChanged<int> onChangeQuantity;
  CartTile({required this.data, required this.onRemove, required this.onChangeQuantity});
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: MediaQuery.of(context).size.width,

        padding: EdgeInsets.only(top: 5, left: 5, bottom: 5, right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.border, width: 1),
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 70,
              height: 70,
              margin: EdgeInsets.only(left: 20),
              decoration: BoxDecoration(
                color: AppColor.border,
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(image: NetworkImage("${URLs.baseUrl+data.image}"), fit: BoxFit.cover),
              ),
            ),
            // Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    '${data.name}',
                    style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Estedad', color: AppColor.secondary),
                  ),
                  // Product Price - Increment Decrement Button
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Product Price
                        Text(
                          'قیمت:',
                          style: TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Estedad', color: AppColor.primary,fontSize: 10),
                        ),
                        Expanded(
                          child: Text(
                            '${thousandSeparator(data.price)}',
                            style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Estedad', color: AppColor.primary),
                          ),
                        ),

                        // Increment Decrement Button
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Container(
                            height: 26,

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: AppColor.primarySoft,
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: onRemove,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: AppColor.primarySoft,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: SvgPicture.asset('assets/icons/Trash.svg', color: Colors.red),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: data.quantity > 1
                                      ? () => onChangeQuantity(data.quantity - 1)
                                      : null,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: AppColor.primarySoft,
                                    ),
                                    child: Text(
                                      '-',
                                      style: TextStyle(fontFamily: 'poppins', fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: 8),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${data.quantity}',
                                      style: TextStyle(fontFamily: 'Estedad', fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    onChangeQuantity(data.quantity + 1);
                                  },
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: AppColor.primarySoft,
                                    ),
                                    child: Text(
                                      '+',
                                      style: TextStyle(fontFamily: 'poppins', fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'قیمت با تخفیف:',
                        style: TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Estedad', color: AppColor.primary,fontSize: 10),
                      ),
                      Expanded(
                        child: Text(
                          '${thousandSeparator(
                              data.discountPrice != null
                                  ? (data.price * (1 - data.discountPrice! / 100.0)).toInt()
                                  : data.price
                          )}(${data.discountPrice}%)',
                          style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Estedad', color: AppColor.primary),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'مجموع:',
                        style: TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Estedad', color: AppColor.primary,fontSize: 10),
                      ),
                      Expanded(
                        child: Text(
                          '${thousandSeparator(data.discountPrice!=null?(data.price * (1 - data.discountPrice! / 100.0)).toInt()*data.quantity:
                          data.quantity*data.price)}',
                          style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Estedad', color: AppColor.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
