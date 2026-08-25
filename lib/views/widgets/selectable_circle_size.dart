// widgets/selectable_circle_size.dart
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';

/// انتخاب‌گر سایز، طبق طرح Obsidian Gold Athletics: دکمه‌های مربعی گوشه‌تیز
/// (این ویجت فقط در product_detail.dart استفاده می‌شود، پس بدون نگرانی از
/// شکستن جای دیگر می‌تواند مستقیم به شکل جدید تغییر کند).
class SelectableCircleSize extends StatefulWidget {
  final List<String> productSize;

  /// موجود بودن هر سایز، هم‌ترتیب با [productSize].
  /// اگر داده نشود همه سایزها موجود در نظر گرفته می‌شوند.
  final List<bool>? sizeAvailability;

  final EdgeInsetsGeometry? margin, padding;
  final ValueChanged<int>? onSizeSelected;
  final int? selectedSizeIndex;

  const SelectableCircleSize({
    Key? key,
    required this.productSize,
    this.sizeAvailability,
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

  bool _isAvailable(int index) {
    final list = widget.sizeAvailability;
    if (list == null || index >= list.length) return true;
    return list[index];
  }

  @override
  void initState() {
    super.initState();
    // انتخاب اولیه روی اولین سایز موجود قرار می‌گیرد
    final firstAvailable = List.generate(widget.productSize.length, (i) => i)
        .where(_isAvailable)
        .toList();
    _selectedIndex = widget.selectedSizeIndex ??
        (firstAvailable.isEmpty ? null : firstAvailable.first);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      padding: widget.padding,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: List.generate(
          widget.productSize.length,
              (index) {
            final size = widget.productSize[index];
            final available = _isAvailable(index);
            final isSelected = _selectedIndex == index && available;

            return GestureDetector(
              // سایز ناموجود قابل انتخاب نیست
              onTap: available
                  ? () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      widget.onSizeSelected?.call(index);
                    }
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 2),
                          content: Text(
                            'سایز $size ناموجود است',
                            style: const TextStyle(fontFamily: 'Estedad'),
                          ),
                        ),
                      );
                    },
              child: Opacity(
                opacity: available ? 1 : 0.5,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: ShapeDecoration(
                        color: isSelected ? null : AppColor.card,
                        gradient:
                            isSelected ? AppColor.greenGradient : null,
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : AppColor.line,
                          ),
                        ),
                        shadows: isSelected
                            ? AppColor.greenShadow
                            : AppColor.cardShadow,
                      ),
                      child: Text(
                        size,
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected
                              ? AppColor.onPitchGreen
                              : AppColor.ink,
                        ),
                      ),
                    ),
                    // ضربدر روی سایز ناموجود
                    if (!available)
                      IgnorePointer(
                        child: CustomPaint(
                          size: const Size(48, 48),
                          painter: _UnavailableCrossPainter(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// خط ضربدر روی دکمه‌ی سایز ناموجود
class _UnavailableCrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.75)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const inset = 8.0;
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(size.width - inset, inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
