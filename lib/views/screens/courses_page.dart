// lib/views/screens/courses_page.dart
import 'dart:ui';
import 'package:marketky/views/widgets/app_buttons.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/urls.dart';
import 'package:marketky/models/course_models.dart';
import 'package:marketky/services/course_service.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});
  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> with TickerProviderStateMixin {
  CoursesResponse? _data;
  bool _loading = true;
  String? _error;
  String? _nextUrl;
  final ScrollController _controller = ScrollController();

  MyCoursesResponse? _userCourses;
  bool _userLoading = false;
  String? _userError;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetch();
    _fetchUserCourses();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool loadMore = false}) async {
    setState(() {
      if (!loadMore) _loading = true;
      _error = null;
    });
    try {
      final res = await CourseService.fetchCourses(nextPageUrl: loadMore ? _nextUrl : null);
      setState(() {
        if (loadMore && _data != null) {
          _data = CoursesResponse(
            count: res.count,
            next: res.next,
            previous: res.previous,
            results: [..._data!.results, ...res.results],
          );
        } else {
          _data = res;
        }
        _nextUrl = res.next;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fetchUserCourses() async {
    setState(() {
      _userLoading = true;
      _userError = null;
    });
    try {
      final res = await CourseService.fetchUserCourses(context);
      setState(() {
        _userCourses = res;
        _userLoading = false;
      });
    } catch (e) {
      setState(() {
        _userError = e.toString();
        _userLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_nextUrl == null) return;
    if (_controller.position.pixels >= _controller.position.maxScrollExtent - 200) {
      final next = _nextUrl;
      _nextUrl = null;
      if (next != null) _fetch(loadMore: true);
    }
  }

  String _abs(String rel) {
    if (rel.isEmpty) return '';
    if (rel.startsWith('http')) return rel;
    return '${URLs.baseUrl}$rel';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.milk,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight + kTextTabBarHeight),
          child: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: const Text('دوره‌ها',
                style: TextStyle(
                    fontFamily: 'Estedad',
                    fontWeight: FontWeight.w800,
                    color: AppColor.ink)),
            backgroundColor: AppColor.milk,
            foregroundColor: AppColor.ink,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColor.goldEnd,
              labelColor: AppColor.goldEnd,
              unselectedLabelColor: AppColor.onSurfaceVariant,
              labelStyle: const TextStyle(fontFamily: 'Estedad'),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Estedad'),
              tabs: [
                Tab(text: 'همه دوره‌ها'),
                Tab(text: 'دوره‌های من'),
              ],
            ),
          ),
        ),
        // جهت TabBarView باید با TabBar راست‌به‌چپ یکی باشد وگرنه جهت اسلاید
        // صفحه‌ها برعکس تب‌ها می‌شود
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: All Courses
            _loading
                ? const Center(child: CircularProgressIndicator(color: AppColor.goldEnd))
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: const TextStyle(
                                fontFamily: 'Estedad', color: AppColor.onSurfaceVariant)))
                    : RefreshIndicator(
                        color: AppColor.goldEnd,
                        onRefresh: () async {
                          _nextUrl = null;
                          await _fetch();
                        },
                        child: ListView.builder(
                          controller: _controller,
                          padding: const EdgeInsets.only(bottom: 110),
                          itemCount: _data!.results.length,
                          itemBuilder: (_, i) {
                            final c = _data!.results[i];
                            return _CourseCard(
                              course: c,
                              imageUrl: _abs(c.image),
                              onTap: () => Navigator.of(context).pushNamed('/course/${c.id}', arguments: c),
                            );
                          },
                        ),
                      ),
            // Tab 2: User Courses
            _userLoading
                ? const Center(child: CircularProgressIndicator(color: AppColor.goldEnd))
                : _userError != null
                    ? Center(
                        child: Text(_userError!,
                            style: const TextStyle(
                                fontFamily: 'Estedad', color: AppColor.onSurfaceVariant)))
                    : _UserCoursesList(
                        courses: _userCourses?.results ?? [],
                        abs: _abs,
                        onTapCourse: (course,{scrollToVideo}) => Navigator.of(context).pushNamed('/user-course-detail', arguments: course),
                      ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final String imageUrl;
  final VoidCallback onTap;
  const _CourseCard({required this.course, required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final price = course.discountPercentage > 0
        ? (course.coursePrice * (1 - course.discountPercentage / 100)).toInt()
        : course.coursePrice;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      color: AppColor.milk,
      // در نمایشگرهای پهن کارت تمام‌عرض نشود
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Hero(
            tag: 'course_${course.id}',
            child: Container(
              decoration: ShapeDecoration(
                color: AppColor.card,
                shape: AppShapes.border(AppShapes.rLg),
                shadows: AppColor.cardShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top image: ارتفاع محدود تا کارت روی صفحه بزرگ غول‌پیکر نشود
                      SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: imageUrl.isEmpty
                            ? Image.asset('assets/images/course_not_found.jpg',
                                fit: BoxFit.cover)
                            : Image.network(imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset('assets/images/course_not_found.jpg',fit: BoxFit.cover,),),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.nameFarsi,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: 'Estedad',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColor.ink),
                            ),
                            const SizedBox(height: 10),
                            // بج‌های رنگی زیر تصویر: دسته‌بندی، سطح و تخفیف
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                PillTag(
                                  label: course.category.nameFarsi,
                                  icon: Icons.local_library_rounded,
                                  color: AppColor.categoryBadge,
                                  dense: true,
                                ),
                                PillTag(
                                  label: course.difficulty,
                                  icon: _difficultyIcon(course.difficulty),
                                  color: _difficultyColor(course.difficulty),
                                  dense: true,
                                ),
                                if (course.discountPercentage > 0)
                                  PillTag(
                                    label: '٪${course.discountPercentage} تخفیف',
                                    icon: Icons.local_offer_rounded,
                                    color: Colors.white,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFEF4444), AppColor.danger],
                                    ),
                                    dense: true,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  '${thousandSeparator(price)} تومان',
                                  style: const TextStyle(
                                      fontFamily: 'Estedad',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColor.ink),
                                ),
                                const Spacer(),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColor.lineStrong),
                              ],
                            ),
                          ],
                        ),
                      )
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

