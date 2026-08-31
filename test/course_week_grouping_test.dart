import 'package:flutter_test/flutter_test.dart';
import 'package:marketky/models/course_detail_model.dart';

/// شکلِ واقعیِ یک ورودی هفته از پاسخ بک‌اند
Map<String, dynamic> _week(String number, String? name, int sections) => {
      'week_number': number,
      'week_name': name,
      'sections': [
        for (int i = 0; i < sections; i++)
          {
            'title': 'ویدیو $i',
            'is_locked': i != 0,
            'video_url': i == 0 ? 'https://example.com/v.m3u8' : '',
            'video_thumbnail': null,
          },
      ],
    };

void main() {
  group('گروه‌بندی هفته‌ها بر اساس week_number', () {
    test('هر هفته یک گروه: ترتیب و تعداد حفظ می‌شود', () {
      final weeks = [
        CourseWeek.fromJson(_week('1', 'هفته اول / پا عوض کردن', 3)),
        CourseWeek.fromJson(_week('2', 'هفته دوم / الاستیکو', 2)),
      ];
      final grouped = CourseWeekGroup.groupByWeek(weeks);

      expect(grouped.length, 2);
      expect(grouped[0].weekNumber, '1');
      expect(grouped[0].groups.length, 1);
      expect(grouped[0].allSections.length, 3);
      expect(grouped[1].allSections.length, 2);
    });

    test('چند ورودی با یک week_number به یک هفته با چند گروه تبدیل می‌شوند', () {
      final weeks = [
        CourseWeek.fromJson(_week('1', 'گروه الف', 2)),
        CourseWeek.fromJson(_week('1', 'گروه ب', 3)),
        CourseWeek.fromJson(_week('2', 'گروه ج', 1)),
      ];
      final grouped = CourseWeekGroup.groupByWeek(weeks);

      expect(grouped.length, 2, reason: 'دو شماره‌ی هفته‌ی متمایز');
      expect(grouped[0].groups.length, 2);
      expect(grouped[0].groups.map((g) => g.weekName), ['گروه الف', 'گروه ب']);
      expect(grouped[0].allSections.length, 5,
          reason: 'ویدیوهای همه‌ی گروه‌های هفته با هم شمرده می‌شوند');
      expect(grouped[1].groups.length, 1);
    });

    test('ترتیبِ اولین ظهورِ هر هفته حفظ می‌شود', () {
      final weeks = [
        CourseWeek.fromJson(_week('3', 'ج', 1)),
        CourseWeek.fromJson(_week('1', 'الف', 1)),
        CourseWeek.fromJson(_week('3', 'ج۲', 1)),
      ];
      final grouped = CourseWeekGroup.groupByWeek(weeks);
      expect(grouped.map((g) => g.weekNumber), ['3', '1']);
      expect(grouped[0].groups.length, 2);
    });
  });

  group('واریانت دوره: مربی، هدیه و زمان/مکانِ اختیاری', () {
    test('coach آبجکت است، نه رشته', () {
      final item = CourseTimeAndLocationItem.fromJson({
        'is_active': true,
        'price': 2250000,
        'location': null,
        'time': null,
        'coach': {
          'id': 3,
          'full_name': 'پشتیبان عادی',
          'avatar': '/media/avatar/a.png',
        },
        'course_name': 'دوره جامع',
        'gift_product': {
          'id': 42,
          'product_name': 'فلش',
          'image': '/media/images/g.jpg',
        },
        'id': 40,
        'shipment_required': false,
        'discount_percentage': 56,
        'capacity': 100,
      });

      expect(item.coach, isNotNull);
      expect(item.coach!.fullName, 'پشتیبان عادی');
      expect(item.giftProduct!.name, 'فلش');
      // دوره‌ی آنلاین زمان و مکان ندارد
      expect(item.location, isNull);
      expect(item.time, isNull);
      expect(item.hasSchedule, isFalse);
    });

    test('دوره‌ی حضوری زمان و مکان دارد', () {
      final item = CourseTimeAndLocationItem.fromJson({
        'is_active': true,
        'price': 5000000,
        'location': 'شرق',
        'time': 'یک شنبه و سه شنبه ساعت ۱۸:۳۰ الی ۲۰',
        'coach': null,
        'course_name': 'کلاس حضوری',
        'gift_product': null,
        'id': 10,
        'shipment_required': false,
        'discount_percentage': 0,
        'capacity': 100,
      });

      expect(item.hasSchedule, isTrue);
      expect(item.location, 'شرق');
      expect(item.coach, isNull);
      expect(item.giftProduct, isNull);
    });
  });
}
