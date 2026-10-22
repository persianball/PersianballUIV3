// lib/services/super_course_service.dart
//
// سوپرکورس‌ها (مسیرهای آموزشی). شکلِ داده و دلیلِ انعطافِ پارسر در
// lib/models/super_course.dart توضیح داده شده.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:persian_ball/constant/urls.dart';
import 'package:persian_ball/models/super_course.dart';
import 'package:persian_ball/services/course_service.dart';

class SuperCourseListPage {
  final int count;
  final String? next;
  final List<SuperCourse> results;

  const SuperCourseListPage(
      {required this.count, required this.next, required this.results});
}

class SuperCourseService {
  SuperCourseService._();

  static const String _path = 'v2/product/super-course/';

  /// سرور در `next` آدرسِ http می‌دهد؛ روی وبِ https بلاکِ mixed-content
  /// می‌خورد.
  static String _https(String url) =>
      url.startsWith('http://') ? url.replaceFirst('http://', 'https://') : url;

  // سرور charset اعلام نمی‌کند؛ بدونِ utf8.decode متنِ فارسی خراب می‌شود.
  static dynamic _decode(http.Response r) => jsonDecode(utf8.decode(r.bodyBytes));

  static Future<SuperCourseListPage> fetchList({String? nextUrl}) async {
    final url = nextUrl != null && nextUrl.isNotEmpty
        ? _https(nextUrl)
        : '${URLs.baseUrl}$_path';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('خطا در دریافت مسیرهای آموزشی (${res.statusCode})');
    }
    final data = _decode(res);
    final raw = data is Map<String, dynamic> ? data['results'] : data;
    final list = <SuperCourse>[
      for (final e in (raw is List ? raw : const []))
        if (e is Map<String, dynamic>) SuperCourse.fromJson(e),
    ]..sort((a, b) => a.sortingOrder.compareTo(b.sortingOrder));
    return SuperCourseListPage(
      count: data is Map && data['count'] is int ? data['count'] as int : list.length,
      next: data is Map ? data['next'] as String? : null,
      results: list,
    );
  }

  /// یک سوپرکورس با شناسه یا نامِ انگلیسی. دوره‌هایی که فقط شناسه‌شان آمده
  /// از /v2/product/course/<id>/ کامل می‌شوند؛ خطای یکی، بقیه را خراب نمی‌کند.
  static Future<SuperCourse> fetchDetail(String idOrSlug) async {
    final key = Uri.encodeComponent(idOrSlug.trim());
    final res = await http.get(Uri.parse('${URLs.baseUrl}$_path$key/'));
    if (res.statusCode == 404) {
      throw const SuperCourseNotFound();
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('خطا در دریافت مسیر آموزشی (${res.statusCode})');
    }
    final data = _decode(res);
    if (data is! Map<String, dynamic>) throw const SuperCourseNotFound();
    final sc = SuperCourse.fromJson(data);
    if (!sc.courses.any((c) => c.needsDetails)) return sc;

    final filled = await Future.wait(sc.courses.map((c) async {
      if (!c.needsDetails) return c;
      try {
        final d = await CourseService.fetchCourseDetail(id: c.id);
        return c.filledWith(
          title: d.courseTitle,
          image: d.image,
          difficulty: d.courseDifficulty,
          weekCount: d.weekCount,
          videoCount: d.sectionCount,
        );
      } catch (_) {
        return c;
      }
    }));
    return sc.withCourses(filled);
  }
}

class SuperCourseNotFound implements Exception {
  const SuperCourseNotFound();
  @override
  String toString() => 'این مسیر آموزشی پیدا نشد';
}
