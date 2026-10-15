// lib/views/widgets/shoe_size_guide.dart
//
// راهنمای سایزِ کفش در صفحه‌ی محصول. دو راه برای پیدا کردنِ سایز:
//   ۱) «طولِ پای من»: کاربر طولِ پایش را تنظیم می‌کند و سایزِ پیشنهادی،
//      وضعیتش در همین محصول و دکمه‌ی «انتخاب» را می‌بیند.
//   ۲) جدولِ کامل EU / UK / US / طولِ پا؛ ضربه روی هر ردیف همان را
//      پیشنهاد می‌کند. سایزهایی که این محصول دارد علامت دارند.
// موبایل: شیتِ پایین؛ نمایشگرِ بزرگ: دیالوگ.
import 'package:flutter/material.dart';

import 'package:persian_ball/constant/app_breakpoints.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:persian_ball/constant/shoe_size_chart.dart';
import 'package:persian_ball/views/widgets/app_buttons.dart';

/// [availability]: سایزهای همین محصول (EU) → موجود بودن.
/// [onPick] با سایزِ EUِ انتخاب‌شده صدا زده می‌شود.
Future<void> showShoeSizeGuide(
  BuildContext context, {
  required Map<String, bool> availability,
  String? selectedSize,
  ValueChanged<String>? onPick,
}) {
  final guide = ShoeSizeGuide(
    availability: availability,
    selectedSize: selectedSize,
    onPick: onPick,
  );
  final bool wide =
      MediaQuery.of(context).size.width >= AppBreakpoints.tablet;
  if (wide) {
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColor.milk,
        insetPadding: const EdgeInsets.all(24),
        shape: AppShapes.border(AppShapes.rXl),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 760),
          child: guide,
        ),
      ),
    );
  }
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.92),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: AppColor.milk,
          shape: AppShapes.borderTop(AppShapes.rXl),
        ),
        child: guide,
      ),
    ),
  );
}

class ShoeSizeGuide extends StatefulWidget {
  const ShoeSizeGuide({
    super.key,
    required this.availability,
    this.selectedSize,
    this.onPick,
  });

  final Map<String, bool> availability;
  final String? selectedSize;
  final ValueChanged<String>? onPick;

  @override
  State<ShoeSizeGuide> createState() => _ShoeSizeGuideState();
}

enum _Stock { available, soldOut, notOffered }

class _ShoeSizeGuideState extends State<ShoeSizeGuide> {
  late double _foot;

  @override
  void initState() {
    super.initState();
    // شروع از سایزِ انتخاب‌شده‌ی فعلی، تا جدول از همان‌جا معنا داشته باشد
    _foot = ShoeSizeChart.byEu(widget.selectedSize ?? '')?.footCm ?? 26;
  }

  ShoeSizeRow? get _match => ShoeSizeChart.forFoot(_foot);

  _Stock _stockOf(int eu) {
    final v = widget.availability['$eu'];
    if (v == null) return _Stock.notOffered;
    return v ? _Stock.available : _Stock.soldOut;
  }

  void _setFoot(double cm) {
    final v = cm.clamp(_sliderMin, _sliderMax);
    setState(() => _foot = (v * 2).round() / 2);
  }

