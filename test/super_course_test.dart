// سه لایه‌ی آموزش از سوپرکورس: مسیر → دوره‌ها → هفته‌ها.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:persian_ball/core/app_router.dart';
import 'package:persian_ball/core/deep_link_resolver.dart';
import 'package:persian_ball/models/course_detail_model.dart';
import 'package:persian_ball/models/super_course.dart';
import 'package:persian_ball/services/super_course_service.dart';
import 'package:persian_ball/views/screens/super_course_page.dart';

Map<String, dynamic> _sc({dynamic courses, String english = 'dribbling-path'}) => {
      'id': 7,
      'name_farsi': 'مسیر دریبلینگ',
      'name_english': english,
      'description': 'از پایه تا حرفه‌ای',
      'image': '/media/images/sc.jpg',
      'video_thumbnail': '',
      'sorting_order': 1,
      'created_at': '2026-10-22T10:00:00+03:30',
      'courses': courses ?? const [],
    };

Map<String, dynamic> _courseDetail(int id, String title) => {
      'id': id,
      'section_count': 12,
      'week_count': 3,
      'course_title': title,
      'image': '/media/images/c$id.jpg',
      'course_description': '',
      'course_difficulty': 'مبتدی',
      'course_duration': 0,
      'detail': {'pre_requirement': '', 'video_count': 12, 'length': 0, 'sections': [], 'time_and_location': []},
      'super_courses': [],
    };

