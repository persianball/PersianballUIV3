// lib/views/widgets/course_lesson_list.dart
//
// فهرستِ درس‌های یک دوره: هفته‌بندی‌شده، با جست‌وجو، فیلترِ هفته، نوارِ
// پیشرفتِ هر ویدیو و نشانه‌ی «در حالِ پخش».
//
// همین ویجت هم داخلِ باتم‌شیتِ کشیدنیِ موبایل استفاده می‌شود هم در ستونِ
// کناریِ دسکتاپ، تا هر دو چیدمان دقیقاً یک رفتار داشته باشند.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/models/course_models.dart';
import 'package:marketky/services/course_progress_service.dart';
import 'package:marketky/views/widgets/app_network_image.dart';
import 'package:marketky/views/widgets/motion.dart';

/// ارتفاعِ ثابتِ ردیف‌ها؛ ثابت بودنشان اجازه می‌دهد محلِ «درسِ فعلی» بدون
/// ساختنِ ویجت‌های خارج از دید دقیق حساب و به آن اسکرول شود.
const double kLessonRowHeight = 78;
const double kWeekHeaderHeight = 46;

/// یک درس در فهرستِ صافِ دوره (هفته و سکشن با هم).
class CourseLesson {
  const CourseLesson({
    required this.weekIndex,
    required this.sectionIndex,
    required this.flatIndex,
    required this.weekTitle,
    required this.weekNumber,
    required this.section,
  });

  final int weekIndex;
  final int sectionIndex;

  /// شماره‌ی پیوسته در کلِ دوره (۰ تا تعدادِ درس‌ها).
  final int flatIndex;

  final String weekTitle;
  final String weekNumber;
  final MyCourseWeekSectionItem section;

  String get title => section.title;
  bool get locked => section.isLocked;
  String get videoUrl => (section.videoUrl ?? '').trim();
  bool get playable => !locked && videoUrl.isNotEmpty;

  /// شناسه‌ی پایدارِ ذخیره‌ی پیشرفت — همان قراردادِ [CourseProgressService].
  String get progressKey =>
      videoUrl.isNotEmpty ? videoUrl : '$weekNumber::${section.title}';
}

/// هفته‌های تودرتو را به یک فهرستِ صافِ قابلِ ایندکس تبدیل می‌کند.
List<CourseLesson> flattenLessons(List<MyCourseWeek> weeks) {
  final out = <CourseLesson>[];
  int flat = 0;
  for (int wi = 0; wi < weeks.length; wi++) {
    final week = weeks[wi];
    final name = (week.weekName ?? '').trim();
    final title = name.isNotEmpty ? name : 'هفته ${week.weekNumber}';
    for (int si = 0; si < week.sections.length; si++) {
      out.add(CourseLesson(
        weekIndex: wi,
        sectionIndex: si,
        flatIndex: flat++,
        weekTitle: title,
        weekNumber: week.weekNumber,
        section: week.sections[si],
      ));
    }
  }
  return out;
}

/// باتم‌شیتِ کشیدنیِ «فهرست درس‌ها».
///
/// با ضربه روی یک درس، شیت بسته می‌شود و همان درس پخش می‌شود؛ ولی
/// علامت‌زدنِ «دیده شد» شیت را باز نگه می‌دارد تا کاربر بتواند چند درس را
/// پشتِ‌هم تیک بزند.
Future<void> showCourseLessonsSheet(
  BuildContext context, {
  required List<CourseLesson> lessons,
  required ValueListenable<CourseProgress> progress,
  required ValueListenable<String?> currentKey,
  required ValueChanged<CourseLesson> onPlay,
  required ValueChanged<CourseLesson> onToggleSeen,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x73000000),
    useSafeArea: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: 0.66,
      minChildSize: 0.42,
      maxChildSize: 0.94,
      snap: true,
      snapSizes: const [0.66, 0.94],
      expand: false,
      builder: (context, controller) => Container(
        decoration: ShapeDecoration(
          color: AppColor.milk,
          shape: AppShapes.borderTop(AppShapes.rXl),
          shadows: AppColor.floatingShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: CourseLessonList(
          lessons: lessons,
          progress: progress,
          currentKey: currentKey,
          scrollController: controller,
          showHandle: true,
          onPlay: (lesson) {
            Navigator.of(sheetContext).pop();
            onPlay(lesson);
          },
          onToggleSeen: onToggleSeen,
        ),
      ),
    ),
  );
}

