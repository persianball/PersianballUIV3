// lib/views/screens/courses_page.dart
import 'dart:ui';
import 'package:marketky/views/widgets/app_buttons.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/urls.dart';
import 'package:marketky/models/course_models.dart';
import 'package:marketky/services/course_service.dart';
import 'package:marketky/services/auth_service.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/views/widgets/motion.dart';
import 'package:marketky/views/widgets/app_slider.dart';
import 'package:marketky/views/widgets/shimmer.dart';
import 'package:marketky/models/slider_item.dart';
import 'package:marketky/constant/app_breakpoints.dart';

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

  /// کاربر برای دیدن «دوره‌های من» باید وارد شده باشد.
  bool _needLogin = false;

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

  Widget _loginRequiredView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColor.greenGradient,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'برای دیدن دوره‌های خود وارد شوید',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Estedad',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColor.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'دوره‌های خریداری‌شده پس از ورود اینجا نمایش داده می‌شوند.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 12,
                  color: AppColor.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final ok = await Navigator.of(context).pushNamed<bool>(
                  '/login',
                  arguments: {'popOnSuccess': true},
                );
                if (!mounted) return;
                if (ok == true) _fetchUserCourses();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.goldEnd,
                foregroundColor: AppColor.onGold,
                shape: AppShapes.pill,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('ورود به حساب',
                  style: TextStyle(fontFamily: 'Estedad', fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchUserCourses() async {
    final token = await AuthService.getToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      setState(() {
        _needLogin = true;
        _userLoading = false;
        _userError = null;
      });
      return;
    }
    setState(() {
      _needLogin = false;
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

  TabBar _buildTabBar() {
    return TabBar(
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
    );
  }

  /// دسکتاپ: کارت‌های دوره در گرید ۲-۳ ستونه داخل پوسته‌ی مرکزی ۱۲۰۰ پیکسلی؛
  /// همان دیتا و همان اسکرول بی‌نهایت لیست موبایل.
  Widget _desktopCoursesGrid() {
    final double screenW = MediaQuery.of(context).size.width;
    final double gutter = AppBreakpoints.gutter(context);
    final double side = ((screenW - AppBreakpoints.contentMaxWidth) / 2)
        .clamp(gutter, double.infinity);
    final double gridW = screenW - side * 2;
    final int columns = gridW >= 980 ? 3 : 2;
    final double heroH =
        (MediaQuery.of(context).size.height * 0.5).clamp(320.0, 460.0);

    return CustomScrollView(
      controller: _controller,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(side, 20, side, 0),
          sliver: SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius: AppShapes.radius(AppShapes.rLg),
              child: AppSlider(
                page: SliderPage.academy,
                desktopHeight: heroH,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(side, 24, side, 110),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              mainAxisExtent: 364,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final c = _data!.results[i];
                return FadeSlideIn(
                  delay: Duration(milliseconds: 50 * (i % 6)),
                  child: _HoverLift(
                    child: _CourseCard(
                      course: c,
                      imageUrl: _abs(c.image),
                      inGrid: true,
                      onTap: () => Navigator.of(context)
                          .pushNamed('/course/${c.id}', arguments: c),
                    ),
                  ),
                );
              },
              childCount: _data!.results.length,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
              (AppBreakpoints.isDesktop(context) ? 8.0 : kToolbarHeight) +
                  kTextTabBarHeight),
          child: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: true,
            // دسکتاپ: عنوان «دوره‌ها» در نوار ناوبری بالای اپ هست، پس اینجا
            // تکرار نمی‌شود و فقط تب‌ها می‌مانند.
            toolbarHeight: AppBreakpoints.isDesktop(context) ? 8 : kToolbarHeight,
            title: AppBreakpoints.isDesktop(context)
                ? null
                : const Text('دوره‌ها',
                style: TextStyle(
                    fontFamily: 'Estedad',
                    fontWeight: FontWeight.w800,
                    color: AppColor.ink)),
            backgroundColor: AppColor.milk,
            foregroundColor: AppColor.ink,
            elevation: 0,
            // دسکتاپ: تب‌ها وسط‌چین با عرض محدود تا روی صفحه‌ی پهن کش نیایند
            bottom: AppBreakpoints.isDesktop(context)
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(kTextTabBarHeight),
                    child: Center(
                      child: SizedBox(width: 480, child: _buildTabBar()),
                    ),
                  )
                : _buildTabBar(),
          ),
        ),
        // جهت TabBarView باید با TabBar راست‌به‌چپ یکی باشد وگرنه جهت اسلاید
        // صفحه‌ها برعکس تب‌ها می‌شود
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: All Courses
            _loading
                ? _CoursesSkeleton(
                    isDesktop: AppBreakpoints.isDesktop(context))
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
                        child: AppBreakpoints.isDesktop(context)
                            ? _desktopCoursesGrid()
                            : ListView.builder(
                                controller: _controller,
                                padding: const EdgeInsets.only(bottom: 110),
                                itemCount: _data!.results.length + 1,
                                itemBuilder: (_, i) {
                                  if (i == 0) {
                                    return const Padding(
                                      padding: EdgeInsets.fromLTRB(0, 8, 0, 4),
                                      child: AppSlider(
                                          page: SliderPage.academy),
                                    );
                                  }
                                  final c = _data!.results[i - 1];
                                  return FadeSlideIn(
                                    delay: Duration(
                                        milliseconds: 50 * ((i - 1) % 6)),
                                    child: _CourseCard(
                                      course: c,
                                      imageUrl: _abs(c.image),
                                      onTap: () => Navigator.of(context).pushNamed('/course/${c.id}', arguments: c),
                                    ),
                                  );
                                },
                              ),
                      ),
            // Tab 2: User Courses
            _needLogin
                ? _loginRequiredView()
                : _userLoading
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

  /// دسکتاپ: کارت داخل سلول گرید است؛ بدون پدینگ بیرونی و با قیمت چسبیده
  /// به پایین کارت. در موبایل (پیش‌فرض) ظاهر قبلی دقیقاً حفظ می‌شود.
  final bool inGrid;

  const _CourseCard(
      {required this.course,
      required this.imageUrl,
      required this.onTap,
      this.inGrid = false});

  @override
  Widget build(BuildContext context) {
    final price = course.discountPercentage > 0
        ? (course.coursePrice * (1 - course.discountPercentage / 100)).toInt()
        : course.coursePrice;

    final Widget info = Column(
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
        if (inGrid) const Spacer() else const SizedBox(height: 12),
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
    );

    final Widget card = Hero(
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
                inGrid
                    ? Expanded(
                        child: Padding(
                            padding: const EdgeInsets.all(12.0), child: info))
                    : Padding(padding: const EdgeInsets.all(12.0), child: info),
              ],
            ),
          ),
        ),
      ),
    );

    if (inGrid) return card;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      color: AppColor.milk,
      // در نمایشگرهای پهن کارت تمام‌عرض نشود
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: card,
        ),
      ),
    );
  }
}