  static const double _sliderMin = 23.5;
  static const double _sliderMax = 30.5;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(context),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 20 + bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _finder(),
                  const SizedBox(height: 18),
                  _sectionTitle('جدولِ سایز'),
                  const SizedBox(height: 8),
                  _table(),
                  const SizedBox(height: 10),
                  _legend(),
                  const SizedBox(height: 14),
                  _tip(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── سربرگ

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 8),
      child: Column(
        children: [
          if (MediaQuery.of(context).size.width < AppBreakpoints.tablet)
            Container(
              width: 46,
              height: 5,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: const ShapeDecoration(
                  color: AppColor.line, shape: StadiumBorder()),
            ),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                margin: const EdgeInsetsDirectional.only(start: 8, end: 10),
                decoration: const ShapeDecoration(
                  color: AppColor.pitchGreenSoft,
                  shape: CircleBorder(),
                ),
                child: const Icon(Icons.straighten_rounded,
                    color: AppColor.pitchGreen, size: 22),
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('راهنمای سایزِ کفش',
                        style: TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColor.ink)),
                    SizedBox(height: 2),
                    Text('سایزهای این فروشگاه اروپایی (EU) هستند',
                        style: TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 11.5,
                            color: AppColor.inkMuted)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'بستن',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded, color: AppColor.inkMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontFamily: 'Estedad',
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColor.ink));

  // ───────────────────────── «طولِ پای من»

  Widget _finder() {
    final match = _match;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: ShapeDecoration(
        color: AppColor.card,
        shape: AppShapes.border(AppShapes.rLg),
        shadows: AppColor.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FootDiagram(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('سایزت را پیدا کن'),
                    const SizedBox(height: 6),
                    ..._steps.map(_step),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // تنظیمِ طول: −/+ برای دقت، اسلایدر برای سرعت
          Row(
            children: [
              const Text('طولِ پای من',
                  style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 12.5,
                      color: AppColor.inkMuted)),
              const Spacer(),
              _stepBtn(Icons.remove_rounded, 'کم کردن',
                  () => _setFoot(_foot - 0.5)),
              SizedBox(
                width: 92,
                child: Text(
                  '${_fa(_foot)} سانت',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColor.ink),
                ),
              ),
              _stepBtn(Icons.add_rounded, 'زیاد کردن',
                  () => _setFoot(_foot + 0.5)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColor.pitchGreen,
              inactiveTrackColor: AppColor.line,
              thumbColor: AppColor.pitchGreen,
              overlayColor: AppColor.pitchGreen.withValues(alpha: 0.12),
              trackHeight: 4,
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: Slider(
              value: _foot,
              min: _sliderMin,
              max: _sliderMax,
              divisions: ((_sliderMax - _sliderMin) * 2).round(),
              semanticFormatterCallback: (v) => '${_fa(v)} سانتی‌متر',
              onChanged: _setFoot,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.15), end: Offset.zero)
                    .animate(a),
                child: c,
              ),
            ),
            child: match == null
                ? _recommendOutOfRange()
                : _recommendation(match),
          ),
        ],
      ),
    );
  }

  static const _steps = [
    'پاشنه را به دیوار بچسبان و روی کاغذ بایست.',
    'نوکِ بلندترین انگشت را علامت بزن.',
    'فاصله‌ی دیوار تا علامت را با خط‌کش بخوان.',
  ];

  Widget _step(String text) {
    final i = _steps.indexOf(text) + 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsetsDirectional.only(end: 6, top: 1),
            alignment: Alignment.center,
            decoration: const ShapeDecoration(
                color: AppColor.pitchGreenSoft, shape: CircleBorder()),
            child: Text(_faInt(i),
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColor.pitchGreen)),
          ),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 11.5,
                    height: 1.6,
                    color: AppColor.ink)),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, String label, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColor.cardMuted,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 18, color: AppColor.ink),
          ),
        ),
      ),
    );
  }

  Widget _recommendation(ShoeSizeRow r) {
    final stock = _stockOf(r.eu);
    final (String note, Color color, IconData icon) = switch (stock) {
      _Stock.available => ('در این مدل موجود است', AppColor.success,
          Icons.check_circle_rounded),
      _Stock.soldOut => ('در این مدل فعلاً ناموجود است', AppColor.danger,
          Icons.remove_circle_outline_rounded),
      _Stock.notOffered => ('این مدل در این سایز تولید نمی‌شود',
          AppColor.inkMuted, Icons.info_outline_rounded),
    };
    final bool alreadySelected = widget.selectedSize == '${r.eu}';
    return Container(
      key: ValueKey(r.eu),
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: AppColor.pitchGreenSoft,
        shape: AppShapes.border(AppShapes.rMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('سایزِ پیشنهادی',
                      style: TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 11,
                          color: AppColor.inkMuted)),
                  Text('${_faInt(r.eu)} EU',
                      style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColor.pitchGreen,
                          height: 1.3)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('UK ${_fa(r.uk)}',
                      style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColor.ink)),
                  Text('US ${_fa(r.us)}',
                      style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColor.ink)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(note,
                    style: TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ),
            ],
          ),
          if (stock == _Stock.available && widget.onPick != null) ...[
            const SizedBox(height: 10),
            GradientButton(
              label: alreadySelected
                  ? 'انتخاب شده'
                  : 'انتخابِ سایزِ ${_faInt(r.eu)}',
              height: 42,
              fontSize: 13,
              enabled: !alreadySelected,
              icon: Icon(alreadySelected
                  ? Icons.check_rounded
                  : Icons.touch_app_rounded),
              onPressed: alreadySelected
                  ? null
                  : () {
                      widget.onPick!('${r.eu}');
                      Navigator.of(context).maybePop();
                    },
            ),
          ],
        ],
      ),
    );
  }

  Widget _recommendOutOfRange() {
    final bool small = _foot < ShoeSizeChart.minFoot;
    return Container(
      key: ValueKey(small ? 'small' : 'big'),
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: AppColor.cardMuted,
        shape: AppShapes.border(AppShapes.rMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppColor.inkMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              small
                  ? 'کوچک‌تر از جدول است؛ کوچک‌ترین سایز ${_faInt(ShoeSizeChart.rows.first.eu)} است.'
                  : 'بزرگ‌تر از جدول است؛ برای سایزِ بزرگ‌تر با پشتیبانی تماس بگیر.',
              style: const TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 12,
                  height: 1.6,
                  color: AppColor.ink),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── جدول

  static const _flex = [3, 3, 3, 4];

  Widget _table() {
    final matchEu = _match?.eu;
    return Container(
      decoration: ShapeDecoration(
        color: AppColor.card,
        shape: AppShapes.border(AppShapes.rLg),
        shadows: AppColor.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: AppColor.cardMuted,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: [
                _cell('EU', _flex[0], header: true),
                _cell('UK', _flex[1], header: true),
                _cell('US', _flex[2], header: true),
                _cell('طولِ پا (سانت)', _flex[3], header: true),
              ],
            ),
          ),
          for (final r in ShoeSizeChart.rows) _row(r, r.eu == matchEu),
        ],
      ),
    );
  }

  Widget _row(ShoeSizeRow r, bool active) {
    final stock = _stockOf(r.eu);
    return Semantics(
      button: true,
      selected: active,
      label:
          'سایز ${r.eu} اروپایی، یو‌کی ${r.uk}، یو‌اس ${r.us}، طول پا ${r.footCm} سانتی‌متر',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => setState(() => _foot = r.footCm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
            color: active ? AppColor.pitchGreenSoft : Colors.transparent,
            border: BorderDirectional(
              top: const BorderSide(color: AppColor.line, width: 0.6),
              start: BorderSide(
                color: active ? AppColor.pitchGreen : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: _flex[0],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_faInt(r.eu),
                        style: TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: active ? AppColor.pitchGreen : AppColor.ink)),
                    const SizedBox(width: 5),
                    _StockDot(stock: stock),
                  ],
                ),
              ),
              _cell(_fa(r.uk), _flex[1], active: active),
              _cell(_fa(r.us), _flex[2], active: active),
              _cell(_fa(r.footCm), _flex[3], active: active),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(String t, int flex, {bool header = false, bool active = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        t,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Estedad',
          fontSize: header ? 11.5 : 13,
          fontWeight: header
              ? FontWeight.w700
              : (active ? FontWeight.w700 : FontWeight.w500),
          color: header
              ? AppColor.inkMuted
              : (active ? AppColor.pitchGreen : AppColor.ink),
        ),
      ),
    );
  }

  Widget _legend() {
    Widget item(_Stock s, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StockDot(stock: s),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 11,
                    color: AppColor.inkMuted)),
          ],
        );
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        item(_Stock.available, 'موجود در این مدل'),
        item(_Stock.soldOut, 'ناموجود'),
      ],
    );
  }

  Widget _tip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: AppColor.warning.withValues(alpha: 0.10),
        shape: AppShapes.border(AppShapes.rMd),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded,
              size: 18, color: AppColor.warning),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'بینِ دو سایز هستی؟ سایزِ بزرگ‌تر را بردار. پا را عصر و با '
              'جورابِ ورزشی اندازه بگیر؛ آن موقع کمی بزرگ‌تر از صبح است.',
              style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 11.5,
                  height: 1.7,
                  color: AppColor.ink),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── اعداد

  static String _faInt(int n) => _digits(n.toString());

  /// ۲۶٫۵ — ممیزِ فارسی، و بدونِ «.۰» اضافه
  static String _fa(double v) {
    final s = v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    return _digits(s).replaceAll('.', '٫');
  }

  static String _digits(String s) {
    const d = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    return s.split('').map((c) {
      final i = c.codeUnitAt(0) - 48;
      return (i >= 0 && i <= 9) ? d[i] : c;
    }).join();
  }
}

