import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/constant/urls.dart';
import 'package:marketky/models/ProductModel.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/views/widgets/app_network_image.dart';
import 'package:marketky/views/widgets/motion.dart';

/// کارت محصول به سبک طرح مرجع: کارت سفید با گوشه‌های کاملاً گرد و سایه‌ی
/// نرم، تصویر بزرگ روی زمینه‌ی ملایم، و پاورقی «نام + دسته‌بندی» در یک طرف
/// و «قیمت» در طرف دیگر.
///
/// هیچ داده‌ای اینجا ساخته نمی‌شود: همان [Product] موجود و همان مسیر
/// `/product/{id}` موجود استفاده می‌شود.
class ProductGridCard extends StatelessWidget {
  const ProductGridCard({
    super.key,
    required this.product,
    this.onTap,
    this.showAddToCartButton = false,
  });

  final Product product;

  /// دکمه‌ی «افزودن به سبد» زیر کارت (صفحه‌ی فروشگاه). چون مدل لیست محصول
  /// رنگ/سایز ندارد، این دکمه مثل قبل به صفحه‌ی جزئیات هدایت می‌کند.
  final bool showAddToCartButton;

  /// اگر داده نشود، رفتار پیش‌فرض قبلی (رفتن به صفحه‌ی جزئیات) اجرا می‌شود.
  final VoidCallback? onTap;

  void _open(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    Navigator.of(context).pushNamed('/product/${product.id}');
  }

  @override
  Widget build(BuildContext context) {
    final p = product;
    final int original = p.price ?? 0;
    final int? percent = p.discountPercentage;
    final bool hasDiscount =
        percent != null && percent > 0 && percent < 100 && original > 0;
    final int finalPrice =
        hasDiscount ? (original * (1 - percent / 100)).toInt() : original;

    return PressableScale(
      onTap: () => _open(context),
      child: Container(
        decoration: ShapeDecoration(
          color: AppColor.card,
          shape: AppShapes.border(AppShapes.rLg),
          shadows: AppColor.cardShadow,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // تصویر محصول روی زمینه‌ی ملایم، بدون برش اضافه (contain)
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: ShapeDecoration(
                        color: AppColor.cardMuted,
                        shape: AppShapes.border(AppShapes.rMd),
                      ),
                      child: SquircleClip(
                        radius: AppShapes.rMd,
                        // فاصله‌ی داخلی تا تصویر «بریده» به‌نظر نرسد و
                        // نوار خالیِ contain عمدی دیده شود
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: AppNetworkImage(
                            url: '${URLs.baseUrl}${p.image ?? ''}',
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (hasDiscount)
                    PositionedDirectional(
                      top: 6,
                      start: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: const ShapeDecoration(
                          color: AppColor.danger,
                          shape: StadiumBorder(),
                        ),
                        child: Text(
                          '٪$percent',
                          style: const TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nameFarsi,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 13,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                            color: AppColor.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.category.nameFarsi,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 11,
                            color: AppColor.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'قیمت',
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 10,
                          color: AppColor.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        original > 0
                            ? thousandSeparator(finalPrice)
                            : 'مشاهده',
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: original > 0 ? 13 : 11,
                          fontWeight: FontWeight.w800,
                          color: AppColor.ink,
                        ),
                      ),
                      if (hasDiscount)
                        Text(
                          thousandSeparator(original),
                          style: const TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 10,
                            color: AppColor.inkMuted,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColor.inkMuted,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (showAddToCartButton) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _open(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.pitchGreen,
                    side: const BorderSide(color: AppColor.pitchGreen),
                    shape: AppShapes.pill,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text(
                    'افزودن به سبد',
                    style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
