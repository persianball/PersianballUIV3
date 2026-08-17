import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';

class FlashsaleCountdownTile extends StatelessWidget {
  final String? digit;

  const FlashsaleCountdownTile({ Key? key, this.digit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 20,
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerHigh,
        border: Border.all(color: AppColor.outlineVariantDark),
      ),
      child: Center(
        child: Text(
          digit!,
          style: TextStyle(
            color: AppColor.goldEnd,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Estedad',
          ),
        ),
      ),
    );
  }
}
