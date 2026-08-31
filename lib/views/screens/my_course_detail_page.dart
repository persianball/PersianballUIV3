// lib/views/screens/my_course_detail_page.dart
import 'dart:async';
import 'package:marketky/constant/app_shapes.dart';
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_breakpoints.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/course_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:marketky/views/widgets/app_buttons.dart';

class MyCourseDetailPage extends StatefulWidget {
  final MyCourse myCourse;
  const MyCourseDetailPage({super.key, required this.myCourse});

  @override
  State<MyCourseDetailPage> createState() => _MyCourseDetailPageState();
}

class _MyCourseDetailPageState extends State<MyCourseDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _listController = ScrollController();
  Map<int, Set<int>> _watchedByCourse = {}; // courseId -> set of flat indices
  int? _continueIndex;
  String? _continueLabel;
  bool _introExpanded = false;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  
  int _selectedWeekIndex = 0;
  int _selectedSectionIndex = 0;

  int get _courseKey => widget.myCourse.courseDetail.id;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _computeContinueWatching();
    _initPlayer();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _listController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    await _loadVideoFromSection(_selectedWeekIndex, _selectedSectionIndex);
  }

  Future<void> _loadVideoFromSection(int weekIndex, int sectionIndex) async {
    final weeks = widget.myCourse.courseDetail.detail.weeks;
    if (weekIndex >= weeks.length) return;
    
    final week = weeks[weekIndex];
    if (sectionIndex >= week.sections.length) return;
    
    final section = week.sections[sectionIndex];
    final url = section.videoUrl;
    
    if ((url ?? '').isEmpty) return;
    
    try {
      // Dispose previous controllers
      _chewieController?.dispose();
      _videoController?.dispose();
      
      final vc = VideoPlayerController.networkUrl(Uri.parse(url!));
      await vc.initialize();
      final cc = ChewieController(
        videoPlayerController: vc,
        autoPlay: false,
        looping: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColor.goldEnd,
          handleColor: AppColor.goldEnd,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white54,
        ),
      );
      if (!mounted) {
        vc.dispose();
        cc.dispose();
        return;
      }
      setState(() {
        _videoController = vc;
        _chewieController = cc;
        _selectedWeekIndex = weekIndex;
        _selectedSectionIndex = sectionIndex;
      });
    } catch (_) {}
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('watchedVideos_$_courseKey') ?? [];
    setState(() {
      _watchedByCourse[_courseKey] = stored.map(int.parse).toSet();
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = _watchedByCourse[_courseKey] ?? {};
    await prefs.setStringList(
      'watchedVideos_$_courseKey',
      ids.map((e) => e.toString()).toList(),
    );
  }

  void _toggleWatched(int flatIndex) {
    final set = _watchedByCourse[_courseKey] ?? <int>{};
    if (set.contains(flatIndex)) {
      set.remove(flatIndex);
    } else {
      set.add(flatIndex);
    }
    setState(() {
      _watchedByCourse[_courseKey] = set;
    });
    _saveProgress();
    _computeContinueWatching();
  }

  void _onSectionTap(int weekIndex, int sectionIndex) {
    _loadVideoFromSection(weekIndex, sectionIndex);
    _toggleWatched(_flatIndexFrom(weekIndex, sectionIndex));
  }

  void _computeContinueWatching() {
    final weeks = widget.myCourse.courseDetail.detail.weeks;
    int total = 0;
    for (final w in weeks) {
      total += w.sections.length;
    }
    if (total == 0) {
      setState(() {
        _continueIndex = null;
        _continueLabel = null;
      });
      return;
    }

    final watched = _watchedByCourse[_courseKey] ?? {};
    int? nextIndex;
    int idx = 0;
    String? label;
    for (int wi = 0; wi < weeks.length; wi++) {
      final week = weeks[wi];
      for (int si = 0; si < week.sections.length; si++, idx++) {
        if (!watched.contains(idx)) {
          nextIndex = idx;
          label = '${week.weekName ?? 'هفته ${week.weekNumber}'} - ${week.sections[si].title}';
          break;
        }
      }
      if (nextIndex != null) break;
    }
    setState(() {
      _continueIndex = nextIndex;
      _continueLabel = label;
    });
  }

  int _flatIndexFrom(int weekIdx, int sectionIdx) {
    int idx = 0;
    for (int i = 0; i < weekIdx; i++) {
      idx += widget.myCourse.courseDetail.detail.weeks[i].sections.length;
    }
    idx += sectionIdx;
    return idx;
  }


  /// معرفی دوره (آکاردئون) — از بدنه‌ی build جدا شد تا در هر دو چیدمان
  /// موبایل و دسکتاپ یکسان استفاده شود.
  Widget _introSection() {
    return Theme(
      data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          unselectedWidgetColor: AppColor.onSurfaceVariant),
      child: ExpansionTile(
        iconColor: AppColor.goldEnd,
        collapsedIconColor: AppColor.onSurfaceVariant,
        initiallyExpanded: _introExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 0),
        onExpansionChanged: (v) => setState(() => _introExpanded = v),
        title: const Text('معرفی دوره',
            style: TextStyle(
                fontFamily: 'Estedad',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColor.onSurface)),
        children: [
          const SizedBox(height: 6),
          Text(widget.myCourse.courseDescription,
              style: const TextStyle(
                  fontFamily: 'Estedad', color: AppColor.onSurfaceVariant)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ==================== چیدمانِ پخش‌کننده‌ی دوره ====================

  /// پخش‌کننده با نسبتِ ثابت ۱۶:۹.
  ///
  /// قبلاً ویدیو داخل یک SliverAppBarِ جمع‌شونده بود؛ با اسکرول کوچک و
  /// بریده می‌شد و عنوان/نوار پیشرفت هم روی کنترل‌های پخش می‌افتاد.
  Widget _player(MyCourseDetail detail) {
    final ready = _chewieController != null &&
        _videoController != null &&
        _videoController!.value.isInitialized;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: ready
            ? Chewie(controller: _chewieController!)
            : Stack(
                fit: StackFit.expand,
                children: [
                  if ((detail.videoThumbnail ?? '').isNotEmpty)
                    Image.network(detail.videoThumbnail!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: AppColor.obsidianBg))
                  else if (detail.images.isNotEmpty)
                    Image.network(detail.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: AppColor.obsidianBg))
                  else
                    Container(color: AppColor.obsidianBg),
                  const DecoratedBox(
                    decoration: BoxDecoration(color: Color(0x66000000)),
                  ),
                  const Center(
                    child: Icon(Icons.play_circle_fill_rounded,
                        size: 64, color: Colors.white70),
                  ),
                ],
              ),
      ),
    );
  }

  /// عنوان دوره، نوار پیشرفت و دکمه‌ی «ادامه تماشا»
  Widget _courseHeader(
    MyCourseDetail detail,
    double progress,
    int watchedCount,
    int totalSections,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.courseTitle,
            style: const TextStyle(
                fontFamily: 'Estedad',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColor.onSurface),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColor.cardMuted,
                    color: AppColor.pitchGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('$watchedCount از $totalSections',
                  style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColor.onSurfaceVariant)),
            ],
          ),
          if (_continueIndex != null) ...[
            const SizedBox(height: 12),
            GradientButton(
              label: _continueLabel == null
                  ? 'ادامه تماشا'
                  : 'ادامه: ${_continueLabel!}',
              icon: const Icon(Icons.play_arrow_rounded),
              height: 44,
              fontSize: 13,
              onPressed: () => _playFlatIndex(_continueIndex!),
            ),
          ],
        ],
      ),
    );
  }

  /// از ایندکسِ پیوسته، هفته و سکشن را پیدا و پخش می‌کند.
  void _playFlatIndex(int flatIndex) {
    final weeks = widget.myCourse.courseDetail.detail.weeks;
    int idx = 0;
    for (int wi = 0; wi < weeks.length; wi++) {
      for (int si = 0; si < weeks[wi].sections.length; si++, idx++) {
        if (idx == flatIndex) {
          setState(() => _selectedWeekIndex = wi);
          _onSectionTap(wi, si);
          return;
        }
      }
    }
  }

  /// یک ردیفِ درس در لیست
  Widget _lessonTile({
    required MyCourseWeekSectionItem section,
    required int weekIndex,
    required int sectionIndex,
    required bool seen,
    required bool isCurrent,
  }) {
    final thumb = (section.videoThumbnail ?? '').trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isCurrent ? AppColor.pitchGreenSoft : AppColor.surfaceContainer,
        shape: AppShapes.border(
          AppShapes.rMd,
          side: BorderSide(
            color: isCurrent ? AppColor.pitchGreen : AppColor.line,
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: section.isLocked
              ? null
              : () => _onSectionTap(weekIndex, sectionIndex),
          child: Padding(
            // ارتفاعِ ردیف بالای ۴۴ می‌ماند تا هدفِ لمس استاندارد باشد
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: AppShapes.radius(AppShapes.rSm),
                  child: SizedBox(
                    width: 76,
                    height: 46,
                    child: thumb.isEmpty
                        ? Container(
                            color: AppColor.cardMuted,
                            child: const Icon(Icons.play_circle_outline,
                                size: 22, color: AppColor.inkMuted),
                          )
                        : Image.network(
                            thumb,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColor.cardMuted,
                              child: const Icon(Icons.play_circle_outline,
                                  size: 22, color: AppColor.inkMuted),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        section.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 13,
                          fontWeight:
                              isCurrent ? FontWeight.w800 : FontWeight.w600,
                          color: section.isLocked
                              ? AppColor.inkMuted
                              : AppColor.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            section.isLocked
                                ? Icons.lock_outline_rounded
                                : (seen
                                    ? Icons.check_circle_rounded
                                    : Icons.play_circle_outline_rounded),
                            size: 13,
                            color: section.isLocked
                                ? AppColor.danger
                                : (seen
                                    ? AppColor.success
                                    : AppColor.onSurfaceVariant),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            section.isLocked
                                ? 'قفل'
                                : (seen ? 'دیده شد' : 'تماشا نشده'),
                            style: TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 11,
                              color: section.isLocked
                                  ? AppColor.danger
                                  : (seen
                                      ? AppColor.success
                                      : AppColor.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// فهرستِ کاملِ درس‌ها: همه‌ی هفته‌ها، هر هفته یک آکاردئون.
  ///
  /// قبلاً فقط سکشن‌های هفته‌ی انتخاب‌شده در یک کروسل افقی با
  /// viewportFraction 0.7 و کارتِ ۲۸۰ پیکسلیِ ثابت نمایش داده می‌شدند؛ روی
  /// نمایشگر بزرگ عملاً یک ویدیو با فاصله‌های خالیِ زیاد دیده می‌شد.
  Widget _lessonList(Set<int> watched, {required bool scrollable}) {
    final weeks = widget.myCourse.courseDetail.detail.weeks;
    return ListView.builder(
      controller: scrollable ? _listController : null,
      shrinkWrap: !scrollable,
      physics: scrollable
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: weeks.length,
      itemBuilder: (context, wi) {
        final week = weeks[wi];
        final done = week.sections
            .asMap()
            .entries
            .where((e) => watched.contains(_flatIndexFrom(wi, e.key)))
            .length;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: AppColor.card,
            shape: AppShapes.border(AppShapes.rLg,
                side: const BorderSide(color: AppColor.line)),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  unselectedWidgetColor: AppColor.onSurfaceVariant),
              child: ExpansionTile(
                initiallyExpanded: wi == _selectedWeekIndex,
                onExpansionChanged: (open) {
                  if (open) setState(() => _selectedWeekIndex = wi);
                },
                iconColor: AppColor.pitchGreen,
                collapsedIconColor: AppColor.onSurfaceVariant,
                title: Text(
                  week.weekName?.trim().isNotEmpty == true
                      ? week.weekName!.trim()
                      : 'هفته ${week.weekNumber}',
                  style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColor.onSurface),
                ),
                subtitle: Text(
                  '$done از ${week.sections.length} ویدیو',
                  style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 11,
                      color: AppColor.onSurfaceVariant),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                children: [
                  for (int si = 0; si < week.sections.length; si++)
                    _lessonTile(
                      section: week.sections[si],
                      weekIndex: wi,
                      sectionIndex: si,
                      seen: watched.contains(_flatIndexFrom(wi, si)),
                      isCurrent: _selectedWeekIndex == wi &&
                          _selectedSectionIndex == si,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.myCourse.courseDetail;
    final weeks = detail.detail.weeks;
    final watched = _watchedByCourse[_courseKey] ?? {};
    final totalSections = weeks.fold<int>(0, (a, b) => a + b.sections.length);
    final watchedCount = watched.length.clamp(0, totalSections);
    final progress = totalSections == 0 ? 0.0 : watchedCount / totalSections;
    final bool desktop = AppBreakpoints.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColor.milk,
      appBar: AppBar(
        backgroundColor: AppColor.card,
        foregroundColor: AppColor.ink,
        elevation: 0,
        title: const Text('دوره‌ی من',
            style: TextStyle(
                fontFamily: 'Estedad',
                fontWeight: FontWeight.w800,
                color: AppColor.ink)),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: desktop
              // دسکتاپ: پخش‌کننده در ستون اصلی، فهرست درس‌ها در ستون کناری
              // — الگوی استانداردِ صفحه‌ی تماشای دوره.
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ListView(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      AppShapes.radius(AppShapes.rLg),
                                  child: _player(detail),
                                ),
                                _courseHeader(detail, progress, watchedCount,
                                    totalSections),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 8, 16, 24),
                                  child: _introSection(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 380,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
                                  child: Text('فهرست درس‌ها',
                                      style: TextStyle(
                                          fontFamily: 'Estedad',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColor.ink)),
                                ),
                                Expanded(
                                    child: _lessonList(watched,
                                        scrollable: true)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              // موبایل: پخش‌کننده‌ی ثابت بالا، بعد عنوان/پیشرفت، بعد فهرست کامل
              : ListView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    _player(detail),
                    _courseHeader(
                        detail, progress, watchedCount, totalSections),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _introSection(),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text('فهرست درس‌ها',
                          style: TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColor.ink)),
                    ),
                    _lessonList(watched, scrollable: false),
                  ],
                ),
        ),
      ),
    );
  }
}
