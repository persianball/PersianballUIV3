import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';

/// بخش آکاردئونی (باز/بسته‌شونده) با سربرگ قرصی و بدنه‌ی کارت برجسته.
/// جایگزین تب‌ها در صفحه‌ی جزئیات محصول و دوره.
class AccordionSection extends StatefulWidget {
  const AccordionSection({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.initiallyExpanded = false,
    this.trailingBadge,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final bool initiallyExpanded;

  /// متن ریز کنار عنوان (مثلاً تعداد نظرات)
  final String? trailingBadge;

  @override
  State<AccordionSection> createState() => _AccordionSectionState();
}

class _AccordionSectionState extends State<AccordionSection>
    with SingleTickerProviderStateMixin {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: ShapeDecoration(
        color: AppColor.card,
        shape: AppShapes.border(AppShapes.rLg),
        shadows: AppColor.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            shape: AppShapes.border(AppShapes.rLg),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const ShapeDecoration(
                          color: AppColor.pitchGreenSoft,
                          shape: CircleBorder(),
                        ),
                        child: Icon(widget.icon,
                            size: 16, color: AppColor.pitchGreen),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColor.ink,
                      ),
                    ),
                    if (widget.trailingBadge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 1),
                        decoration: const ShapeDecoration(
                          color: AppColor.cardMuted,
                          shape: StadiumBorder(),
                        ),
                        child: Text(
                          widget.trailingBadge!,
                          style: const TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColor.inkMuted,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppColor.inkMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, color: AppColor.line),
                  const SizedBox(height: 12),
                  widget.child,
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}
