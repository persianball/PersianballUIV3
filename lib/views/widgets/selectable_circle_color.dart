import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/ColorWay.dart';

class SelectableCircleColor extends StatefulWidget {
  final EdgeInsetsGeometry? margin, padding;
  final List<ColorWay> colorWay;
  final ValueChanged<String?> onColorSelected; // فراخوانی وقتی رنگ تغییر کرد

  SelectableCircleColor({
    Key? key,
    required this.colorWay,
    this.margin,
    this.padding,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  _SelectableCircleState createState() => _SelectableCircleState();
}

class _SelectableCircleState extends State<SelectableCircleColor> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      padding: widget.padding,
      child: Wrap(
        spacing: 20,
        runSpacing: 8,
        children: List.generate(
          widget.colorWay.length,
              (index) {
            final variant = widget.colorWay[index];
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                // ارسال آدرس تصویر به صفحه والد
                widget.onColorSelected(variant.imageUrl);
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: AppColor.primarySoft,
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: variant.color,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      width: 4,
                      color: (index == _selectedIndex)
                          ? AppColor.primarySoft.withOpacity(0.9)
                          : Colors.transparent,
                    ),
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