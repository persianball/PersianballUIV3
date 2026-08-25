// views/widgets/modals/add_course_to_cart_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/bloc/cart/cart_bloc.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/models/course_detail_model.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/views/widgets/app_buttons.dart';
import 'package:marketky/views/widgets/page_container.dart';

class AddCourseToCartModal extends StatefulWidget {
  final CourseTimeAndLocationItem
      courseItem; // دوره‌ای که کاربر می‌خواهد اضافه کند

  const AddCourseToCartModal({Key? key, required this.courseItem})
      : super(key: key);

  @override
  _AddCourseToCartModalState createState() => _AddCourseToCartModalState();
}

class _AddCourseToCartModalState extends State<AddCourseToCartModal> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = 1;
  }

  @override
  Widget build(BuildContext context) {
    // محاسبات دقیقاً مثل قبل
    final totalPrice = widget.courseItem.price * _quantity;
    final discountedPrice = widget.courseItem.discountPercentage > 0
        ? ((widget.courseItem.discountPercentage / 100) * totalPrice).toInt()
        : 0;
    final payable = totalPrice - discountedPrice;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        child: PageContainer(
          maxWidth: 700.0,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: ShapeDecoration(
              color: AppColor.milk,
              shape: ContinuousRectangleBorder(
                borderRadius: AppShapes.radiusTop(AppShapes.rXl),
              ),
              shadows: AppColor.floatingShadow,
            ),
            padding: EdgeInsets.only(
              left: 14,
              right: 14,
              top: 10,
              // فضای نوار ناوبری سیستم تا دکمه‌ی افزودن زیر آن گیر نکند
              bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // دستگیره‌ی کشیدن
                Container(
                  width: 46,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: const ShapeDecoration(
                    color: AppColor.line,
                    shape: StadiumBorder(),
                  ),
                ),

                // سربرگ
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
                  child: Row(
                    children: [
                      const Text(
                        'ثبت‌نام دوره',
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColor.ink,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded,
                            size: 20, color: AppColor.inkMuted),
                      ),
                    ],
                  ),
                ),

                // کارت دوره
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: ShapeDecoration(
                    color: AppColor.card,
                    shape: AppShapes.border(AppShapes.rLg),
                    shadows: AppColor.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const ShapeDecoration(
                              color: AppColor.pitchGreenSoft,
                              shape: CircleBorder(),
                            ),
                            child: const Icon(Icons.school_rounded,
                                size: 18, color: AppColor.pitchGreen),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.courseItem.courseName,
                              style: const TextStyle(
                                fontFamily: 'Estedad',
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColor.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          PillTag(
                            label: widget.courseItem.location,
                            icon: Icons.place_rounded,
                            color: AppColor.categoryBadge,
                            dense: true,
                          ),
                          PillTag(
                            label: widget.courseItem.time,
                            icon: Icons.schedule_rounded,
                            color: AppColor.levelExpert,
                            dense: true,
                          ),
                          if (widget.courseItem.discountPercentage > 0)
                            PillTag(
                              label:
                                  '٪${widget.courseItem.discountPercentage} تخفیف',
                              icon: Icons.local_offer_rounded,
                              color: Colors.white,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEF4444), AppColor.danger],
                              ),
                              dense: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // تعداد + جمع‌بندی مبلغ
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  decoration: ShapeDecoration(
                    color: AppColor.card,
                    shape: AppShapes.border(AppShapes.rLg),
                    shadows: AppColor.cardShadow,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'تعداد',
                            style: TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 13,
                              color: AppColor.inkMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          _StepperButton(
                            icon: Icons.remove_rounded,
                            onTap: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                          ),
                          Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Estedad',
                                color: AppColor.ink,
                              ),
                            ),
                          ),
                          _StepperButton(
                            icon: Icons.add_rounded,
                            filled: true,
                            onTap: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColor.line),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: 'قیمت',
                        value: '${thousandSeparator(totalPrice)} تومان',
                      ),
                      if (widget.courseItem.discountPercentage > 0) ...[
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'تخفیف',
                          value:
                              '${thousandSeparator(discountedPrice)} (٪${widget.courseItem.discountPercentage})',
                          valueColor: AppColor.danger,
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColor.line),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: 'مبلغ قابل پرداخت',
                        value: '${thousandSeparator(payable)} تومان',
                        bold: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // دکمه افزودن — همان منطق قبلی
                GradientButton(
                  label: 'افزودن به سبد',
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  onPressed: () {
                    context.read<CartBloc>().add(
                        AddCourseToCart(context, widget.courseItem.id, _quantity));
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Container(
        width: 34,
        height: 34,
        decoration: ShapeDecoration(
          color: filled ? null : AppColor.cardMuted,
          gradient: filled ? AppColor.greenGradient : null,
          shape: const CircleBorder(),
          shadows: filled && enabled ? AppColor.greenShadow : null,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Icon(icon,
                size: 18,
                color: filled ? AppColor.onPitchGreen : AppColor.ink),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Estedad',
            fontSize: bold ? 14 : 13,
            color: bold ? AppColor.ink : AppColor.inkMuted,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Estedad',
            fontSize: bold ? 15 : 13,
            color: valueColor ?? (bold ? AppColor.pitchGreen : AppColor.ink),
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