class _StockDot extends StatelessWidget {
  const _StockDot({required this.stock});
  final _Stock stock;

  @override
  Widget build(BuildContext context) {
    if (stock == _Stock.notOffered) return const SizedBox(width: 7);
    final bool on = stock == _Stock.available;
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? AppColor.success : Colors.transparent,
        border: on ? null : Border.all(color: AppColor.danger, width: 1.4),
      ),
    );
  }
}

/// کفِ پا از بالا با خطِ اندازه‌ی «پاشنه تا نوکِ انگشت».
class _FootDiagram extends StatelessWidget {
  const _FootDiagram();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: 58,
        height: 92,
        child: CustomPaint(painter: _FootPainter()),
      ),
    );
  }
}

class _FootPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final fill = Paint()..color = AppColor.pitchGreenSoft;
    final stroke = Paint()
      ..color = AppColor.pitchGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // کف: بیضیِ کشیده که پاشنه باریک‌تر است
    final sole = Path()
      ..moveTo(w * 0.40, h * 0.98)
      ..cubicTo(w * 0.18, h * 0.98, w * 0.14, h * 0.72, w * 0.16, h * 0.52)
      ..cubicTo(w * 0.18, h * 0.32, w * 0.20, h * 0.20, w * 0.42, h * 0.20)
      ..cubicTo(w * 0.66, h * 0.20, w * 0.70, h * 0.36, w * 0.66, h * 0.56)
      ..cubicTo(w * 0.62, h * 0.76, w * 0.62, h * 0.98, w * 0.40, h * 0.98)
      ..close();
    canvas.drawPath(sole, fill);
    canvas.drawPath(sole, stroke);

    // انگشت‌ها: از شست (بزرگ) تا کوچک
    const toes = [
      [0.30, 0.10, 0.085],
      [0.47, 0.08, 0.065],
      [0.59, 0.11, 0.055],
      [0.68, 0.16, 0.048],
      [0.74, 0.23, 0.042],
    ];
    for (final t in toes) {
      final c = Offset(w * t[0], h * t[1]);
      canvas.drawCircle(c, w * t[2], fill);
      canvas.drawCircle(c, w * t[2], stroke);
    }

    // خطِ اندازه کنارِ پا
    final dim = Paint()
      ..color = AppColor.ink
      ..strokeWidth = 1.2;
    final x = w * 0.92;
    final top = h * 0.03, bottom = h * 0.98;
    canvas.drawLine(Offset(x, top), Offset(x, bottom), dim);
    canvas.drawLine(Offset(x - 4, top), Offset(x + 4, top), dim);
    canvas.drawLine(Offset(x - 4, bottom), Offset(x + 4, bottom), dim);
    final arrow = Path()
      ..moveTo(x, top)
      ..lineTo(x - 3, top + 5)
      ..moveTo(x, top)
      ..lineTo(x + 3, top + 5)
      ..moveTo(x, bottom)
      ..lineTo(x - 3, bottom - 5)
      ..moveTo(x, bottom)
      ..lineTo(x + 3, bottom - 5);
    canvas.drawPath(
        arrow,
        Paint()
          ..color = AppColor.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
