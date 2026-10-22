// lib/views/widgets/course_path.dart
//
// مسیرِ شماره‌دارِ یادگیری: دایره‌ی شماره + خطِ اتصال به گامِ قبلی و بعدی.
// در صفحه‌ی سوپرکورس هر گام یکی از دوره‌های مسیر است.
import 'package:flutter/material.dart';
import 'package:persian_ball/constant/app_color.dart';

class CoursePathStep extends StatelessWidget {
  const CoursePathStep({
    super.key,
    required this.index,
    required this.isLast,
    required this.child,
    this.highlighted = false,
  });

  /// از صفر؛ روی دایره index+1 نوشته می‌شود.
  final int index;
  final bool isLast;
  final bool highlighted;
  final Widget child;

  static const double _rail = 18; // فاصله‌ی مرکزِ دایره از لبه‌ی شروع
  static const double _dot = 36;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (index > 0)
          const PositionedDirectional(
            start: _rail - 1,
            top: 0,
            height: 10,
            child: _RailLine(),
          ),
        if (!isLast)
          const PositionedDirectional(
            start: _rail - 1,
            top: 10 + _dot,
            bottom: 0,
            child: _RailLine(),
          ),
        Padding(
          padding: EdgeInsets.only(bottom: isLast ? 4 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: _dot,
                  height: _dot,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    gradient: highlighted ? AppColor.greenGradient : null,
                    color: highlighted ? null : AppColor.surfaceContainer,
                    shape: CircleBorder(
                      side: BorderSide(
                          color: AppColor.pitchGreen
                              .withValues(alpha: highlighted ? 0 : 0.45),
                          width: 1.5),
                    ),
                    shadows: highlighted ? AppColor.greenShadow : null,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: highlighted
                          ? AppColor.onPitchGreen
                          : AppColor.pitchGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }
}

class _RailLine extends StatelessWidget {
  const _RailLine();

  @override
  Widget build(BuildContext context) => Container(
        width: 2,
        decoration: BoxDecoration(
          color: AppColor.pitchGreen.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(1),
        ),
      );
}