void main() {
  group('مدلِ سوپرکورس', () {
    test('courses به‌صورتِ لیستِ شناسه', () {
      final sc = SuperCourse.fromJson(_sc(courses: [21, 22, 22, 0]));
      expect(sc.courses.map((c) => c.id), [21, 22]);
      expect(sc.courses.first.needsDetails, isTrue);
    });

    test('courses به‌صورتِ آبجکتِ لیستِ دوره‌ها، مرتب با sorting_order', () {
      final sc = SuperCourse.fromJson(_sc(courses: [
        {'id': 22, 'name_farsi': 'دوم', 'sorting_order': 2, 'course_price': 1000000, 'discount_percentage': 10},
        {'id': 21, 'name_farsi': 'اول', 'sorting_order': 1, 'difficulty': 'مبتدی'},
      ]));
      expect(sc.courses.map((c) => c.title), ['اول', 'دوم']);
      expect(sc.courses.last.finalPrice, 900000);
      expect(sc.courses.first.difficulty, 'مبتدی');
    });

    test('courses به‌صورتِ آبجکتِ جزئیاتِ دوره یا تودرتو', () {
      final sc = SuperCourse.fromJson(_sc(courses: [
        {'id': 30, 'course_title': 'جزئیات', 'section_count': 40, 'week_count': 4},
        {'order': 5, 'course': {'id': 31, 'name_farsi': 'تودرتو'}},
      ]));
      expect(sc.courses.first.title, 'جزئیات');
      expect(sc.courses.first.videoCount, 40);
      expect(sc.courses.last.id, 31);
      expect(sc.totalWeeks, 4);
    });

    test('courses به‌صورتِ رشته (JSON یا جداشده با ویرگول)', () {
      expect(SuperCourse.fromJson(_sc(courses: '[3, 4]')).courses.map((c) => c.id), [3, 4]);
      expect(SuperCourse.fromJson(_sc(courses: '5,6')).courses.map((c) => c.id), [5, 6]);
      expect(SuperCourse.fromJson(_sc(courses: '')).courses, isEmpty);
    });

    test('آدرس: نامِ انگلیسیِ لینک‌پذیر، وگرنه شناسه', () {
      expect(SuperCourse.fromJson(_sc()).route, '/super-course/dribbling-path');
      expect(SuperCourse.fromJson(_sc(english: 'Dribbling Path')).route, '/super-course/7');
    });

    test('super_courses در جزئیاتِ دوره: شناسه یا آبجکت', () {
      final refs = SuperCourseRef.listFrom([7, {'id': 8, 'name_farsi': 'مسیر شوت', 'name_english': 'shooting'}]);
      expect(refs.map((r) => r.route), ['/super-course/7', '/super-course/shooting']);
      expect(refs.last.name, 'مسیر شوت');
    });
  });

  group('دوره‌ی ۲۰ دیگر از روی نامِ هفته‌ها سه‌لایه نمی‌شود', () {
    test('همه‌ی ۳۰ ورودی برنامه‌ی هفتگیِ خودِ دوره‌اند', () {
      final raw = File('test/fixtures/course_20_bundle.json').readAsStringSync();
      final data = CourseDetailResponse.fromJson(jsonDecode(raw));
      expect(data.detail.weeks.length, 30);
      expect(data.superCourses, isEmpty);
    });

    test('super_courses خوانده می‌شود', () {
      final data = CourseDetailResponse.fromJson({..._courseDetail(21, 'x'), 'super_courses': [7]});
      expect(data.superCourses.single.id, 7);
    });
  });

  group('سرویس', () {
    test('دوره‌هایی که فقط شناسه دارند از endpointِ دوره کامل می‌شوند', () async {
      final asked = <String>[];
      final client = MockClient((req) async {
        asked.add(req.url.path);
        if (req.url.path.endsWith('/v2/product/super-course/dribbling-path/')) {
          return http.Response.bytes(utf8.encode(jsonEncode(_sc(courses: [21, 22]))), 200);
        }
        final m = RegExp(r'/v2/product/course/(\d+)/$').firstMatch(req.url.path);
        if (m != null && m.group(1) == '21') {
          return http.Response.bytes(utf8.encode(jsonEncode(_courseDetail(21, 'دوره اول'))), 200);
        }
        return http.Response('{}', 500); // دوره‌ی ۲۲ خراب است
      });
      final sc = await http.runWithClient(
          () => SuperCourseService.fetchDetail('dribbling-path'), () => client);
      expect(sc.title, 'مسیر دریبلینگ');
      expect(sc.courses.map((c) => c.title), ['دوره اول', '']);
      expect(sc.courses.first.weekCount, 3);
      expect(sc.courses.first.videoCount, 12);
      expect(asked, contains('/v2/product/course/22/'));
    });

    test('۴۰۴ → پیامِ «پیدا نشد»', () async {
      final client = MockClient((_) async => http.Response('{"detail":"No SuperCourse"}', 404));
      expect(
        () => http.runWithClient(() => SuperCourseService.fetchDetail('x'), () => client),
        throwsA(isA<SuperCourseNotFound>()),
      );
    });

    test('لیست بر اساسِ sorting_order مرتب می‌شود', () async {
      final client = MockClient((_) async => http.Response.bytes(
          utf8.encode(jsonEncode({
            'count': 2,
            'next': null,
            'previous': null,
            'results': [
              {..._sc(), 'id': 2, 'sorting_order': 5},
              {..._sc(), 'id': 1, 'sorting_order': 1},
            ],
          })),
          200));
      final page = await http.runWithClient(() => SuperCourseService.fetchList(), () => client);
      expect(page.results.map((s) => s.id), [1, 2]);
    });
  });

  group('آدرس‌ها', () {
    test('لینکِ عمیق', () {
      expect(DeepLinkResolver.resolvePath('/super-course/dribbling-path'), '/super-course/dribbling-path');
      expect(DeepLinkResolver.resolve(Uri.parse('persianball://super-course/7')), '/super-course/7');
      expect(DeepLinkResolver.resolvePath('/super-course/a b'), isNull);
    });

    test('روتر صفحه‌ی سوپرکورس را می‌سازد', () {
      final route = AppRouter.onGenerateRoute(const RouteSettings(name: '/super-course/7'));
      expect(route, isA<MaterialPageRoute>());
    });
  });

  testWidgets('صفحه‌ی سوپرکورس: دوره‌ها به ترتیب و ضربه به صفحه‌ی دوره', (t) async {
    final client = MockClient((req) async => http.Response.bytes(
        utf8.encode(jsonEncode(_sc(courses: [
          {'id': 21, 'name_farsi': 'دریبل پایه', 'sorting_order': 1, 'week_count': 2},
          {'id': 22, 'name_farsi': 'دریبل سرعتی', 'sorting_order': 2, 'course_price': 500000},
        ]))),
        200));
    final pushed = <String>[];
    await http.runWithClient(() async {
      await t.pumpWidget(MaterialApp(
        home: const SuperCoursePage(idOrSlug: 'dribbling-path'),
        onGenerateRoute: (s) {
          pushed.add(s.name ?? '');
          return MaterialPageRoute(builder: (_) => const Scaffold());
        },
      ));
      // تصویرِ شبکه در تست بار نمی‌شود و جانگهدارش مدام متحرک است؛
      // pumpAndSettle هیچ‌وقت آرام نمی‌گیرد.
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 200));
      }
    }, () => client);

    expect(find.text('مسیر دریبلینگ'), findsOneWidget);
    expect(find.text('2 دوره'), findsOneWidget);
    expect(find.text('دوره‌های این مسیر به ترتیب'), findsOneWidget);
    final first = t.getTopLeft(find.text('دریبل پایه'));
    final second = t.getTopLeft(find.text('دریبل سرعتی'));
    expect(first.dy, lessThan(second.dy));
    expect(find.text('500,000 تومان'), findsOneWidget);

    await t.ensureVisible(find.text('دریبل سرعتی'));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('دریبل سرعتی'));
    await t.pump(const Duration(milliseconds: 500));
    expect(pushed, ['/course/22']);
  });
}
