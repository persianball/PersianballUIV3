import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/core/model/Category.dart';

class CategoryCard extends StatelessWidget {
  final Category data;
  final GestureTapCallback onTap;
  const CategoryCard({super.key, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool featured = data.featured == true;
    final Color fg = featured ? AppColor.pitchGreen : AppColor.inkMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: ShapeDecoration(
          color: featured ? AppColor.pitchGreenSoft : AppColor.card,
          shape: AppShapes.border(
            AppShapes.rMd,
            side: BorderSide(
              color: featured ? AppColor.pitchGreen : AppColor.line,
            ),
          ),
          shadows: AppColor.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: SvgPicture.asset(
                '${data.iconUrl}',
                width: 30,
                colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
              ),
            ),
            Flexible(
              child: Text(
                '${data.name}',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: featured ? AppColor.pitchGreen : AppColor.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
