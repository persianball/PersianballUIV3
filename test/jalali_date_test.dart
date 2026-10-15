// تاریخ شمسی و حفظِ منطقه‌ی زمانیِ سرور.
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/utils/jalali_date.dart';

void main() {
  test('تبدیل میلادی به شمسی', () {
    expect(JalaliDate.fromDateTime(DateTime(2025, 9, 11)).year, 1404);
    expect(JalaliDate.fromDateTime(DateTime(2025, 9, 11)).month, 6);
    expect(JalaliDate.fromDateTime(DateTime(2025, 9, 11)).day, 20);
    // نوروز
    final nowruz = JalaliDate.fromDateTime(DateTime(2025, 3, 21));
    expect([nowruz.year, nowruz.month, nowruz.day], [1404, 1, 1]);
    // آخرین روز سال
    final last = JalaliDate.fromDateTime(DateTime(2025, 3, 20));
    expect([last.year, last.month, last.day], [1403, 12, 30]);
  });

  test('آفستِ سرور حفظ می‌شود، نه تبدیل به UTC', () {
    final d = parseServerDate('2025-09-11T14:18:06.045020+03:30')!;
    // DateTime.parse تنها، ساعت را ۱۰:۴۸ می‌کرد
    expect(d.hour, 14);
    expect(d.minute, 18);
  });

  test('سفارشِ بامداد نباید یک روز عقب بیفتد', () {
    final d = parseServerDate('2025-09-11T01:30:00+03:30')!;
    final j = JalaliDate.fromDateTime(d);
    expect(j.day, 20); // ۲۰ شهریور، نه ۱۹
  });

  test('ورودی نامعتبر امن است', () {
    expect(parseServerDate(null), isNull);
    expect(parseServerDate('None'), isNull);
    expect(parseServerDate(''), isNull);
    expect(formatOrderDate(null), '—');
  });

  test('قالب فارسی با ارقام فارسی', () {
    final d = parseServerDate('2025-09-11T14:18:06+03:30');
    expect(formatOrderDate(d), '۲۰ شهریور ۱۴۰۴، ساعت ۱۴:۱۸');
    expect(formatOrderDate(d, withTime: false), '۲۰ شهریور ۱۴۰۴');
  });
}
