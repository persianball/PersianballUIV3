// lib/views/widgets/app_network_image.dart
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/constant/app_shapes.dart';

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

  /// سقفِ عرضِ دیکود؛ بزرگ‌تر از این روی هیچ نمایشگری فرقی نمی‌کند.
  static const int _maxDecodeWidth = 1600;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _clip(_fallback());

    // عکس‌های محصول اغلب ۱۵۰۰–۳۰۰۰ پیکسل‌اند ولی در کارت ۲۰۰–۴۰۰ پیکسل
    // نمایش داده می‌شوند. بدونِ memCacheWidth کلِ تصویر در اندازه‌ی اصلی
    // دیکود و در حافظه‌ی گرافیکی نگه داشته می‌شد و هر فریمِ اسکرول همان
    // تصویرِ بزرگ کوچک می‌شد؛ روی وب این یکی از عاملانِ اصلیِ لرزشِ
    // اسکرول بود. اینجا تصویر به اندازه‌ی واقعیِ کادر (× چگالی) دیکود
    // می‌شود. برای cover بزرگ‌ترین بعد ملاک است تا تصویرِ پهن در کادرِ
    // بلند تار نشود.
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(builder: (context, c) {
      double? w = (width != null && width!.isFinite)
          ? width
          : (c.hasBoundedWidth ? c.maxWidth : null);
      double? h = (height != null && height!.isFinite)
          ? height
          : (c.hasBoundedHeight ? c.maxHeight : null);
      final double? logical = (w == null && h == null)
          ? null
          : math.max(w ?? 0, h ?? 0);
      final int? decodeWidth = (logical == null || logical <= 0)
          ? null
          : math.min(_maxDecodeWidth, (logical * dpr).ceil());

      return _clip(CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: decodeWidth,
        placeholder: (_, __) => _skeleton(),
        errorWidget: (_, __, ___) => _fallback(),
      ));
    });
  }

  Widget _clip(Widget image) => borderRadius == null
      ? image
      : ClipRRect(borderRadius: borderRadius!, child: image);

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
            AppColor.cardMuted,
            AppColor.line,
            _controller.value,
          ),
          // null یعنی «بدون گردی» (کارت‌های dark/گوشه‌تیز)، نه یک مقدار
          // پیش‌فرض دلخواه؛ وگرنه اسکلتون روی کارت‌های گوشه‌تیز گرد دیده
          // می‌شد در حالی که تصویر واقعی بعد از لود کاملاً گوشه‌تیز است.
          borderRadius: widget.borderRadius ?? AppShapes.radius(AppShapes.rMd),
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
        SkeletonBox(width: width, height: width),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
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
        decoration: ShapeDecoration(
          color: AppColor.card,
          shape: AppShapes.border(AppShapes.rMd),
          shadows: AppColor.cardShadow,
        ),
        child: SquircleClip(radius: AppShapes.rMd, child: content),
      ),
    );
  }
}
