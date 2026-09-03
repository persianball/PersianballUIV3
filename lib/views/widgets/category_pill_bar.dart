// lib/views/widgets/category_pill_bar.dart
//
// نوار دسته‌بندی با نشانگرِ متحرک.
//
// پیش‌تر هر چیپ خودش پس‌زمینه‌ی سبز می‌گرفت، پس تعویض دسته یک پرشِ ناگهانی
// بود: رنگ از یک دکمه می‌پرید و روی دکمه‌ی دیگر ظاهر می‌شد. اینجا فقط *یک*
// قرصِ سبز وجود دارد که پشت برچسب‌ها می‌نشیند و هنگام انتخاب، از دکمه‌ی
// قبلی کنده می‌شود و تا دکمه‌ی جدید سُر می‌خورد.
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/constant/app_text_styles.dart';

class CategoryPillBar extends StatefulWidget {
  const CategoryPillBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.height = 42,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.clipBehavior = Clip.none,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double height;
  final EdgeInsets padding;
  final Clip clipBehavior;

  @override
  State<CategoryPillBar> createState() => _CategoryPillBarState();
}

class _CategoryPillBarState extends State<CategoryPillBar> {
  static const Duration _travel = Duration(milliseconds: 340);

  final ScrollController _scroll = ScrollController();
  final GlobalKey _rowKey = GlobalKey();
  List<GlobalKey> _keys = const [];

  /// هندسه‌ی هر چیپ نسبت به ردیف؛ تا اندازه‌گیری نشود نشانگر رسم نمی‌شود.
  List<({double left, double width})> _rects = const [];

  /// در حین حرکت، قرص کمی جمع می‌شود و سایه‌اش پررنگ‌تر — همان حسِ
  /// «کنده شدن از دکمه و رفتن به دکمه‌ی بعدی».
  bool _moving = false;

  @override
  void initState() {
    super.initState();
    _syncKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant CategoryPillBar old) {
    super.didUpdateWidget(old);
    if (old.labels.length != widget.labels.length ||
        !_sameLabels(old.labels, widget.labels)) {
      _syncKeys();
      _rects = const [];
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
    if (old.selectedIndex != widget.selectedIndex) {
      _startTravel();
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
    }
  }

  static bool _sameLabels(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _syncKeys() {
    _keys = List.generate(widget.labels.length, (_) => GlobalKey());
  }

  void _startTravel() {
    setState(() => _moving = true);
    Future.delayed(_travel, () {
      if (mounted) setState(() => _moving = false);
    });
  }

  /// موقعیت هر چیپ نسبت به ردیف. با globalToLocal حساب می‌شود تا در RTL
  /// هم درست بماند (Positioned.left معنای جهت‌دار ندارد).
  void _measure() {
    if (!mounted) return;
    final rowBox = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (rowBox == null || !rowBox.hasSize) return;
    final next = <({double left, double width})>[];
    for (final key in _keys) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return; // هنوز چیده نشده
      final left = rowBox.globalToLocal(box.localToGlobal(Offset.zero)).dx;
      next.add((left: left, width: box.size.width));
    }
    if (_rects.length == next.length) {
      var same = true;
      for (int i = 0; i < next.length; i++) {
        if ((_rects[i].left - next[i].left).abs() > 0.5 ||
            (_rects[i].width - next[i].width).abs() > 0.5) {
          same = false;
          break;
        }
      }
      if (same) return;
    }
    setState(() => _rects = next);
    _revealSelected();
  }

  /// دسته‌ی انتخاب‌شده باید دیده شود، حتی اگر بیرون از کادر اسکرول باشد.
  void _revealSelected() {
    if (!mounted || !_scroll.hasClients) return;
    final i = widget.selectedIndex;
    if (i < 0 || i >= _rects.length) return;
    final r = _rects[i];
    final viewport = _scroll.position.viewportDimension;
    final target = (r.left + r.width / 2 - viewport / 2)
        .clamp(_scroll.position.minScrollExtent,
            _scroll.position.maxScrollExtent)
        .toDouble();
    _scroll.animateTo(target,
        duration: _travel, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // اندازه‌ها بعد از هر چیدمان دوباره چک می‌شوند (تغییر عرض، فونت، متن)
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

    final int sel = widget.selectedIndex;
    final bool hasIndicator =
        sel >= 0 && sel < _rects.length && _rects.isNotEmpty;

    return SizedBox(
      height: widget.height,
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        clipBehavior: widget.clipBehavior,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // پس‌زمینه‌ی خنثیِ چیپ‌ها، *زیر* نشانگر رسم می‌شود؛ اگر داخل
            // خود چیپ می‌ماند، قرصِ متحرک را می‌پوشاند.
            for (int i = 0; i < _rects.length; i++)
              Positioned(
                left: _rects[i].left,
                width: _rects[i].width,
                top: 0,
                bottom: 0,
                child: const DecoratedBox(
                  decoration: ShapeDecoration(
                    color: AppColor.cardMuted,
                    shape: StadiumBorder(),
                  ),
                ),
              ),
            if (hasIndicator)
              AnimatedPositioned(
                duration: _travel,
                curve: Curves.easeInOutCubic,
                left: _rects[sel].left,
                width: _rects[sel].width,
                top: 0,
                bottom: 0,
                child: AnimatedScale(
                  // جمع شدنِ عمودیِ ملایم در حین سفر
                  scale: _moving ? 0.92 : 1.0,
                  duration: const Duration(milliseconds: 170),
                  curve: Curves.easeOut,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      gradient: AppColor.greenGradient,
                      shape: AppShapes.pill,
                      shadows: AppColor.greenShadow,
                    ),
                  ),
                ),
              ),
            Row(
              key: _rowKey,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < widget.labels.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    // کلید روی خودِ قرص است نه روی Padding، وگرنه نشانگر به
                    // اندازه‌ی حاشیه‌ها بزرگ‌تر از چیپ می‌شود.
                    child: KeyedSubtree(
                      key: _keys[i],
                      child: Material(
                      color: Colors.transparent,
                      shape: AppShapes.pill,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => widget.onSelected(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          child: AnimatedDefaultTextStyle(
                            duration: _travel,
                            curve: Curves.easeOutCubic,
                            style: AppTextStyles.labelSm.copyWith(
                              letterSpacing: 0,
                              fontWeight:
                                  i == sel ? FontWeight.w700 : FontWeight.w500,
                              color:
                                  i == sel ? Colors.white : AppColor.inkMuted,
                            ),
                            child: Text(widget.labels[i]),
                          ),
                        ),
                      ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