/// آیکن و رنگ بج «سطح دوره» بر اساس متن سطح (داده‌ی واقعی بک‌اند)
IconData _difficultyIcon(String difficulty) {
  final d = difficulty.trim();
  if (d.contains('مقدماتی') || d.contains('مبتدی')) {
    return Icons.trending_up_rounded;
  }
  if (d.contains('پیشرفته') || d.contains('حرفه')) {
    return Icons.military_tech_rounded;
  }
  if (d.contains('تخصصی')) return Icons.workspace_premium_rounded;
  if (d.contains('متوسط')) return Icons.speed_rounded;
  return Icons.bolt_rounded;
}

Color _difficultyColor(String difficulty) {
  final d = difficulty.trim();
  if (d.contains('مقدماتی') || d.contains('مبتدی')) return AppColor.success;
  if (d.contains('پیشرفته') || d.contains('حرفه')) return AppColor.danger;
  if (d.contains('تخصصی')) return AppColor.levelExpert;
  if (d.contains('متوسط')) return AppColor.warning;
  return AppColor.pitchGreen;
}

class _UserCoursesList extends StatefulWidget {
  final List<MyCourse> courses;
  final String Function(String) abs;
  final void Function(MyCourse, {int? scrollToVideo}) onTapCourse;
  const _UserCoursesList({required this.courses, required this.abs, required this.onTapCourse});

  @override
  State<_UserCoursesList> createState() => _UserCoursesListState();
}

class _UserCoursesListState extends State<_UserCoursesList> {
  Map<int, Set<int>> watchedVideos = {};

