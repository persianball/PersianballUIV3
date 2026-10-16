// lib/views/widgets/player/glass_surface.dart
//
// سطوحِ «شیشه‌ی مایع» برای کنترل‌های پخش‌کننده: تاریِ پس‌زمینه، تینتِ تیره‌ی
// نیمه‌شفاف، یک گرادیانِ روشنِ مورب (نورِ محیط)، حاشیه‌ی نازکِ روشن و یک
// خطِ براقِ بالایی. همه‌جا یک زبان: دکمه‌ی گرد، قرص، کارت.
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:persian_ball/views/widgets/motion.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 18,
    this.padding = EdgeInsets.zero,
    this.circle = false,
    this.tint = 0.34,
    this.blur = 18,
    this.highlight = true,
    this.shadow = true,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool circle;

  /// غلظتِ تینتِ تیره (۰ تا ۱)
  final double tint;
  final double blur;
  final bool highlight;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final BorderRadius br =
        circle ? BorderRadius.circular(999) : BorderRadius.circular(radius);
    final surface = ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: tint),
                  borderRadius: br,
                ),
              ),
            ),
            // نورِ موربِ محیط
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: br,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.20),
                      Colors.white.withValues(alpha: 0.04),
                      Colors.white.withValues(alpha: 0.10),
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.26), width: 1),
                ),
              ),
            ),
            // خطِ براقِ لبه‌ی بالا
            // روی سطوحِ گرد، خطِ براق بعد از برش یک قوسِ سفیدِ لکه‌مانند می‌شد
            if (highlight && !circle)
              Positioned(
                top: 1,
                left: radius * 0.6,
                right: radius * 0.6,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.35),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
    if (!shadow) return surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: const [
          BoxShadow(
              color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: surface,
    );
  }
}

/// دکمه‌ی گردِ شیشه‌ای با یک آیکن.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 40,
    this.iconSize,
    this.emphasis = false,
    this.enabled = true,
    this.child,
  });

  final IconData icon;

  /// به‌جای آیکن (مثلاً اسپینرِ بافر روی دکمه‌ی پخش)
  final Widget? child;
  final String tooltip;
  final VoidCallback? onTap;
  final double size;
  final double? iconSize;

  /// دکمه‌ی اصلی (پخش): تینتِ سبز و کمی پررنگ‌تر
  final bool emphasis;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Widget core = GlassSurface(
      circle: true,
      tint: emphasis ? 0.18 : 0.34,
      shadow: emphasis,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (emphasis)
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2FA45C).withValues(alpha: 0.75),
                      const Color(0xFF1B7A3E).withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            child ??
                Icon(icon,
                    size: iconSize ?? size * 0.56,
                    color:
                        Colors.white.withValues(alpha: enabled ? 1 : 0.38)),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 600),
        child: PressableScale(
          onTap: enabled ? onTap : null,
          pressedScale: 0.9,
          hoverScale: 1.06,
          child: core,
        ),
      ),
    );
  }
}

/// قرصِ شیشه‌ای با آیکن و برچسب (کیفیت، سرعت).
class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.94,
      child: GlassSurface(
        circle: true,
        tint: active ? 0.22 : 0.34,
        shadow: false,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            busy
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.6, color: Colors.white),
                  )
                : Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Estedad',
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
