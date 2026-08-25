// lib/views/widgets/checkout_timeline.dart
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/constant/app_color.dart';

/// A simple 3-step horizontal checkout timeline.
/// Steps: 0 = Cart, 1 = Address & Shipping, 2 = Finalize
class CheckoutTimeline extends StatelessWidget {
  final int currentStep; // 0..2
  const CheckoutTimeline({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = const ['سبد خرید', 'آدرس و ارسال', 'نهایی‌سازی'];

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
                dot(0),
                connector(currentStep > 0),
                dot(1),
                connector(currentStep > 1),
                dot(2),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(steps[0], style: TextStyle(fontSize: 12, color: currentStep >= 0 ? AppColor.onSurface : AppColor.onSurfaceVariant, fontWeight: FontWeight.w600)),
                Text(steps[1], style: TextStyle(fontSize: 12, color: currentStep >= 1 ? AppColor.onSurface : AppColor.onSurfaceVariant, fontWeight: FontWeight.w600)),
                Text(steps[2], style: TextStyle(fontSize: 12, color: currentStep >= 2 ? AppColor.onSurface : AppColor.onSurfaceVariant, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}