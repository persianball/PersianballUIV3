// lib/views/widgets/detail_tabs.dart
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';

class DetailTab {
  final String title;
  final WidgetBuilder builder;

  const DetailTab({required this.title, required this.builder});
}

/// تب‌های صفحه جزئیات (کالا/دوره) با ترنزیشن نرم بین محتواها.
///
/// از TabBarView استفاده نمی‌کند چون این ویجت داخل ListView قرار می‌گیرد و
/// ارتفاع نامحدود است؛ در عوض فقط تب فعال ساخته می‌شود و تغییر ارتفاع هم با
/// AnimatedSize نرم می‌شود. سوایپ افقی هم پشتیبانی می‌شود.
class DetailTabs extends StatefulWidget {
  final List<DetailTab> tabs;
  final int initialIndex;

  /// پوسته تیره/طلایی طرح Obsidian Gold Athletics. پیش‌فرض false تا
  /// صفحاتی که هنوز بازطراحی نشده‌اند (مثل course_detail_page) بدون تغییر بمانند.
  final bool dark;

  const DetailTabs(
      {super.key, required this.tabs, this.initialIndex = 0, this.dark = false});

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
                  final slide = Tween<Offset>(
                    begin: Offset(0.06 * _direction, 0),
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

  Widget _tabBar() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = i == _index;
          return GestureDetector(
            onTap: () => _select(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: widget.dark
                  ? BoxDecoration(
                      color: selected
                          ? AppColor.goldEnd.withOpacity(0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? AppColor.goldEnd
                            : AppColor.outlineVariantDark,
                      ),
                    )
                  : BoxDecoration(
                      color: selected ? AppColor.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppColor.primary : AppColor.border,
                      ),
                    ),
              child: Text(
                widget.tabs[i].title,
                style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.dark
                      ? (selected ? AppColor.goldEnd : AppColor.onSurfaceVariant)
                      : (selected ? Colors.white : AppColor.secondary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
