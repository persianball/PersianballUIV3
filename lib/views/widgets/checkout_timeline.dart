// lib/views/widgets/checkout_timeline.dart
import 'package:flutter/material.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:persian_ball/constant/app_color.dart';

/// A simple 3-step horizontal checkout timeline.
/// Steps: 0 = Cart, 1 = Address & Shipping, 2 = Finalize
class CheckoutTimeline extends StatelessWidget {
  final int currentStep; // 0..2 (یا 0..1 وقتی مرحله‌ی آدرس حذف شده)

  /// سفارشِ بدون ارسال، مرحله‌ی «آدرس و ارسال» را ندارد؛ نشان‌دادن آن به
  /// عنوان مرحله‌ی طی‌شده گمراه‌کننده است، پس تایم‌لاین دو-مرحله‌ای می‌شود.
  final bool skipAddress;

  const CheckoutTimeline({
    super.key,
    required this.currentStep,
    this.skipAddress = false,
  });

  @override
  Widget build(BuildContext context) {
    final steps = skipAddress
        ? const ['سبد خرید', 'نهایی‌سازی']
        : const ['سبد خرید', 'آدرس و ارسال', 'نهایی‌سازی'];

    Widget dot(int index) {
      final active = index <= currentStep;
      return CircleAvatar(
        radius: 14,
        backgroundColor: active ? AppColor.goldEnd : AppColor.surfaceContainer,
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: active ? AppColor.onGold : AppColor.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    Widget connector(bool filled) => Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: filled ? AppColor.goldEnd : AppColor.outlineVariantDark,
          ),
        );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: ShapeDecoration(
            color: AppColor.surfaceContainer,
            shape: AppShapes.border(AppShapes.rLg),
            shadows: AppColor.cardShadow,
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (int i = 0; i < steps.length; i++) ...[
                  if (i > 0) connector(currentStep > i - 1),
                  dot(i),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flexible: روی گوشیِ باریک با متنِ بزرگ‌شده برچسب‌ها
                // به‌جای سرریز، کوتاه می‌شوند
                for (int i = 0; i < steps.length; i++)
                  Flexible(
                    child: Text(steps[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          color: currentStep >= i
                              ? AppColor.onSurface
                              : AppColor.onSurfaceVariant,
                          fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}