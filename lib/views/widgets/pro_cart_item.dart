import 'package:flutter/material.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/bloc/cart/cart_bloc.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/CartModel.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';

import '../../constant/urls.dart';

class ProCartItemCard extends StatefulWidget {
  final CartItemFromBackend cartItemFromBackend;
  final TotalPriceFromBack priceFromBack;

  const ProCartItemCard(
      {Key? key, required this.cartItemFromBackend, required this.priceFromBack})
      : super(key: key);

  @override
  _ProCartItemCardState createState() => _ProCartItemCardState();
}

class _ProCartItemCardState extends State<ProCartItemCard> {
  bool isLoading = false;
  bool isDeleteLoading = false;

  int get _originalPrice =>
      (widget.cartItemFromBackend.product?.price ?? 0) *
      widget.cartItemFromBackend.quantity;

  int? get _discountPercent => widget.cartItemFromBackend.product?.disountPercentage;

  int get _discountedPrice {
    final percent = _discountPercent;
    if (percent == null || percent == 0) return _originalPrice;
    return (_originalPrice * (1 - percent / 100.0)).toInt();
  }

  void _changeQuantity(int next) {
    if (next < 1) return;
    context.read<CartBloc>().add(UpdateQuantity(context,
        widget.cartItemFromBackend.id, widget.cartItemFromBackend.product!.id, null, next));
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
      builder: (ctx) => _ProductDetailsSheet(
        cartItemFromBackend: widget.cartItemFromBackend,
        priceFromBack: widget.priceFromBack,
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
    final farsiName = widget.cartItemFromBackend.product?.productVariant?.productName ?? '';
    final colorName = widget.cartItemFromBackend.product?.productVariant?.color ?? '';
    final image = widget.cartItemFromBackend.product?.productVariant?.image ?? '';
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
                  child: Image.network(
                    "${URLs.baseUrl}$image",
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Image.asset('assets/images/placeholder.jpg', width: 48, height: 48),
                  ),
                ),
                const SizedBox(width: 10),

                // عنوان و رنگ، چسبیده به تصویر در سمت راست
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        farsiName,
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
                      if (colorName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          colorName,
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

/// ردیف ریز و مینیمال تعداد + حذف، مشترک بین محصول و دوره.
class MiniQuantityRow extends StatelessWidget {
  final int quantity;
  final bool isLoading;
  final bool isDeleteLoading;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  const MiniQuantityRow({
    required this.quantity,
    required this.isLoading,
    required this.isDeleteLoading,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });

  Widget _miniIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        isDeleteLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: Padding(
                  padding: EdgeInsets.all(2),
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: Colors.red),
                ),
              )
            : _miniIcon(Icons.delete_outline, Colors.red[400]!, onDelete),
        const SizedBox(width: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColor.outlineVariantDark),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _miniIcon(Icons.add, AppColor.successDark, onIncrement),
              isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: Padding(
                        padding: EdgeInsets.all(3),
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: AppColor.goldEnd),
                      ),
                    )
                  : SizedBox(
                      width: 18,
                      child: Text(
                        '$quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColor.onSurface,
                        ),
                      ),
                    ),
              _miniIcon(Icons.remove, AppColor.onSurfaceVariant, onDecrement),
            ],
          ),
        ),
      ],
    );
  }
}

/// جزئیات کامل محصول در سبد، به‌صورت modal bottom sheet.
class _ProductDetailsSheet extends StatelessWidget {
  final CartItemFromBackend cartItemFromBackend;
  final TotalPriceFromBack priceFromBack;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onDelete;

  const _ProductDetailsSheet({
    required this.cartItemFromBackend,
    required this.priceFromBack,
    required this.onQuantityChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final farsiName = cartItemFromBackend.product?.productVariant?.productName ?? '';
    final colorName = cartItemFromBackend.product?.productVariant?.color ?? '';
    final image = cartItemFromBackend.product?.productVariant?.image ?? '';
    final originalPrice =
        (cartItemFromBackend.product?.price ?? 0) * cartItemFromBackend.quantity;
    final percent = cartItemFromBackend.product?.disountPercentage;
    final discountedPrice = (percent != null && percent != 0)
        ? (originalPrice * (1 - percent / 100.0)).toInt()
        : originalPrice;
    final isFreeShipping = priceFromBack.isFreeShipping ?? false;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                color: AppColor.outlineVariantDark,
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  "${URLs.baseUrl}$image",
                  width: 96,
                  height: 96,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Image.asset('assets/images/placeholder.jpg', width: 96, height: 96),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                farsiName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColor.onSurface,
                ),
              ),
              if (colorName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  colorName,
                  style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 13,
                      color: AppColor.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 16),
              _featureRow(Icons.check_circle_outline, 'بسته بندی حرفه‌ای'),
              const SizedBox(height: 6),
              _featureRow(Icons.check_circle_outline, 'ضمانت یک ساله'),
              const SizedBox(height: 6),
              _featureRow(
                isFreeShipping ? Icons.check_circle_outline : Icons.motorcycle,
                isFreeShipping
                    ? 'ارسال رایگان'
                    : '${priceFromBack.postShippingPrice}: هزینه ارسال',
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('تومان',
                      style:
                          TextStyle(fontSize: 14, color: AppColor.onSurfaceVariant)),
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
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
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
              StatefulBuilder(
                builder: (context, setModalState) {
                  return MiniQuantityRow(
                    quantity: cartItemFromBackend.quantity,
                    isLoading: false,
                    isDeleteLoading: false,
                    onIncrement: () =>
                        onQuantityChanged(cartItemFromBackend.quantity + 1),
                    onDecrement: () =>
                        onQuantityChanged(cartItemFromBackend.quantity - 1),
                    onDelete: onDelete,
                  );
                },
              ),
            ],
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
