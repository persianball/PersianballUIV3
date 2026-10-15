// دوره‌ی مجموعه‌ای: دوره‌ای که از چند دوره‌ی دیگر تشکیل شده و هر کدام برنامه‌ی
// هفتگیِ خودش را دارد. قراردادِ پیشنهادی: detail.sub_courses (بازگشتی).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketky/models/course_detail_model.dart';
import 'package:marketky/views/widgets/locked_lessons_veil.dart';

Map<String, dynamic> _week(String n, List<bool> locks, {String? name}) => {
      'week_number': n,
      'week_name': name,
      'sections': [
        for (int i = 0; i < locks.length; i++)
          {'title': 'جلسه $n-$i', 'is_locked': locks[i]},
      ],
    };

Map<String, dynamic> _sub(int id, int order, List<Map<String, dynamic>> weeks,
        {List<Map<String, dynamic>> subs = const []}) =>
    {
      'id': id,
      'order': order,
      'course_title': 'دوره $id',
      'course_difficulty': 'مبتدی',
      'sections': weeks,
      'sub_courses': subs,
    };

CourseDetailInner _inner(Map<String, dynamic> extra) => CourseDetailInner.fromJson({
      'pre_requirement': '',
      'video_count': 0,
      'length': 0,
      'sections': const [],
      'time_and_location': const [],
      ...extra,
    });

void main() {
  group('مدل', () {
    test('دوره‌ی بدونِ sub_courses همان دوره‌ی معمولی است', () {
      final d = _inner({});
      expect(d.isBundle, isFalse);
      expect(d.subCourses, isEmpty);
    });

    test('زیرمجموعه‌ها به ترتیبِ order می‌آیند، نه ترتیبِ پاسخ', () {
      final d = _inner({
        'sub_courses': [
          _sub(3, 2, [_week('1', [true])]),
          _sub(7, 1, [_week('1', [true])]),
        ],
      });
      expect(d.isBundle, isTrue);
      expect(d.subCourses.map((c) => c.id), [7, 3]);
    });

    test('هر زیرمجموعه برنامه‌ی هفتگیِ خودش را دارد و هفته‌ها گروه می‌شوند', () {
      final c = SubCourse.fromJson(_sub(1, 1, [
        _week('1', [false, true], name: 'گرم کردن'),
        _week('1', [true], name: 'تمرین'),
        _week('2', [true, true]),
      ]));
      expect(c.weekGroups.length, 2);
      expect(c.weekGroups.first.groups.length, 2);
      expect(c.totalVideos, 5);
      expect(c.totalWeeks, 2);
      expect(c.isFullyLocked, isFalse); // یک جلسه‌ی رایگان دارد
    });

    test('جمعِ مجموعه از همه‌ی سطوح شمرده می‌شود', () {
      final d = _inner({
        'sub_courses': [
          _sub(1, 1, [_week('1', [true, true])]),
          _sub(2, 2, [_week('1', [true])], subs: [
            _sub(9, 1, [_week('1', [true, true, true]), _week('2', [true])]),
          ]),
        ],
      });
      expect(d.bundleVideoCount, 2 + 1 + 4);
      expect(d.bundleWeekCount, 1 + 1 + 2);
      expect(d.subCourses[1].subCourses.single.id, 9);
    });

    test('isFullyLocked فقط وقتی همه‌چیز (حتی زیرسطح‌ها) قفل است', () {
      final allLocked = SubCourse.fromJson(_sub(1, 1, [_week('1', [true, true])],
          subs: [_sub(2, 1, [_week('1', [true])])]));
      expect(allLocked.isFullyLocked, isTrue);

      final nestedOpen = SubCourse.fromJson(_sub(1, 1, [_week('1', [true])],
          subs: [_sub(2, 1, [_week('1', [false])])]));
      expect(nestedOpen.isFullyLocked, isFalse);
    });

    test('اگر برنامه نیامده باشد، عددِ اعلام‌شده‌ی بک‌اند استفاده می‌شود', () {
      final c = SubCourse.fromJson({'id': 4, 'week_count': 6, 'video_count': 24});
      expect(c.totalWeeks, 6);
      expect(c.totalVideos, 24);
      expect(c.isFullyLocked, isFalse);
    });
  });

  group('پرده‌ی ویدیوهای قفل', () {
    Widget host(Widget child) => MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        );

    testWidgets('تعداد را نشان می‌دهد و ضربه به خرید می‌رود', (t) async {
      var unlocks = 0;
      await t.pumpWidget(host(LockedLessonsVeil(
        count: 8,
        onUnlock: () => unlocks++,
        child: const SizedBox(height: 120),
      )));
      expect(find.text('۸ ویدیو قفل است'), findsOneWidget);
      await t.ensureVisible(find.text('تهیه‌ی دوره'));
      await t.pump();
      await t.tap(find.text('تهیه‌ی دوره'));
      expect(unlocks, 1);
    });

    testWidgets('ردیف‌های زیرِ پرده ضربه نمی‌گیرند', (t) async {
      var lessonTaps = 0, unlocks = 0;
      await t.pumpWidget(host(LockedLessonsVeil(
        count: 1,
        onUnlock: () => unlocks++,
        child: SizedBox(
          height: 220,
          child: Align(
            alignment: Alignment.topCenter,
            child: TextButton(
                onPressed: () => lessonTaps++, child: const Text('جلسه')),
          ),
        ),
      )));
      await t.tap(find.text('جلسه'), warnIfMissed: false);
      expect(lessonTaps, 0, reason: 'عنوانِ تار نباید قابلِ کلیک باشد');
      expect(unlocks, 1, reason: 'هر جای پرده مسیرِ خرید را باز می‌کند');
    });

    testWidgets('گوشیِ باریک با متنِ بزرگ: کارت بریده نمی‌شود', (t) async {
      t.view.physicalSize = const Size(320 * 3, 640 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      var unlocks = 0;
      await t.pumpWidget(MediaQuery(
        data: const MediaQueryData(
            size: Size(320, 640), textScaler: TextScaler.linear(1.4)),
        child: host(LockedLessonsVeil(
          count: 1,
          onUnlock: () => unlocks++,
          child: const SizedBox(height: 56), // یک ردیفِ تنها
        )),
      ));
      final veil = t.getRect(find.byType(LockedLessonsVeil));
      final button = t.getRect(find.text('تهیه‌ی دوره'));
      expect(veil.top <= button.top && button.bottom <= veil.bottom, isTrue,
          reason: 'دکمه باید کاملاً داخلِ کادر باشد، نه بریده');
      await t.ensureVisible(find.text('تهیه‌ی دوره'));
      await t.pump();
      await t.tap(find.text('تهیه‌ی دوره'));
      expect(unlocks, 1);
    });

    testWidgets('بدونِ امکانِ خرید، دکمه نشان داده نمی‌شود', (t) async {
      await t.pumpWidget(host(const LockedLessonsVeil(
        count: 3,
        child: SizedBox(height: 120),
      )));
      expect(find.text('تهیه‌ی دوره'), findsNothing);
      expect(find.text('۳ ویدیو قفل است'), findsOneWidget);
    });
  });
}
