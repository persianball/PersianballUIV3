import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/constant/app_shapes.dart';

/// دکمه‌ی اصلی اپ: قرصی (کاملاً گرد)، پس‌زمینه‌ی گرادیان سبز و سایه‌ی
/// سبزفام تا برجسته دیده شود. هیچ گوشه‌ی تیزی ندارد.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 52,
    this.expand = true,
    this.gradient,
    this.foregroundColor = AppColor.onPitchGreen,
    this.fontSize = 15,
    this.enabled = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// آیکن کوچک کنار متن (ترجیحاً آیکن مینیمال یا SvgPicture)
  final Widget? icon;

  final double height;
  final bool expand;
  final Gradient? gradient;
  final Color foregroundColor;
  final double fontSize;
  final bool enabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bool active = enabled && !loading && onPressed != null;

    final Widget content = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: foregroundColor),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                IconTheme(
                  data: IconThemeData(color: foregroundColor, size: 18),
                  child: icon!,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: foregroundColor,
                ),
              ),
            ],
          );

    return Opacity(
      opacity: active ? 1 : 0.5,
      child: Container(
        width: expand ? double.infinity : null,
        height: height,
        decoration: ShapeDecoration(
          gradient: gradient ?? AppColor.greenGradient,
          shape: AppShapes.pill,
          shadows: active ? AppColor.greenShadow : null,
        ),
        child: Material(
          color: Colors.transparent,
          shape: AppShapes.pill,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: active ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              // widthFactor وقتی expand=false لازم است: Center بدونِ آن
              // تمام عرضِ در دسترس را می‌گیرد، پس این پرچم عملاً بی‌اثر بود
              // و دکمه‌های «غیرکشیده» در دسکتاپ تمام‌عرض می‌شدند.
              child: Center(
                widthFactor: expand ? null : 1,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// دکمه‌ی ثانویه: قرصی، سطح سفید برجسته با بوردر ملایم.
class SoftButton extends StatelessWidget {
  const SoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 48,
    this.expand = true,
    this.color = AppColor.pitchGreen,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final double height;
  final bool expand;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expand ? double.infinity : null,
      height: height,
      decoration: ShapeDecoration(
        color: AppColor.card,
        shape: AppShapes.pill.copyWith(
          side: BorderSide(color: color.withValues(alpha: 0.35)),
        ),
        shadows: AppColor.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        shape: AppShapes.pill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    IconTheme(
                      data: IconThemeData(color: color, size: 18),
                      child: icon!,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// دکمه‌ی آیکنی گرد و برجسته (بازگشت، اشتراک‌گذاری و…)
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.color = AppColor.card,
    this.iconColor = AppColor.ink,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color color;
  final Color iconColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: color,
        shape: const CircleBorder(),
        shadows: AppColor.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Icon(icon, size: size * 0.5, color: iconColor),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// بج/تگ کوچک قرصی با آیکن مینیمال — برای جزئیات ریز محصول و دوره
/// (سطح، مدت، موجودی، امتیاز، تخفیف و…).
class PillTag extends StatelessWidget {
  const PillTag({
    super.key,
    required this.label,
    this.icon,
    this.svgAsset,
    this.color = AppColor.pitchGreen,
    this.background,
    this.gradient,
    this.dense = false,
  });

  final String label;
  final IconData? icon;

  /// مسیر آیکن SVG (اگر داده شود، به‌جای [icon] استفاده می‌شود)
  final String? svgAsset;

  final Color color;
  final Color? background;
  final Gradient? gradient;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: ShapeDecoration(
        color: gradient == null
            ? (background ?? color.withValues(alpha: 0.10))
            : null,
        gradient: gradient,
        shape: AppShapes.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (svgAsset != null) ...[
            SvgPicture.asset(
              svgAsset!,
              width: dense ? 11 : 13,
              height: dense ? 11 : 13,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            SizedBox(width: dense ? 3 : 5),
          ] else if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: color),
            SizedBox(width: dense ? 3 : 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Estedad',
              fontSize: dense ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
