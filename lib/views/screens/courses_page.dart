// lib/views/screens/courses_page.dart
import 'dart:ui';
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
    return Scaffold(
      // چیدمان اپ‌بار راست‌به‌چپ: عنوان و تب‌ها از سمت راست شروع می‌شوند
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + kTextTabBarHeight),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: AppBar(
            title: const Text('دوره‌ها', style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'همه دوره‌ها'),
                Tab(text: 'دوره‌های من'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: All Courses
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : Directionality(
                      textDirection: TextDirection.rtl,
                      child: RefreshIndicator(
                        color: AppColor.primary,
                        onRefresh: () async {
                          _nextUrl = null;
                          await _fetch();
                        },
                        child: ListView.builder(
                          controller: _controller,
                          padding: const EdgeInsets.only(bottom: 32),
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
                    ),
          // Tab 2: User Courses
          _userLoading
              ? const Center(child: CircularProgressIndicator())
              : _userError != null
                  ? Center(child: Text(_userError!))
                  : Directionality(
                      textDirection: TextDirection.rtl,
                      child: _UserCoursesList(
                        courses: _userCourses?.results ?? [],
                        abs: _abs,
                        onTapCourse: (course,{scrollToVideo}) => Navigator.of(context).pushNamed('/user-course-detail', arguments: course),
                      ),
                    ),
        ],
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

    return Stack(
      children: [
        // Blurred background based on course image
        // if (imageUrl.isNotEmpty)
        //   Positioned.fill(
        //     child: Image.network(imageUrl, fit: BoxFit.cover),
        //   ),
        // Positioned.fill(
        //   child: BackdropFilter(
        //     filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        //     child: Container(color: Colors.white.withOpacity(0.75)),
        //   ),
        // ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          decoration: BoxDecoration(
            image: DecorationImage(
          image: AssetImage("assets/images/background.jpg"), fit: BoxFit.cover,
          )),
          child: Hero(
            tag: 'course_${course.id}',
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top image
                    AspectRatio(
                      aspectRatio: 16 / 9,
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
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.category, size: 16, color: Colors.grey.shade700),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(course.category.nameFarsi, style: TextStyle(color: Colors.grey.shade800)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.bolt, size: 16, color: AppColor.primary),
                              const SizedBox(width: 6),
                              Text(course.difficulty, style: TextStyle(color: Colors.grey.shade800)),
                              const Spacer(),
                              Text(
                                '${thousandSeparator(price)} تومان',
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
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


      ],
    );
  }
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
        Card(
          color: Colors.deepPurple[50],
          margin: EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: ListTile(
            leading: Icon(Icons.play_circle_fill, color: Colors.deepPurple, size: 40),
            title: Text('ادامه تماشا', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_continueCourseTitle ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_continueVideoWeekTitle ?? ''),
                Text(_continueVideoTitle ?? '', style: TextStyle(fontSize: 13)),
              ],
            ),
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => widget.onTapCourse(_continueCourse!, scrollToVideo: _continueVideo),
              icon: Icon(Icons.play_arrow),
              label: Text('ادامه'),
            ),
          ),
        ),
      );
    }
    if (widget.courses.isEmpty) {
      children.add(Center(child: Text('درسی خریداری نکرده‌اید')));
    } else {
      children.add(
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          itemCount: widget.courses.length,
          itemBuilder: (context, i) {
            final course = widget.courses[i];
            return Card(
              margin: EdgeInsets.fromLTRB(16, 12, 16, 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _CourseThumbnail(url: widget.abs(course.courseThumbnail)),
                ),
                title: Text(course.courseDetail.courseTitle, style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('پیشرفت: به زودی', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () => widget.onTapCourse(course),
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
          color: Colors.grey.shade200,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}
