// lib/views/widgets/detail_tabs.dart
import 'package:flutter/material.dart';
import 'package:marketky/views/widgets/category_pill_bar.dart';

class DetailTab {
  final String title;
  final WidgetBuilder builder;

  /// آیکن کوچک کنار عنوان تب
  final IconData? icon;

  const DetailTab({required this.title, required this.builder, this.icon});
}

/// تب‌های صفحه جزئیات (کالا/دوره) با ترنزیشن نرم بین محتواها.
///
/// از TabBarView استفاده نمی‌کند چون این ویجت داخل ListView قرار می‌گیرد و
/// ارتفاع نامحدود است؛ در عوض فقط تب فعال ساخته می‌شود و تغییر ارتفاع هم با
/// AnimatedSize نرم می‌شود. سوایپ افقی هم پشتیبانی می‌شود.
class DetailTabs extends StatefulWidget {
  final List<DetailTab> tabs;
  final int initialIndex;

  const DetailTabs({super.key, required this.tabs, this.initialIndex = 0});

  @override
  State<DetailTabs> createState() => _DetailTabsState();
}

class _DetailTabsState extends State<DetailTabs> {
  late int _index = widget.initialIndex.clamp(0, widget.tabs.length - 1);

  /// جهت اسلاید بر اساس اینکه به تب بعدی می‌رویم یا قبلی
  int _direction = 1;

  void _select(int next) {
    if (next == _index || next < 0 || next >= widget.tabs.length) return;
    setState(() {
      _direction = next > _index ? 1 : -1;
      _index = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tabBar(),
          const SizedBox(height: 12),
          // سوایپ افقی برای جابه‌جایی بین تب‌ها
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              final v = details.primaryVelocity ?? 0;
              if (v.abs() < 200) return;
              // در RTL سوایپ به راست یعنی تب قبلی
              _select(v > 0 ? _index - 1 : _index + 1);
            },
            child: AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                ),
                transitionBuilder: (child, animation) {
                  // در RTL تبِ بعدی سمتِ چپ است، پس محتوای تازه از چپ وارد
                  // می‌شود — هم‌جهت با حرکتِ قرصِ سبز. پیش‌تر برعکس بود و
                  // محتوا خلافِ جهتِ نشانگر سُر می‌خورد.
                  final slide = Tween<Offset>(
                    begin: Offset(-0.06 * _direction, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_index),
                  child: Builder(builder: widget.tabs[_index].builder),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// همان نوارِ دسته‌بندیِ فروشگاه: یک قرصِ سبزِ واحد که از تبِ قبلی کنده
  /// می‌شود و تا تبِ جدید سُر می‌خورد. پیش‌تر هر چیپ رنگِ خودش را عوض
  /// می‌کرد و جابه‌جایی یک پرشِ ناگهانی بود.
  Widget _tabBar() {
    return CategoryPillBar(
      labels: [for (final t in widget.tabs) t.title],
      icons: [for (final t in widget.tabs) t.icon],
      selectedIndex: _index,
      onSelected: _select,
      padding: EdgeInsets.zero,
      fontSize: 13,
    );
  }
}
