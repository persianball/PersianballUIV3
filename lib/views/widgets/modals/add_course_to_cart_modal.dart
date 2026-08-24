// views/widgets/modals/add_course_to_cart_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/course_detail_model.dart';
import 'package:marketky/bloc/cart/cart_bloc.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';

class AddCourseToCartModal extends StatefulWidget {
  final CourseTimeAndLocationItem
      courseItem; // دوره‌ای که کاربر می‌خواهد اضافه کند

  const AddCourseToCartModal({Key? key, required this.courseItem})
      : super(key: key);

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
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: AppColor.surfaceContainerOpaque,
            border: Border(
              top: BorderSide(color: AppColor.outlineVariantDark),
              left: BorderSide(color: AppColor.outlineVariantDark),
              right: BorderSide(color: AppColor.outlineVariantDark),
            ),
          ),
          width: double.infinity,
          constraints: BoxConstraints(maxWidth: 700),
          margin: EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 14,
            bottom: 20 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Column(
            children: [
              // Indicator
              Container(
                width: 140,
                height: 6,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColor.outlineVariantDark,
                ),
              ),

              // Course Info
              Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.school, color: AppColor.goldEnd, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.courseItem.courseName,
                            style: TextStyle(
                              fontFamily: 'Estedad',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColor.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: AppColor.onSurfaceVariant, size: 16),
                        SizedBox(width: 4),
                        Text(
                          widget.courseItem.location,
                          style: TextStyle(
                            fontFamily: 'Estedad',
                            color: AppColor.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            color: AppColor.onSurfaceVariant, size: 16),
                        SizedBox(width: 4),
                        Text(
                          widget.courseItem.time,
                          style: TextStyle(
                            fontFamily: 'Estedad',
                            color: AppColor.onSurfaceVariant,
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
                            color: AppColor.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => setState(() => _quantity++),
                              icon: Icon(Icons.add,
                                  size: 20, color: AppColor.onGold),
                              style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.all(AppColor.goldEnd),
                                shape:
                                    WidgetStateProperty.all(CircleBorder()),
                                padding: WidgetStateProperty.all(
                                    EdgeInsets.all(0)),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '$_quantity',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Estedad',
                                    color: AppColor.onSurface),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (_quantity > 1) setState(() => _quantity--);
                              },
                              icon: Icon(Icons.remove,
                                  size: 20, color: AppColor.onSurface),
                              style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.all(AppColor.surfaceContainerHigh),
                                shape:
                                    WidgetStateProperty.all(CircleBorder()),
                                padding: WidgetStateProperty.all(
                                    EdgeInsets.all(0)),
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
                            color: AppColor.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${thousandSeparator(totalPrice)}',
                          style: TextStyle(
                            fontFamily: 'Estedad',
                            color: AppColor.onSurfaceVariant,
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
                              color: AppColor.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${thousandSeparator(discountedPrice)} (${widget.courseItem.discountPercentage}%)',
                            style: TextStyle(
                              fontFamily: 'Estedad',
                              color: AppColor.onSurfaceVariant,
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
                  color: AppColor.obsidianBg,
                  border: Border.all(color: AppColor.outlineVariantDark),
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
                            Text('مجموع',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'Estedad',
                                    color: AppColor.onSurfaceVariant)),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                '${thousandSeparator(totalPrice - discountedPrice)} تومان',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Estedad',
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.goldEnd),
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
                          context.read<CartBloc>().add(AddCourseToCart(
                              context, widget.courseItem.id, _quantity));
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'افزودن به سبد',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Estedad',
                              color: AppColor.onGold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.goldEnd,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: const RoundedRectangleBorder(),
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
      ),
    );
  }
}
