import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/models/course_detail_model.dart';

CourseWeek _w(String n, String? name, [int videos = 1]) => CourseWeek(
      weekNumber: n,
      weekName: name,
      sections: [
        for (int i = 0; i < videos; i++)
          CourseWeekSectionItem(title: 'v$i', isLocked: true),
      ],
    );

void main() {
  group('دوره‌ی ۲۰ (پاسخِ واقعیِ بک‌اند)', () {
    late CourseDetailResponse data;
    setUpAll(() {
      final raw = File('test/fixtures/course_20_bundle.json').readAsStringSync();
      data = CourseDetailResponse.fromJson(jsonDecode(raw));
    });

    test('۳۰ ورودی → ۱۲ زیردوره، هفته‌ها فقط داخلِ زیردوره‌ها', () {
      final d = data.detail;
      expect(d.isBundle, isTrue);
      expect(d.subCourses.length, 12);
      expect(d.weeks, isEmpty);
      expect(d.bundleVideoCount, 339);
      expect(d.bundleWeekCount, 30);
    });

    test('عنوان‌ها بدونِ شماره و بدونِ «هفته…»', () {
      final t = data.detail.subCourses.map((c) => c.title).toList();
      expect(t.first, 'دوره دریبلینگ ساکن وی');
      expect(t[1], 'دوره دریبلینگ سرعت – پا عوض کردن');
      expect(t[2], 'دوره سرعت پا دریبل ریز های لب خط');
      expect(t[3], 'دوره هنر سر توپ');
      expect(t[8], 'هنر شوت زدن');
      expect(t.last, 'دوره فریستایل فوتبال');
    });

    test('هفته‌ها به ترتیب شماره می‌خورند؛ برچسبِ تکراریِ بک‌اند مهم نیست', () {
      final head = data.detail.subCourses[3]; // هنر سر توپ: ۶ هفته
      expect(head.weekGroups.map((w) => w.title),
          ['هفته 1', 'هفته 2', 'هفته 3', 'هفته 4', 'هفته 5', 'هفته 6']);
      // کلیدِ پیشرفت همان شماره‌ی بک‌اند می‌ماند
      expect(head.weekGroups[1].weekNumber, '10');
    });

    test('بخش‌های بی‌نامِ هفته نامِ خودشان را دارند', () {
      final free = data.detail.subCourses.last;
      expect(free.weekGroups.map((w) => w.title).toList(),
          ['Upper', 'Sit moves', 'Lower', 'Transition', 'Blocking', 'Set']);
      final shot = data.detail.subCourses[8];
      expect(shot.weekGroups.first.title, 'قواعد و راز تمرین شوت');
    });

    test('ویدیوی رایگانِ هفته‌ی اول باز می‌ماند', () {
      final first = data.detail.subCourses.first.weeks.first.sections.first;
      expect(first.isLocked, isFalse);
      expect(first.videoUrl, contains('master.m3u8'));
    });
  });

  group('دوره‌های معمولی دست نمی‌خورند', () {
    test('هفته اول/دوم/سوم بدونِ نامِ زیردوره', () {
      expect(
          SubCourse.deriveFromWeekNames([
            _w('1', 'هفته اول'),
            _w('2', 'هفته دوم'),
            _w('3', 'هفته سوم'),
          ]),
          isNull);
    });

    test('همه از یک زیردوره → دوره‌ی ساده', () {
      expect(
          SubCourse.deriveFromWeekNames([
            _w('1', 'دوره X - هفته اول'),
            _w('2', 'دوره X - هفته دوم'),
          ]),
          isNull);
    });

    test('بدونِ نام', () {
      expect(SubCourse.deriveFromWeekNames([_w('1', null), _w('2', null)]),
          isNull);
    });
  });
}
