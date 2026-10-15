import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:persian_ball/constant/app_color.dart';

class RatingTag extends StatelessWidget {
  final double value;
  final EdgeInsetsGeometry? margin;
  RatingTag({required this.value, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const ShapeDecoration(
        color: AppColor.cardMuted,
        shape: StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/Star-active.svg',
            width: 14,
            height: 14,
          ),
          SizedBox(width: 4),
          Text(
            '$value',
            style: TextStyle(
              fontFamily: 'Estedad',
              color: AppColor.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
