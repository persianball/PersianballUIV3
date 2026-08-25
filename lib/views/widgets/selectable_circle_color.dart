import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/ColorWay.dart';

/// انتخاب‌گر رنگ، طبق طرح Obsidian Gold Athletics: نمونه‌های رنگ مربعی
/// گوشه‌تیز به‌جای دایره («zero roundedness» و «no circular avatars» طرح).
/// این ویجت فقط در product_detail.dart استفاده می‌شود.
class SelectableCircleColor extends StatefulWidget {
  final EdgeInsetsGeometry? margin, padding;
  final List<ColorWay> colorWay;
  final ValueChanged<int> onColorSelected; // فراخوانی وقتی رنگ تغییر کرد

  // New: allow customizing circle size and spacing
  final double circleSize; // default 42
  final double spacing; // default 20

  SelectableCircleColor({
    Key? key,
    required this.colorWay,
    this.margin,
    this.padding,
    required this.onColorSelected,
    this.circleSize = 42,
    this.spacing = 20,
  }) : super(key: key);

  @override
  _SelectableCircleState createState() => _SelectableCircleState();
}

class _SelectableCircleState extends State<SelectableCircleColor> {
  int? _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: widget.margin,
      padding: widget.padding,
      child: Wrap(
        spacing: widget.spacing,
        runSpacing: 8,
        children: List.generate(
          widget.colorWay.length,
              (index) {
            final variant = widget.colorWay[index];
            final isSelected = index == _selectedIndex;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });

                // ارسال ایندکس انتخاب
                widget.onColorSelected(index);
              },
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: ShapeDecoration(
                  color: AppColor.card,
                  shape: CircleBorder(
                    side: BorderSide(
                      width: 2,
                      color: isSelected
                          ? AppColor.pitchGreen
                          : AppColor.line,
                    ),
                  ),
                  shadows:
                      isSelected ? AppColor.greenShadow : AppColor.cardShadow,
                ),
                child: Container(
                  width: widget.circleSize,
                  height: widget.circleSize,
                  decoration: ShapeDecoration(
                    color: variant.color,
                    shape: const CircleBorder(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
