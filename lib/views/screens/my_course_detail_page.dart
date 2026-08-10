// lib/views/screens/my_course_detail_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
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
          playedColor: AppColor.primary,
          handleColor: AppColor.primary,
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
    // first un-watched index
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

  @override
  Widget build(BuildContext context) {
    final detail = widget.myCourse.courseDetail;
    final weeks = detail.detail.weeks;
    final watched = _watchedByCourse[_courseKey] ?? {};
    final totalSections = weeks.fold<int>(0, (a, b) => a + b.sections.length);
    final watchedCount = watched.length.clamp(0, totalSections);
    final progress = totalSections == 0 ? 0.0 : watchedCount / totalSections;

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              elevation: 0,
              pinned: true,
              expandedHeight: 450,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
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
                        Container(color: Colors.black12),
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
                                    color: AppColor.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('${((progress) * 100).round()}%', style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_continueIndex != null)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _scrollToIndex(_continueIndex!),
                              child: Text(_continueLabel ?? 'ادامه تماشا'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: _introExpanded,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 0),
                        onExpansionChanged: (v) => setState(() => _introExpanded = v),
                        title: const Text('معرفی دوره', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        children: [
                          const SizedBox(height: 6),
                          Text(widget.myCourse.courseDescription),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('ویدیوها', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    // Week dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedWeekIndex,
                          isExpanded: true,
                          items: weeks.asMap().entries.map((entry) {
                            final week = entry.value;
                            return DropdownMenuItem<int>(
                              value: entry.key,
                              child: Text(week.weekName ?? 'هفته ${week.weekNumber}'),
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
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Horizontal carousel for sections of selected week
            SliverToBoxAdapter(
              child: Container(
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
                            color: isSelected ? AppColor.primary.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColor.primary : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Video thumbnail
                              Expanded(
                                flex: 3,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    color: Colors.grey.shade200,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: section.videoThumbnail != null && section.videoThumbnail!.isNotEmpty
                                        ? Image.network(
                                            section.videoThumbnail!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: Colors.grey.shade300,
                                              child: const Icon(Icons.play_circle_fill, size: 40, color: Colors.grey),
                                            ),
                                          )
                                        : Container(
                                            color: Colors.grey.shade300,
                                            child: const Icon(Icons.play_circle_fill, size: 40, color: Colors.grey),
                                          ),
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
                                            color: seen ? AppColor.primary : Colors.grey,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              section.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
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
                                            color: Colors.redAccent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      else if (seen)
                                        const Text(
                                          'دیده شد',
                                          style: TextStyle(
                                            color: Colors.green,
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
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}


