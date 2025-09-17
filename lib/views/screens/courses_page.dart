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

class _CoursesPageState extends State<CoursesPage> {
  CoursesResponse? _data;
  bool _loading = true;
  String? _error;
  String? _nextUrl;
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetch();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
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
      appBar: AppBar(
        title: const Text('دوره‌ها', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
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
                          imageUrl: _abs("${URLs.baseUrl}${c.image}"),
                          onTap: () => Navigator.of(context).pushNamed('/course/${c.id}', arguments: c),
                        );
                      },
                    ),
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
                          ? Container(color: Colors.grey[200])
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