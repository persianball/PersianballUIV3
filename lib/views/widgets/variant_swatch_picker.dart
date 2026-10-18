// lib/views/widgets/variant_swatch_picker.dart
//
// انتخابِ رنگ با تصویرِ خودِ واریانت. بک‌اند برای هر رنگ یک `image` دارد؛
// دایره‌ی رنگیِ تنها («سورمه‌ای» یا «طوسی»؟) برای کفش کافی نبود — کاربر
// باید خودِ کفش را در آن رنگ ببیند.
//
// انتخاب با یک «قطره»ی سبزِ پشتِ کاشی‌ها نشان داده می‌شود که بینِ کاشی‌ها
// مثلِ مایع جاری می‌شود: لبه‌ی جلو زودتر راه می‌افتد، لبه‌ی عقب دیرتر
// می‌رسد، و قطره وقتی کشیده می‌شود کمی پهن‌تر و کوتاه‌تر می‌شود (حجمش ثابت
// می‌ماند) و در مقصد با کمی فنری‌بودن می‌نشیند.
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:persian_ball/views/widgets/app_network_image.dart';

class VariantSwatch {
  const VariantSwatch({
    required this.name,
    required this.color,
    this.imageUrl,
    this.available = true,
  });

  final String name;
  final Color color;

  /// آدرسِ کاملِ تصویرِ رنگ؛ null → کاشیِ تک‌رنگ
  final String? imageUrl;

  /// دست‌کم یک سایزِ موجود دارد
  final bool available;
}

class VariantSwatchPicker extends StatefulWidget {
  const VariantSwatchPicker({
    super.key,
    required this.swatches,
    required this.selectedIndex,
    required this.onSelected,
    this.tileSize = 64,
  });

  final List<VariantSwatch> swatches;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double tileSize;

  @override
  State<VariantSwatchPicker> createState() => _VariantSwatchPickerState();
}

