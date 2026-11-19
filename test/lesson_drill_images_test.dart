// تصویرِ چیدمان و میزانِ انجامِ تمرین برای هر ویدیوی دوره.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/models/course_detail_model.dart';
import 'package:persian_ball/models/course_models.dart';
import 'package:persian_ball/views/widgets/lesson_drill_images.dart';

Map<String, dynamic> _section(dynamic layout, dynamic volume) => {
      'title': 'استایل پا عوض کردن',
      'is_locked': false,
      'video_url': 'https://v/master.m3u8',
      'video_thumbnail': null,
      'layout_image': layout,
      'volume_image': volume,
    };

Widget _host(Widget child) => MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: SizedBox(width: 360, child: child)),
      ),
    );

void main() {
  test('هر دو مدل: لینک، null و رشته‌ی خالی', () {
    final my = MyCourseWeekSectionItem.fromJson(
        _section('https://pball.ah8ad3.ir/media/a.jpg', null));
    expect(my.layoutImage, 'https://pball.ah8ad3.ir/media/a.jpg');
    expect(my.volumeImage, isNull);

    final pub = CourseWeekSectionItem.fromJson(_section('', '/media/b.png'));
    expect(pub.layoutImage, isNull);
    expect(pub.volumeImage, '/media/b.png');
  });

  test('مسیرِ نسبی به آدرسِ کامل تبدیل می‌شود', () {
    expect(drillImageUrl('/media/b.png'), endsWith('/media/b.png'));
    expect(drillImageUrl('/media/b.png'), startsWith('http'));
    expect(drillImageUrl('https://x/y.jpg'), 'https://x/y.jpg');
  });

  testWidgets('هر دو تصویر با برچسب، و ضربه تمام‌صفحه را باز می‌کند', (t) async {
    await t.pumpWidget(_host(const LessonDrillImages(
        layoutImage: 'https://x/a.jpg', volumeImage: 'https://x/b.jpg')));
    expect(find.text('چیدمان تمرین'), findsOneWidget);
    expect(find.text('میزان انجام تمرین'), findsOneWidget);
    await t.tap(find.text('میزان انجام تمرین'));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(InteractiveViewer), findsWidgets);
    expect(find.widgetWithText(AppBar, 'میزان انجام تمرین'), findsOneWidget);
  });

  testWidgets('فقط یکی آپلود شده', (t) async {
    await t.pumpWidget(_host(
        const LessonDrillImages(layoutImage: null, volumeImage: 'https://x/b.jpg')));
    expect(find.text('چیدمان تمرین'), findsNothing);
    expect(find.text('میزان انجام تمرین'), findsOneWidget);
  });

  testWidgets('هیچ‌کدام: چیزی کشیده نمی‌شود', (t) async {
    await t.pumpWidget(_host(const LessonDrillImages(layoutImage: null, volumeImage: null)));
    expect(find.byType(InkWell), findsNothing);
  });
}