/// دسکتاپ: بالا آمدن نرم کارت هنگام هاور ماوس + نشانگر کلیک.
class _HoverLift extends StatefulWidget {
  final Widget child;
  const _HoverLift({required this.child});

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        child: widget.child,
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
    // دسکتاپ: فهرست «دوره‌های من» وسط‌چین با حداکثر عرض ~۹۰۰ پیکسل
    final bool desktop = AppBreakpoints.isDesktop(context);
    final double itemMaxWidth = desktop ? 900 : 520;

    List<Widget> children = [];
    if (_continueCourse != null && _continueVideo != null) {
      Widget continueCard = Container(
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
        );
      if (desktop) {
        continueCard = Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: itemMaxWidth),
            child: continueCard,
          ),
        );
      }
      children.add(continueCard);
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
          padding: desktop
              ? const EdgeInsets.only(top: 12, bottom: 110)
              : const EdgeInsets.only(bottom: 110),
          itemCount: widget.courses.length,
          itemBuilder: (context, i) {
            final course = widget.courses[i];
            return FadeSlideIn(
              delay: Duration(milliseconds: 50 * (i % 6)),
              child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: itemMaxWidth),
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

/// اسکلتونِ شیمرِ تبِ «همه‌ی دوره‌ها» — هم‌ساختارِ صفحه‌ی بارگذاری‌شده.
class _CoursesSkeleton extends StatelessWidget {
  const _CoursesSkeleton({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      final double screenW = MediaQuery.of(context).size.width;
      final double gutter = AppBreakpoints.gutter(context);
      final double side = ((screenW - AppBreakpoints.contentMaxWidth) / 2)
          .clamp(gutter, double.infinity);
      final double gridW = screenW - side * 2;
      final int columns = gridW >= 980 ? 3 : 2;
      final double heroH =
          (MediaQuery.of(context).size.height * 0.5).clamp(320.0, 460.0);

      return Shimmer(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(side, 20, side, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Bone(height: heroH, radius: 16),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.86,
                children: List.generate(6, (_) => const _CourseCardBone()),
              ),
            ],
          ),
        ),
      );
    }

    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(32, 12, 32, 8),
            child: Bone(height: 200, radius: 24),
          ),
          _CourseCardBone(),
          _CourseCardBone(),
          _CourseCardBone(),
        ],
      ),
    );
  }
}

/// اسکلتونِ یک کارتِ دوره، هم‌ساختارِ _CourseCard.
class _CourseCardBone extends StatelessWidget {
  const _CourseCardBone();

  @override
  Widget build(BuildContext context) {
    final Widget card = Container(
      decoration: BoxDecoration(
        color: AppColor.card,
        borderRadius: AppShapes.radius(AppShapes.rLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Bone(height: 180, radius: 0),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone(width: double.infinity, height: 16),
                SizedBox(height: 8),
                Bone(width: 160, height: 16),
                SizedBox(height: 14),
                Row(
                  children: [
                    Bone(width: 64, height: 22, radius: 11),
                    SizedBox(width: 6),
                    Bone(width: 54, height: 22, radius: 11),
                  ],
                ),
                SizedBox(height: 14),
                Row(
                  children: [
                    Bone(width: 120, height: 15),
                    Spacer(),
                    Bone(width: 22, height: 22, radius: 6),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: card,
        ),
      ),
    );
  }
}
