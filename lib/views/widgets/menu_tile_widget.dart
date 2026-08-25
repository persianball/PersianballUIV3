import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';

class MenuTileWidget extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final GestureTapCallback onTap;
  final EdgeInsetsGeometry? margin;
  final Color iconBackground;
  final Color titleColor;

  MenuTileWidget({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.margin,
    this.iconBackground = AppColor.pitchGreenSoft,
    this.titleColor = AppColor.ink,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 10),
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: ShapeDecoration(
          color: AppColor.card,
          shape: AppShapes.border(AppShapes.rLg),
          shadows: AppColor.cardShadow,
        ),
        child: Row(
          children: [
            // Icon Box
            Container(
              width: 46,
              height: 46,
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.only(left: 14),
              decoration: ShapeDecoration(
                color: iconBackground,
                shape: const CircleBorder(),
              ),
              child: icon,
            ),
            // Info
            Expanded(
              child: (subtitle == null)
                  ? Text('$title', style: TextStyle(color: titleColor, fontFamily: 'Estedad', fontWeight: FontWeight.w500))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$title', style: TextStyle(color: AppColor.onSurface, fontFamily: 'Estedad', fontWeight: FontWeight.w500)),
                        SizedBox(height: 2),
                        Text('$subtitle', style: TextStyle(color: AppColor.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
            ),
            const Icon(
              Icons.chevron_left_rounded,
              color: AppColor.lineStrong,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
