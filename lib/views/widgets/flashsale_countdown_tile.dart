import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';

class FlashsaleCountdownTile extends StatelessWidget {
  final String? digit;

  const FlashsaleCountdownTile({super.key, this.digit});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      width: 22,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: ShapeDecoration(
        color: AppColor.cardMuted,
        shape: AppShapes.border(AppShapes.rSm),
      ),
      child: Center(
        child: Text(
          digit!,
          style: const TextStyle(
            color: AppColor.ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            fontFamily: 'Estedad',
          ),
        ),
      ),
    );
  }
}
