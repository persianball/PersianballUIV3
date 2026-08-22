// views/widgets/modals/add_to_cart_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/bloc/cart/cart_bloc.dart';
import 'package:marketky/services/analytics_service.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/CartModel.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/views/widgets/page_container.dart';

class AddToCartModal extends StatefulWidget {
  final CartItem cartItem; // محصولی که کاربر می‌خواهد اضافه کند

  const AddToCartModal({Key? key, required this.cartItem}) : super(key: key);

  @override
  _AddToCartModalState createState() => _AddToCartModalState();
}

class _AddToCartModalState extends State<AddToCartModal> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = 1;
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.cartItem.price * _quantity;
    final discoutedPrice = widget.cartItem.discountPrice != null
        ? ((widget.cartItem.discountPrice! / 100) * totalPrice).toInt()
        : 0;

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 700.0,
        child: Container(
          decoration: BoxDecoration(
            // AppColor.surfaceContainer فقط ۵٪ آلفا دارد (برای پنل شیشه‌ای
            // روی پس‌زمینه‌ی صفحه طراحی شده)؛ چون این باتم‌شیت خودش
            // showModalBottomSheet(backgroundColor: transparent) است، آن
            // ۵٪ باعث می‌شد کل صفحه‌ی پشت مودال دیده شود. همان رنگ ولی
            // به‌صورت کاملاً کدر (بلندشده روی obsidianBg) استفاده می‌شود.
            color: Color.alphaBlend(
                AppColor.surfaceContainer, AppColor.obsidianBg),
            border: Border(
              top: BorderSide(color: AppColor.outlineVariantDark),
              left: BorderSide(color: AppColor.outlineVariantDark),
              right: BorderSide(color: AppColor.outlineVariantDark),
            ),
          ),
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 14,
            // فضای نوار ناوبری سیستم تا دکمه افزودن زیر آن گیر نکند
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
                          '${widget.cartItem.discountPrice != null ? thousandSeparator(discoutedPrice) : 0}(${widget.cartItem.discountPrice ?? 0}%)',
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
                width: double.infinity,
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
                                '${thousandSeparator(totalPrice - discoutedPrice)} تومان',
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
                          AnalyticsService.addToCart(
                            productId: widget.cartItem.productId,
                            quantity: _quantity,
                            price: widget.cartItem.price,
                          );
                          context.read<CartBloc>().add(
                              AddToCart(context, widget.cartItem.id, _quantity));
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.goldEnd,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: const RoundedRectangleBorder(),
                          elevation: 0,
                        ),
                        child: Text(
                          'افزودن به سبد',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Estedad',
                              color: AppColor.onGold),
                        ),
                      ),
                    ),
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