  MyCourse? _continueCourse;
  int? _continueVideo;
  String? _continueCourseTitle;
  String? _continueVideoTitle;
  String? _continueVideoWeekTitle;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    // TODO: persist video progress with shared_preferences or other storage for each course
    // ...load watched videos into watchedVideos...
    // After loading watchedVideos:
    _findContinueWatching();
  }

  void _findContinueWatching() {
    _continueCourse = null;
    _continueVideo = null;

    // for (final course in widget.courses) {
    //   final totalVideos = course.sectionCount;
    //   final watched = watchedVideos[course.id]?.length ?? 0;
    //   if (watched < totalVideos) {
    //     // This course is not finished, find first unwatched video index
    //     int idx = 0;
    //     outer:
    //     for (final week in course.courseDetail['detail']['sections'] ?? []) {
    //       for (final video in week['sections'] ?? []) {
    //         if (!(watchedVideos[course.id]?.contains(idx) ?? false)) {
    //           _continueCourse = course;
    //           _continueVideo = idx;
    //           _continueCourseTitle = course.courseTitle ?? course.nameFarsi;
    //           _continueVideoTitle = video['title'] ?? '';
    //           _continueVideoWeekTitle = week['week_name'] ?? "هفته ${week['week_number']}";
    //           break outer;
    //         }
    //         idx++;
    //       }
    //     }
    //     if (_continueCourse != null) break;
    //   }
    // }
    // setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    if (_continueCourse != null && _continueVideo != null) {
      children.add(
        Container(
          decoration: ShapeDecoration(
            color: AppColor.pitchGreenSoft,
            shape: AppShapes.border(AppShapes.rLg),
            shadows: AppColor.cardShadow,
          ),
          margin: EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: ListTile(
            leading: Icon(Icons.play_circle_fill, color: AppColor.goldEnd, size: 40),
            title: Text('ادامه تماشا',
                style: TextStyle(
                    fontFamily: 'Estedad', fontWeight: FontWeight.bold, color: AppColor.goldEnd)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_continueCourseTitle ?? '',
                    style: TextStyle(
                        fontFamily: 'Estedad',
                        fontWeight: FontWeight.bold,
                        color: AppColor.onSurface)),
                Text(_continueVideoWeekTitle ?? '',
                    style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurfaceVariant)),
                Text(_continueVideoTitle ?? '',
                    style: TextStyle(
                        fontFamily: 'Estedad', fontSize: 13, color: AppColor.onSurfaceVariant)),
              ],
            ),
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: AppColor.goldEnd,
                shape: AppShapes.pill,
              ),
              onPressed: () => widget.onTapCourse(_continueCourse!, scrollToVideo: _continueVideo),
              icon: Icon(Icons.play_arrow, color: AppColor.onGold),
              label: Text('ادامه',
                  style: TextStyle(fontFamily: 'Estedad', color: AppColor.onGold)),
            ),
          ),
        ),
      );
    }
    if (widget.courses.isEmpty) {
      children.add(Center(
          child: Text('درسی خریداری نکرده‌اید',
              style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurfaceVariant))));
    } else {
      children.add(
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 110),
          itemCount: widget.courses.length,
          itemBuilder: (context, i) {
            final course = widget.courses[i];
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  margin: EdgeInsets.fromLTRB(16, 12, 16, 6),
                  decoration: ShapeDecoration(
                    color: AppColor.card,
                    shape: AppShapes.border(AppShapes.rLg),
                    shadows: AppColor.cardShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: _CourseThumbnail(url: widget.abs(course.courseThumbnail)),
                    title: Text(course.courseDetail.courseTitle,
                        style: TextStyle(
                            fontFamily: 'Estedad',
                            fontWeight: FontWeight.w800,
                            color: AppColor.onSurface)),
                    subtitle: Text('پیشرفت: به زودی',
                        style: TextStyle(
                            fontFamily: 'Estedad', color: AppColor.onSurfaceVariant, fontSize: 12)),
                    trailing: Icon(Icons.arrow_back_ios_new_rounded, color: AppColor.onSurfaceVariant, size: 16),
                    onTap: () => widget.onTapCourse(course),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return SingleChildScrollView(child: Column(children: children));
  }
}
/// تصویر دوره با نمایش عکس پیش‌فرض در صورت نبود آدرس یا خطای لود
class _CourseThumbnail extends StatelessWidget {
  final String url;
  final double size;

  const _CourseThumbnail({required this.url, this.size = 60});

  Widget _fallback() => Image.asset(
        'assets/images/course_not_found.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
      );

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _fallback();
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: size,
          height: size,
          color: AppColor.obsidianBg,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColor.goldEnd),
            ),
          ),
        );
      },
    );
  }
}
