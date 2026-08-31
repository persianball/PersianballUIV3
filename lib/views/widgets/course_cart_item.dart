import 'package:flutter/material.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/bloc/cart/cart_bloc.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/CartModel.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/views/widgets/pro_cart_item.dart' show MiniQuantityRow;

import '../../constant/urls.dart';

class CourseCartItemCard extends StatefulWidget {
  final CartItemFromBackend cartItemFromBackend;
  final TotalPriceFromBack priceFromBack;

  const CourseCartItemCard(
      {Key? key, required this.cartItemFromBackend, required this.priceFromBack})
      : super(key: key);

  @override
  _CourseCartItemCardState createState() => _CourseCartItemCardState();
}

class _CourseCartItemCardState extends State<CourseCartItemCard> {
  bool isLoading = false;
  bool isDeleteLoading = false;

  int get _originalPrice =>
      (widget.cartItemFromBackend.course?.price ?? 0) *
      widget.cartItemFromBackend.quantity;

  int? get _discountPercent => widget.cartItemFromBackend.course?.discountPercentage;

  int get _discountedPrice {
    final percent = _discountPercent;
    if (percent == null || percent == 0) return _originalPrice;
    return (_originalPrice * (1 - percent / 100.0)).toInt();
  }

  void _changeQuantity(int next) {
    if (next < 1) return;
    context.read<CartBloc>().add(UpdateQuantity(context,
        widget.cartItemFromBackend.id, null, widget.cartItemFromBackend.course!.id, next));
    setState(() => isLoading = true);
  }

  void _delete() {
    setState(() => isDeleteLoading = true);
    context
        .read<CartBloc>()
        .add(RemoveFromCart(context, widget.cartItemFromBackend.id));
  }

  void _openDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.obsidianBg,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColor.outlineVariantDark),
        borderRadius: AppShapes.radius(AppShapes.rMd),
      ),
      builder: (ctx) => _CourseDetailsSheet(
        cartItemFromBackend: widget.cartItemFromBackend,
        onQuantityChanged: _changeQuantity,
        onDelete: () {
          Navigator.of(ctx).pop();
          _delete();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseName = widget.cartItemFromBackend.course?.courseName ?? '';
    final location = widget.cartItemFromBackend.course?.location ?? '';
    final image = widget.cartItemFromBackend.course?.image;
    final percent = _discountPercent;

    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is CartLoaded) {
          setState(() {
            isLoading = false;
            isDeleteLoading = false;
          });
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: GestureDetector(
          onTap: _openDetails,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: ShapeDecoration(
            color: AppColor.surfaceContainer,
            shape: AppShapes.border(AppShapes.rLg),
            shadows: AppColor.cardShadow,
          ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // تصویر کوچک، سمت راست
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: image != null
                      ? Image.network(
                          "${URLs.baseUrl}$image",
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.school, size: 28, color: AppColor.goldEnd),
                        )
                      : Icon(Icons.school, size: 28, color: AppColor.goldEnd),
                ),
                const SizedBox(width: 10),

                // عنوان و محل برگزاری، چسبیده به تصویر در سمت راست
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        courseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColor.onSurface,
                        ),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 11,
                            color: AppColor.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // قیمت/تخفیف و کنترل تعداد و حذف، سمت چپ - مینیمال و ریز
                // ردیف اول: درصد تخفیف + قیمت قبلی (خط‌خورده)، ردیف دوم:
                // قیمت نهایی.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (percent != null && percent != 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            color: Colors.red,
                            child: Text(
                              '$percent%',
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            thousandSeparator(_originalPrice),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColor.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    Text(
                      thousandSeparator(_discountedPrice),
                      style: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColor.goldEnd,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MiniQuantityRow(
                      quantity: widget.cartItemFromBackend.quantity,
                      isLoading: isLoading,
                      isDeleteLoading: isDeleteLoading,
                      onIncrement: () =>
                          _changeQuantity(widget.cartItemFromBackend.quantity + 1),
                      onDecrement: () =>
                          _changeQuantity(widget.cartItemFromBackend.quantity - 1),
                      onDelete: _delete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// جزئیات کامل دوره در سبد، به‌صورت modal bottom sheet.
class _CourseDetailsSheet extends StatelessWidget {
  final CartItemFromBackend cartItemFromBackend;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onDelete;

  const _CourseDetailsSheet({
    required this.cartItemFromBackend,
    required this.onQuantityChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final courseName = cartItemFromBackend.course?.courseName ?? '';
    final location = cartItemFromBackend.course?.location ?? '';
    final image = cartItemFromBackend.course?.image;
    final originalPrice =
        (cartItemFromBackend.course?.price ?? 0) * cartItemFromBackend.quantity;
    final percent = cartItemFromBackend.course?.discountPercentage;
    final discountedPrice = (percent != null && percent != 0)
        ? (originalPrice * (1 - percent / 100.0)).toInt()
        : originalPrice;
    final gift = cartItemFromBackend.course?.giftProduct;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(width: 40, height: 4, color: AppColor.outlineVariantDark),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: image != null
                      ? Image.network(
                          "${URLs.baseUrl}$image",
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.school, size: 56, color: AppColor.goldEnd),
                        )
                      : Icon(Icons.school, size: 56, color: AppColor.goldEnd),
                ),
                const SizedBox(height: 16),
                Text(
                  courseName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColor.onSurface,
                  ),
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 13,
                        color: AppColor.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 4),
                const Text(
                  'دوره آموزشی',
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 12,
                    color: AppColor.goldEnd,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                _featureRow(Icons.school, 'آموزش حرفه‌ای'),
                const SizedBox(height: 6),
                _featureRow(Icons.group, 'کلاس گروهی'),
                const SizedBox(height: 6),
                _featureRow(Icons.access_time, 'زمان‌بندی انعطاف‌پذیر'),
                if (gift != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColor.successDark.withOpacity(0.08),
                      border:
                          Border.all(color: AppColor.successDark.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: gift.image != null
                              ? Image.network(
                                  "${URLs.baseUrl}${gift.image}",
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                      Icons.card_giftcard,
                                      size: 26,
                                      color: AppColor.successDark),
                                )
                              : Icon(Icons.card_giftcard,
                                  size: 26, color: AppColor.successDark),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('هدیه ویژه',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColor.successDark)),
                              const SizedBox(height: 2),
                              Text(
                                gift.productName ?? 'محصول هدیه',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColor.onSurfaceVariant),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('تومان',
                        style: TextStyle(
                            fontSize: 14, color: AppColor.onSurfaceVariant)),
                    const SizedBox(width: 8),
                    Text(
                      thousandSeparator(discountedPrice),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColor.goldEnd),
                    ),
                  ],
                ),
                if (percent != null && percent != 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                        color: Colors.red,
                        child: Text('$percent%',
                            style:
                                const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        thousandSeparator(originalPrice),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColor.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                MiniQuantityRow(
                  quantity: cartItemFromBackend.quantity,
                  isLoading: false,
                  isDeleteLoading: false,
                  onIncrement: () =>
                      onQuantityChanged(cartItemFromBackend.quantity + 1),
                  onDecrement: () =>
                      onQuantityChanged(cartItemFromBackend.quantity - 1),
                  onDelete: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColor.successDark),
        const SizedBox(width: 8),
        Text(text,
            style:
                const TextStyle(fontSize: 12, color: AppColor.onSurfaceVariant)),
      ],
    );
  }
}