class CourseLessonList extends StatefulWidget {
  const CourseLessonList({
    super.key,
    required this.lessons,
    required this.progress,
    required this.currentKey,
    required this.onPlay,
    required this.onToggleSeen,
    this.scrollController,
    this.showHandle = false,
  });

  final List<CourseLesson> lessons;
  final ValueListenable<CourseProgress> progress;
  final ValueListenable<String?> currentKey;
  final ValueChanged<CourseLesson> onPlay;
  final ValueChanged<CourseLesson> onToggleSeen;

  /// در باتم‌شیت باید کنترلرِ خودِ شیت باشد وگرنه کشیدن کار نمی‌کند.
  final ScrollController? scrollController;

  /// دستگیره و عنوانِ بالای شیت (در ستونِ دسکتاپ لازم نیست).
  final bool showHandle;

  @override
  State<CourseLessonList> createState() => _CourseLessonListState();
}

class _CourseLessonListState extends State<CourseLessonList> {
  late final ScrollController _controller =
      widget.scrollController ?? ScrollController();
  final TextEditingController _search = TextEditingController();

  String _query = '';
  int? _weekFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealCurrent());
  }

  @override
  void dispose() {
    if (widget.scrollController == null) _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  /// اسکرول به درسی که همین حالا پخش می‌شود، تا کاربر با بازکردنِ فهرست
  /// دنبالِ جای خودش نگردد.
  void _revealCurrent() {
    final key = widget.currentKey.value;
    if (key == null || !_controller.hasClients) return;
    final rows = _buildRows();
    double offset = 0;
    for (final row in rows) {
      if (row.lesson?.progressKey == key) {
        final target = (offset - 120).clamp(0.0, _controller.position.maxScrollExtent);
        _controller.animateTo(
          target,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      offset += row.lesson == null ? kWeekHeaderHeight : kLessonRowHeight;
    }
  }

  List<_Row> _buildRows() {
    final q = _query.trim();
    final rows = <_Row>[];
    int? lastWeek;
    for (final lesson in widget.lessons) {
      if (_weekFilter != null && lesson.weekIndex != _weekFilter) continue;
      if (q.isNotEmpty && !lesson.title.contains(q)) continue;
      if (lastWeek != lesson.weekIndex) {
        lastWeek = lesson.weekIndex;
        rows.add(_Row.header(lesson.weekIndex, lesson.weekTitle));
      }
      rows.add(_Row.lesson(lesson));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CourseProgress>(
      valueListenable: widget.progress,
      builder: (context, progress, _) => ValueListenableBuilder<String?>(
        valueListenable: widget.currentKey,
        builder: (context, currentKey, __) {
          final rows = _buildRows();
          return CustomScrollView(
            controller: _controller,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              if (widget.showHandle)
                SliverToBoxAdapter(child: _handle(progress)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTools(
                  height: 106,
                  child: _tools(progress),
                ),
              ),
              if (rows.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _empty(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 28),
                  sliver: SliverList.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final row = rows[i];
                      final lesson = row.lesson;
                      if (lesson == null) {
                        return _weekHeader(row.weekTitle!, row.weekIndex!, progress);
                      }
                      return _LessonRow(
                        lesson: lesson,
                        watched: progress.of(lesson.progressKey),
                        isCurrent: currentKey == lesson.progressKey,
                        onPlay: () => widget.onPlay(lesson),
                        onToggleSeen: () => widget.onToggleSeen(lesson),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _handle(CourseProgress progress) {
    final total = widget.lessons.length;
    final seen = widget.lessons
        .where((l) => progress.isSeen(l.progressKey))
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColor.lineStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'فهرست درس‌ها',
                style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColor.ink,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: const ShapeDecoration(
                  color: AppColor.pitchGreenSoft,
                  shape: AppShapes.pill,
                ),
                child: Text(
                  '$seen از $total',
                  style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColor.pitchGreen,
                  ),
                ),
              ),
              const Spacer(),
              CircleIconButtonSmall(
                icon: Icons.close_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tools(CourseProgress progress) {
    final weeks = <int, String>{};
    for (final l in widget.lessons) {
      weeks[l.weekIndex] = l.weekTitle;
    }
    final entries = weeks.entries.toList();

    return Container(
      color: AppColor.milk,
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              height: 44,
              decoration: ShapeDecoration(
                color: AppColor.card,
                shape: AppShapes.pill.copyWith(
                  side: const BorderSide(color: AppColor.line),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search_rounded,
                      size: 19, color: AppColor.inkMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _query = v),
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 13.5,
                        color: AppColor.ink,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'جست‌وجو در درس‌ها…',
                        hintStyle: TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 13,
                          color: AppColor.inkMuted,
                        ),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded,
                          size: 17, color: AppColor.inkMuted),
                      tooltip: 'پاک‌کردن',
                    )
                  else
                    const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: entries.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _chip('همه', _weekFilter == null,
                      () => setState(() => _weekFilter = null));
                }
                final e = entries[i - 1];
                return _chip(e.value, _weekFilter == e.key,
                    () => setState(() => _weekFilter = e.key));
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: selected ? AppColor.pitchGreen : AppColor.card,
          shape: AppShapes.pill.copyWith(
            side: BorderSide(
              color: selected ? AppColor.pitchGreen : AppColor.line,
            ),
          ),
          shadows: selected ? AppColor.greenShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Estedad',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppColor.onPitchGreen : AppColor.inkMuted,
          ),
        ),
      ),
    );
  }

  Widget _weekHeader(String title, int weekIndex, CourseProgress progress) {
    final lessons =
        widget.lessons.where((l) => l.weekIndex == weekIndex).toList();
    final seen = lessons.where((l) => progress.isSeen(l.progressKey)).length;
    final done = lessons.isNotEmpty && seen == lessons.length;

    return SizedBox(
      height: kWeekHeaderHeight,
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: done ? AppColor.pitchGreen : AppColor.pitchGreenSoft,
              shape: const CircleBorder(),
            ),
            child: done
                ? const Icon(Icons.check_rounded,
                    size: 14, color: AppColor.onPitchGreen)
                : Text(
                    '${weekIndex + 1}',
                    style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColor.pitchGreen,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Estedad',
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColor.ink,
              ),
            ),
          ),
          Text(
            '$seen/${lessons.length}',
            style: const TextStyle(
              fontFamily: 'Estedad',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColor.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 44, color: AppColor.lineStrong),
          const SizedBox(height: 12),
          const Text(
            'درسی با این عنوان پیدا نشد',
            style: TextStyle(
              fontFamily: 'Estedad',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColor.inkMuted,
            ),
          ),
          const SizedBox(height: 14),
          PressableScale(
            onTap: () {
              _search.clear();
              setState(() {
                _query = '';
                _weekFilter = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: const ShapeDecoration(
                color: AppColor.pitchGreenSoft,
                shape: AppShapes.pill,
              ),
              child: const Text(
                'نمایش همه‌ی درس‌ها',
                style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColor.pitchGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// یک ردیفِ فهرست: یا سرتیترِ هفته است یا یک درس.
class _Row {
  const _Row.header(this.weekIndex, this.weekTitle) : lesson = null;
  const _Row.lesson(CourseLesson this.lesson)
      : weekIndex = null,
        weekTitle = null;

  final CourseLesson? lesson;
  final int? weekIndex;
  final String? weekTitle;
}

class _StickyTools extends SliverPersistentHeaderDelegate {
  const _StickyTools({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      SizedBox(height: height, child: child);

  @override
  bool shouldRebuild(_StickyTools old) =>
      old.height != height || old.child != child;
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.lesson,
    required this.watched,
    required this.isCurrent,
    required this.onPlay,
    required this.onToggleSeen,
  });

  final CourseLesson lesson;
  final VideoProgress? watched;
  final bool isCurrent;
  final VoidCallback onPlay;
  final VoidCallback onToggleSeen;

  @override
  Widget build(BuildContext context) {
    final bool seen = watched?.seen ?? false;
    final double fraction = watched?.fraction ?? 0;
    final bool locked = lesson.locked;

    final Color statusColor = locked
        ? AppColor.danger
        : seen
            ? AppColor.success
            : (fraction > 0 ? AppColor.warning : AppColor.inkMuted);
    final String statusText = locked
        ? 'قفل'
        : seen
            ? 'دیده شد'
            : fraction > 0
                ? 'نیمه‌تمام — ٪${(fraction * 100).round()}'
                : 'تماشا نشده';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PressableScale(
        onTap: locked ? null : onPlay,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: kLessonRowHeight - 8,
          padding: const EdgeInsets.all(8),
          decoration: ShapeDecoration(
            color: isCurrent ? AppColor.pitchGreenSoft : AppColor.card,
            shape: AppShapes.border(
              AppShapes.rMd,
              side: BorderSide(
                color: isCurrent ? AppColor.pitchGreen : AppColor.line,
                width: isCurrent ? 1.4 : 1,
              ),
            ),
            shadows: isCurrent ? null : AppColor.cardShadow,
          ),
          child: Row(
            children: [
              _thumbnail(seen: seen, fraction: fraction, locked: locked),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight:
                            isCurrent ? FontWeight.w800 : FontWeight.w600,
                        color: locked ? AppColor.inkMuted : AppColor.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          locked
                              ? Icons.lock_outline_rounded
                              : seen
                                  ? Icons.check_circle_rounded
                                  : Icons.play_circle_outline_rounded,
                          size: 12,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            statusText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!locked)
                IconButton(
                  onPressed: onToggleSeen,
                  visualDensity: VisualDensity.compact,
                  tooltip: seen ? 'علامتِ دیده‌شدن برداشته شود' : 'دیدم',
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      seen
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      key: ValueKey(seen),
                      size: 21,
                      color: seen ? AppColor.success : AppColor.lineStrong,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail({
    required bool seen,
    required double fraction,
    required bool locked,
  }) {
    return SquircleClip(
      radius: AppShapes.rSm,
      child: SizedBox(
        width: 92,
        height: 54,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(
              url: lesson.section.videoThumbnail,
              fallbackAsset: 'assets/images/course_not_found.jpg',
              fit: BoxFit.cover,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: locked ? 0.55 : 0.28),
              ),
            ),
            Center(
              child: Icon(
                locked
                    ? Icons.lock_rounded
                    : isCurrent
                        ? Icons.graphic_eq_rounded
                        : Icons.play_arrow_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
            if (fraction > 0)
              Align(
                alignment: Alignment.bottomCenter,
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 3,
                  backgroundColor: Colors.white24,
                  color: seen ? AppColor.success : AppColor.pitchGreenLight,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// دکمه‌ی آیکنیِ کوچکِ سطحِ خاکستری — برای بستنِ شیت.
class CircleIconButtonSmall extends StatelessWidget {
  const CircleIconButtonSmall({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: const ShapeDecoration(
          color: AppColor.cardMuted,
          shape: CircleBorder(),
        ),
        child: Icon(icon, size: 18, color: AppColor.ink),
      ),
    );
  }
}
