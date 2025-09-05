// widgets/selectable_circle_size.dart
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';

class SelectableCircleSize extends StatefulWidget {
  final List<String> productSize;
  final EdgeInsetsGeometry? margin, padding;
  final ValueChanged<int>? onSizeSelected;
  final int? selectedSizeIndex;

  const SelectableCircleSize({
    Key? key,
    required this.productSize,
    this.margin,
    this.padding,
    this.onSizeSelected,
    this.selectedSizeIndex,
  }) : super(key: key);

  @override
  _SelectableCircleSizeState createState() => _SelectableCircleSizeState();
}

class _SelectableCircleSizeState extends State<SelectableCircleSize> {
  int? _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      padding: widget.padding,
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: List.generate(
          widget.productSize.length,
              (index) {
            final size = widget.productSize[index];
            final isSelected = _selectedIndex == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });

                widget.onSizeSelected?.call(_selectedIndex!);
              },
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColor.primary : Colors.white,
                  border: Border.all(
                    color: isSelected ? AppColor.primary : AppColor.border,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  size,
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColor.secondary,
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