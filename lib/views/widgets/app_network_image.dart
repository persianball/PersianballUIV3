// lib/views/widgets/app_network_image.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';

/// تصویر شبکه‌ای با کش دیسک، اسکلتون لودینگ و تصویر پیش‌فرض.
///
/// جایگزین Image.network خام: مصرف داده را کم می‌کند و از پرش لِی‌اوت و
/// آیکن شکسته جلوگیری می‌کند.
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String fallbackAsset;
  final BorderRadius? borderRadius;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackAsset = 'assets/images/placeholder.jpg',
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final Widget image = (url == null || url!.isEmpty)
        ? _fallback()
        : CachedNetworkImage(
            imageUrl: url!,
            width: width,
            height: height,
            fit: fit,
            placeholder: (_, __) => _skeleton(),
            errorWidget: (_, __, ___) => _fallback(),
          );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _fallback() => Image.asset(
        fallbackAsset,
        width: width,
        height: height,
        fit: fit,
      );

  // اسکلتون باید همان گردی گوشه‌ی تصویر واقعی را داشته باشد (borderRadius
  // این ویجت)، وگرنه در کارت‌های گوشه‌تیز (dark) یا با گردی متفاوت، حین
  // لودینگ یک جعبه‌ی گرد نامتناسب با بقیه‌ی کارت دیده می‌شود.
  Widget _skeleton() =>
      _SkeletonBox(width: width, height: height, borderRadius: borderRadius);
}

/// مستطیل خاکستری با انیمیشن نبض، برای حالت لودینگ
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonBox({super.key, this.width, this.height, this.borderRadius});

  @override
  Widget build(BuildContext context) => _SkeletonBox(
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
}

class _SkeletonBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const _SkeletonBox({this.width, this.height, this.borderRadius});

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(
            Colors.grey.shade200,
            Colors.grey.shade300,
            _controller.value,
          ),
          // null یعنی «بدون گردی» (کارت‌های dark/گوشه‌تیز)، نه یک مقدار
          // پیش‌فرض دلخواه؛ وگرنه اسکلتون روی کارت‌های گوشه‌تیز گرد دیده
          // می‌شد در حالی که تصویر واقعی بعد از لود کاملاً گوشه‌تیز است.
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
        ),
      ),
    );
  }
}

/// اسکلتون یک کارت محصول، هم‌اندازه و هم‌شکل ItemCard (`dark` باید با
/// همان مقداری که ItemCard واقعی صفحه استفاده می‌کند ست شود، وگرنه حین
/// لودینگ یک شکل/گردی متفاوت از کارت واقعی دیده می‌شود).
class ProductCardSkeleton extends StatelessWidget {
  final bool dark;

  const ProductCardSkeleton({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final width =
        (MediaQuery.of(context).size.width / 2 - 16 - 8).clamp(130.0, 200.0);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(
          width: width,
          height: width * (dark ? 1 : 0.8),
          borderRadius: dark
              ? null
              : const BorderRadius.vertical(top: Radius.circular(15)),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(8, dark ? 8 : 6, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: width * 0.8, height: 12),
              const SizedBox(height: 6),
              SkeletonBox(width: width * 0.5, height: 12),
              const SizedBox(height: 8),
              SkeletonBox(width: width * 0.35, height: 14),
            ],
          ),
        ),
      ],
    );

    return SizedBox(
      width: width,
      child: Container(
        decoration: dark
            ? BoxDecoration(
                color: AppColor.surfaceContainer,
                border: Border.all(color: AppColor.outlineVariantDark),
              )
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColor.border),
              ),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
}