class _VariantSwatchPickerState extends State<VariantSwatchPicker>
    with SingleTickerProviderStateMixin {
  static const double _gap = 12;
  static const double _ring = 4; // فاصله‌ی قطره از لبه‌ی کاشی

  /// حاشیه‌ی رسم دورِ کاشی‌ها: قطره و هاله‌اش روی کاشیِ اول/آخر و بالا/پایین
  /// بیرونِ بومِ رسم می‌افتاد و بریده می‌شد. ویوپورتِ اسکرول هم همین‌قدر
  /// پهن‌تر می‌شود تا کاشیِ اول با سربرگ هم‌تراز بماند.
  static const double _bleed = 10;

  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..value = 1;

  final ScrollController _scroll = ScrollController();
  late int _from = widget.selectedIndex;
  late int _to = widget.selectedIndex;

  @override
  void didUpdateWidget(covariant VariantSwatchPicker old) {
    super.didUpdateWidget(old);
    if (widget.selectedIndex != _to) _flowTo(widget.selectedIndex);
  }

  @override
  void dispose() {
    _flow.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  double get _step => widget.tileSize + _gap;

  void _flowTo(int i) {
    // قطره از هر جا که الان هست راه می‌افتد (حتی وسطِ حرکتِ قبلی)
    final current = _blobCenterIndex();
    setState(() {
      _from = current.round();
      _to = i;
    });
    if (_reduceMotion) {
      _flow.value = 1;
    } else {
      _flow.forward(from: 0);
    }
    _ensureVisible(i);
  }

  double _blobCenterIndex() {
    final t = _flow.value;
    return lerpDouble(_from.toDouble(), _to.toDouble(), Curves.easeInOut.transform(t))!;
  }

  void _ensureVisible(int i) {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    final start = _bleed + i * _step;
    final end = start + widget.tileSize + _ring * 2;
    double? target;
    if (start < pos.pixels) target = start - 8;
    if (end > pos.pixels + pos.viewportDimension) {
      target = end - pos.viewportDimension + 8;
    }
    if (target == null) return;
    _scroll.animateTo(
      target.clamp(0, pos.maxScrollExtent),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _tap(int i) {
    if (i == widget.selectedIndex) return;
    widget.onSelected(i);
    // والد معمولاً با selectedIndexِ تازه rebuild می‌کند؛ اگر نکرد هم
    // قطره راه می‌افتد.
    if (i != _to) _flowTo(i);
  }

  @override
  Widget build(BuildContext context) {
    final swatches = widget.swatches;
    if (swatches.isEmpty) return const SizedBox.shrink();
    final sel = widget.selectedIndex.clamp(0, swatches.length - 1);
    final selected = swatches[sel];
    final double box = widget.tileSize + _ring * 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(selected, swatches.length),
        const SizedBox(height: 2),
        SizedBox(
          height: box + _bleed * 2,
          child: LayoutBuilder(builder: (context, cons) {
            final double contentW =
                swatches.length * _step - _gap + _ring * 2;
            final double viewportW = cons.maxWidth + _bleed * 2;
            return OverflowBox(
              minWidth: viewportW,
              maxWidth: viewportW,
              alignment: Alignment.center,
              child: SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                child: SizedBox(
                  width: contentW + _bleed * 2,
                  height: box + _bleed * 2,
                  child: AnimatedBuilder(
                    animation: _flow,
                    builder: (context, _) => CustomPaint(
                      painter: _LiquidBlobPainter(
                        from: _from,
                        to: _to,
                        t: _flow.value,
                        step: _step,
                        size: box,
                        inset: _bleed,
                        rtl: Directionality.of(context) == TextDirection.rtl,
                        totalWidth: contentW,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(_bleed),
                        child: Row(
                          children: [
                            for (int i = 0; i < swatches.length; i++) ...[
                              if (i > 0) const SizedBox(width: _gap),
                              Padding(
                                padding: EdgeInsets.only(
                                  left: i == 0 ? _ring : 0,
                                  right: i == swatches.length - 1 ? _ring : 0,
                                ),
                                child: _Tile(
                                  swatch: swatches[i],
                                  size: widget.tileSize,
                                  selected: i == sel,
                                  onTap: () => _tap(i),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _header(VariantSwatch selected, int count) {
    return Row(
      children: [
        const Text(
          'رنگ:',
          style: TextStyle(
            fontFamily: 'Estedad',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColor.ink,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (current, previous) => Stack(
              alignment: AlignmentDirectional.centerStart,
              children: [...previous, if (current != null) current],
            ),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.45),
                  end: Offset.zero,
                ).animate(a),
                child: child,
              ),
            ),
            child: Row(
              key: ValueKey(selected.name),
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: selected.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColor.lineStrong, width: 1),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    selected.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColor.inkMuted,
                    ),
                  ),
                ),
                if (!selected.available) ...[
                  const SizedBox(width: 6),
                  const Text(
                    'ناموجود',
                    style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 12,
                      color: AppColor.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Text(
          '${_fa(count)} رنگ',
          style: const TextStyle(
            fontFamily: 'Estedad',
            fontSize: 12,
            color: AppColor.inkMuted,
          ),
        ),
      ],
    );
  }

  static String _fa(int n) {
    const d = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    return n.toString().split('').map((c) {
      final i = c.codeUnitAt(0) - 48;
      return (i >= 0 && i <= 9) ? d[i] : c;
    }).join();
  }
}

/// قطره‌ی سبزِ انتخاب. دو لبه با منحنی‌های متفاوت حرکت می‌کنند تا قطره
/// کشیده و بعد جمع شود؛ ارتفاع با پهنا معکوس تغییر می‌کند (حجم ثابت).
class _LiquidBlobPainter extends CustomPainter {
  _LiquidBlobPainter({
    required this.from,
    required this.to,
    required this.t,
    required this.step,
    required this.size,
    required this.rtl,
    required this.totalWidth,
    this.inset = 0,
  });

  final int from, to;
  final double t, step, size, totalWidth;
  final bool rtl;

  /// حاشیه‌ی رسم (همان _bleed) که محتوا با آن جابه‌جا شده
  final double inset;

  // Row در RTL از راست چیده می‌شود
  double _left(int i) =>
      inset + (rtl ? totalWidth - size - i * step : i * step);

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final double a = _left(from), b = _left(to);
    final bool forward = b >= a;
    // لبه‌ی جلو: سریع شروع، لبه‌ی عقب: با تأخیر
    final lead = Curves.easeOutCubic.transform((t / 0.72).clamp(0.0, 1.0));
    final trail =
        Curves.easeInOutCubic.transform(((t - 0.18) / 0.82).clamp(0.0, 1.0));
    // کمی پرتاب از مقصد و برگشت، مثلِ قطره‌ای که می‌نشیند
    final settle = t < 0.78
        ? 0.0
        : math.sin((t - 0.78) / 0.22 * math.pi) * 0.06 * (b - a).sign;

    double leadPos = lerpDouble(a, b, lead)!;
    double trailPos = lerpDouble(a, b, trail)!;
    leadPos += settle * step;
    final double left = forward ? trailPos : leadPos;
    final double right = (forward ? leadPos : trailPos) + size;
    final double width = right - left;

    // حجمِ ثابت: هرچه کشیده‌تر، کوتاه‌تر (حداکثر ~۱۸٪)
    final stretch = (width / size - 1).clamp(0.0, 3.0);
    final double h = size * (1 - 0.18 * math.min(stretch, 1.0));
    final double top = inset + (size - h) / 2;

    final rect = Rect.fromLTWH(left, top, width, h);
    final r = Radius.circular(AppShapes.rLg * 0.9);
    final rrect = RRect.fromRectAndRadius(rect, r);

    canvas.drawRRect(
      rrect.shift(const Offset(0, 4)),
      Paint()
        ..color = AppColor.pitchGreen.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = AppColor.greenGradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_LiquidBlobPainter old) =>
      old.t != t || old.from != from || old.to != to || old.rtl != rtl;
}

class _Tile extends StatefulWidget {
  const _Tile({
    required this.swatch,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final VariantSwatch swatch;
  final double size;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.swatch;
    final double scale = _pressed
        ? 0.92
        : widget.selected
            ? 1.0
            : (_hover ? 0.97 : 0.94);

    Widget media = s.imageUrl == null
        ? ColoredBox(color: s.color)
        : AppNetworkImage(
            url: s.imageUrl,
            fit: BoxFit.cover,
            width: widget.size,
            height: widget.size,
          );
    if (!s.available) {
      // ناموجود: خاکستری، ولی همچنان قابلِ دیدن (کاربر شاید فقط ببیند)
      media = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.33, 0.33, 0.33, 0, 0, //
          0.33, 0.33, 0.33, 0, 0, //
          0.33, 0.33, 0.33, 0, 0, //
          0, 0, 0, 0.7, 0,
        ]),
        child: media,
      );
    }

    return Semantics(
      button: true,
      selected: widget.selected,
      label: 'رنگ ${s.name}${s.available ? '' : '، ناموجود'}',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: Tooltip(
            message: s.name,
            waitDuration: const Duration(milliseconds: 500),
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 380),
              curve: widget.selected ? Curves.easeOutBack : Curves.easeOutCubic,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: ShapeDecoration(
                  color: AppColor.card,
                  shape: AppShapes.border(AppShapes.rMd),
                  shadows: widget.selected ? null : AppColor.cardShadow,
                ),
                child: SquircleClip(
                  radius: AppShapes.rMd,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      media,
                      // نقطه‌ی رنگ در گوشه: رنگ را حتی وقتی عکس روشن نیست
                      // معلوم می‌کند
                      PositionedDirectional(
                        bottom: 5,
                        start: 5,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: s.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Color(0x33000000), blurRadius: 3),
                            ],
                          ),
                        ),
                      ),
                      if (!s.available)
                        CustomPaint(painter: _StrikePainter()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StrikePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.88),
      Offset(size.width * 0.88, size.height * 0.12),
      Paint()
        ..color = AppColor.danger.withValues(alpha: 0.75)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
