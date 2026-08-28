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
import 'package:carousel_slider/carousel_slider.dart';

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

  void _scrollToIndex(int flatIndex) {
    // Each tile approx 92-100 height; use 94 as heuristic
    final double pos = flatIndex * 94.0;
    _listController.animateTo(
      pos,
      duration: const Duration(milliseconds: 400),
      curve: Curves.ease,
    );
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

  /// انتخاب هفته‌ی دوره
  Widget _weekDropdown(List<dynamic> weeks) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: ShapeDecoration(
        color: AppColor.surfaceContainer,
        shape: AppShapes.border(AppShapes.rLg),
        shadows: AppColor.cardShadow,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedWeekIndex,
          isExpanded: true,
          dropdownColor: AppColor.surfaceContainer,
          // آیتم‌های منو راست‌به‌چپ چیده شوند
          alignment: AlignmentDirectional.centerEnd,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColor.onSurfaceVariant),
          items: weeks.asMap().entries.map((entry) {
            final week = entry.value;
            return DropdownMenuItem<int>(
              value: entry.key,
              alignment: AlignmentDirectional.centerEnd,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    week.weekName ?? 'هفته ${week.weekNumber}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontFamily: 'Estedad', color: AppColor.onSurface),
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedWeekIndex = value;
                _selectedSectionIndex = 0;
              });
            }
          },
        ),
      ),
    );
  }

  /// دسکتاپ: محتوای زیر هیرو در ستون مرکزی ۱۰۰۰ پیکسلی می‌نشیند تا روی
  /// نمایشگر پهن کش نیاید؛ موبایل دقیقاً همان تمام‌عرض قبلی می‌ماند.
  Widget _centered(Widget child) => AppBreakpoints.isDesktop(context)
      ? Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: child,
          ),
        )
      : child;

  @override
  Widget build(BuildContext context) {
    final detail = widget.myCourse.courseDetail;
    final weeks = detail.detail.weeks;
    final watched = _watchedByCourse[_courseKey] ?? {};
    final totalSections = weeks.fold<int>(0, (a, b) => a + b.sections.length);
    final watchedCount = watched.length.clamp(0, totalSections);
    final progress = totalSections == 0 ? 0.0 : watchedCount / totalSections;

    return Scaffold(
      backgroundColor: AppColor.obsidianBg,
      // top: false تا SliverAppBar تمام‌عرض بالای صفحه بماند و فقط پایین
      // صفحه از نوار ناوبری سیستم فاصله بگیرد
      body: SafeArea(
        top: false,
        child: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              elevation: 0,
              pinned: true,
              expandedHeight: 450,
              backgroundColor: AppColor.obsidianBg,
              foregroundColor: AppColor.onSurface,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [

                    // Gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black.withOpacity(0.45)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    if (_chewieController != null && _videoController!.value.isInitialized)
                      Center(
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio == 0
                              ? 16 / 9
                              : _videoController!.value.aspectRatio,
                          child: Chewie(controller: _chewieController!),
                        ),
                      )
                    else ...[
                      if (detail.videoThumbnail != null && detail.videoThumbnail!.isNotEmpty)
                        Image.network(detail.videoThumbnail!, fit: BoxFit.cover)
                      else if (detail.images.isNotEmpty)
                        Image.network(detail.images.first, fit: BoxFit.cover)
                      else
                        Container(color: AppColor.surfaceContainer),
                    ],

                    // Title and quick actions
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.courseTitle,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor: Colors.white24,
                                    color: AppColor.goldEnd,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('${((progress) * 100).round()}%',
                                  style: const TextStyle(fontFamily: 'Estedad', color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_continueIndex != null)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.goldEnd,
                                foregroundColor: AppColor.onGold,
                                shape: AppShapes.pill,
                              ),
                              onPressed: () => _scrollToIndex(_continueIndex!),
                              child: Text(_continueLabel ?? 'ادامه تماشا',
                                  style: const TextStyle(fontFamily: 'Estedad')),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: _centered(Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _introSection(),
                    const SizedBox(height: 16),
                    const Text('ویدیوها',
                        style: TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColor.onSurface)),
                    const SizedBox(height: 12),
                    // Week dropdown
                    _weekDropdown(weeks),
                    const SizedBox(height: 16),
                  ],
                ),
              )),
            ),

            // Horizontal carousel for sections of selected week
            SliverToBoxAdapter(
              child: _centered(Container(
                height: 200,
                child: CarouselSlider.builder(
                  itemCount: weeks[_selectedWeekIndex].sections.length,
                  itemBuilder: (context, sectionIdx, realIndex) {
                    final section = weeks[_selectedWeekIndex].sections[sectionIdx];
                    final flatIndex = _flatIndexFrom(_selectedWeekIndex, sectionIdx);
                    final seen = watched.contains(flatIndex);
                    final isSelected = _selectedWeekIndex == _selectedWeekIndex && _selectedSectionIndex == sectionIdx;
                    
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: InkWell(
                        onTap: () => _onSectionTap(_selectedWeekIndex, sectionIdx),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColor.goldEnd.withOpacity(0.1)
                                : AppColor.surfaceContainer,
                            border: Border.all(
                              color: isSelected ? AppColor.goldEnd : AppColor.outlineVariantDark,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Video thumbnail
                              Expanded(
                                flex: 3,
                                child: Container(
                                  width: double.infinity,
                                  color: AppColor.obsidianBg,
                                  child: section.videoThumbnail != null && section.videoThumbnail!.isNotEmpty
                                      ? Image.network(
                                          section.videoThumbnail!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: AppColor.obsidianBg,
                                            child: const Icon(Icons.play_circle_fill,
                                                size: 40, color: AppColor.onSurfaceVariant),
                                          ),
                                        )
                                      : Container(
                                          color: AppColor.obsidianBg,
                                          child: const Icon(Icons.play_circle_fill,
                                              size: 40, color: AppColor.onSurfaceVariant),
                                        ),
                                ),
                              ),
                              // Section info
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            seen ? Icons.check_circle : Icons.play_circle_fill,
                                            color: seen ? AppColor.goldEnd : AppColor.onSurfaceVariant,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              section.title,
                                              style: const TextStyle(
                                                fontFamily: 'Estedad',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: AppColor.onSurface,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      if (section.isLocked)
                                        const Text(
                                          'قفل',
                                          style: TextStyle(
                                            fontFamily: 'Estedad',
                                            color: Colors.redAccent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      else if (seen)
                                        const Text(
                                          'دیده شد',
                                          style: TextStyle(
                                            fontFamily: 'Estedad',
                                            color: AppColor.successDark,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  options: CarouselOptions(
                    height: 200,
                    viewportFraction: 0.7,
                    enableInfiniteScroll: false,
                    enlargeCenterPage: true,
                    enlargeFactor: 0.1,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _selectedSectionIndex = index;
                      });
                    },
                  ),
                ),
              )),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
        ),
      ),
    );
  }
}


