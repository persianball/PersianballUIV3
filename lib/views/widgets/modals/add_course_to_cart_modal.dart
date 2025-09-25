// views/widgets/modals/add_course_to_cart_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/course_detail_model.dart';
import 'package:marketky/bloc/cart/cart_bloc.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';

class AddCourseToCartModal extends StatefulWidget {
  final CourseTimeAndLocationItem courseItem; // دوره‌ای که کاربر می‌خواهد اضافه کند

  const AddCourseToCartModal({Key? key, required this.courseItem}) : super(key: key);

  @override
  _AddCourseToCartModalState createState() => _AddCourseToCartModalState();
}

class _AddCourseToCartModalState extends State<AddCourseToCartModal> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = 1;
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.courseItem.price * _quantity;
    final discountedPrice = widget.courseItem.discountPercentage > 0 
        ? ((widget.courseItem.discountPercentage / 100) * totalPrice).toInt() 
        : 0;

    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          color: Colors.white,
        ),
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 20),
        child: Column(
          children: [
            // Indicator
            Container(
              width: MediaQuery.of(context).size.width / 2,
              height: 6,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: AppColor.primarySoft,
              ),
            ),

            // Course Info
            Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.school, color: AppColor.primary, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.courseItem.courseName,
                          style: TextStyle(
                            fontFamily: 'Estedad',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                      SizedBox(width: 4),
                      Text(
                        widget.courseItem.location,
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                      SizedBox(width: 4),
                      Text(
                        widget.courseItem.time,
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),

            // تعداد
            Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تعداد',
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          color: Color(0xFF0A0E2F).withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(() => _quantity++),
                            icon: Icon(Icons.add, size: 20, color: Colors.black),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(AppColor.border),
                              shape: MaterialStateProperty.all(CircleBorder()),
                              padding: MaterialStateProperty.all(EdgeInsets.all(0)),
                            ),
                          ),

                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '$_quantity',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Estedad'),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (_quantity > 1) setState(() => _quantity--);
                            },
                            icon: Icon(Icons.remove, size: 20, color: Colors.black),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(AppColor.border),
                              shape: MaterialStateProperty.all(CircleBorder()),
                              padding: MaterialStateProperty.all(EdgeInsets.all(0)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'قیمت',
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          color: Color(0xFF0A0E2F).withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${thousandSeparator(totalPrice)}',
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          color: Color(0xFF0A0E2F).withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (widget.courseItem.discountPercentage > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تخفیف',
                          style: TextStyle(
                            fontFamily: 'Estedad',
                            color: Color(0xFF0A0E2F).withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${thousandSeparator(discountedPrice)} (${widget.courseItem.discountPercentage}%)',
                          style: TextStyle(
                            fontFamily: 'Estedad',
                            color: Color(0xFF0A0E2F).withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // دکمه افزودن
            Container(
              width: MediaQuery.of(context).size.width,
              margin: EdgeInsets.only(top: 18),
              padding: EdgeInsets.all(4),
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColor.primarySoft,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: Container(
                      padding: EdgeInsets.only(left: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('مجموع', style: TextStyle(fontSize: 10, fontFamily: 'Estedad')),
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              '${thousandSeparator(totalPrice - discountedPrice)} تومان',
                              style: TextStyle(fontSize: 16, fontFamily: 'Estedad', fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                   flex: 6,
                   child: ElevatedButton(
                     onPressed: () {
                       context.read<CartBloc>().add(AddCourseToCart(context, widget.courseItem.id, _quantity));
                       Navigator.of(context).pop();
                     },
                     child: Text(
                       'افزودن به سبد',
                       style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Estedad',
                       color: Colors.white),
                     ),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColor.primary,
                       padding: EdgeInsets.symmetric(vertical: 15),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                       elevation: 0,
                     ),
                   ),
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
