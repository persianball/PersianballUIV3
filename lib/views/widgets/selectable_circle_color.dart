import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/ColorWay.dart';

class SelectableCircleColor extends StatefulWidget {
  final EdgeInsetsGeometry? margin, padding;
  final List<ColorWay> colorWay;
  /// فراخوانی وقتی رنگ تغییر کرد؛ [globalPosition] محل کلیک کاربر است
  final void Function(int index, Offset globalPosition) onColorSelected;

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
            return InkWell(
              onTapDown: (details) {
                setState(() {
                  _selectedIndex = index;
                });

                // ارسال ایندکس انتخاب به همراه محل کلیک
                widget.onColorSelected(index, details.globalPosition);
              },
              onTap: () {},
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: AppColor.primarySoft,
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Container(
                  width: widget.circleSize,
                  height: widget.circleSize,
                  decoration: BoxDecoration(
                    color: variant.color,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      width: (widget.circleSize / 10).clamp(2, 6),
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