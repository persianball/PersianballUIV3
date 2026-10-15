import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/utils/html_dark_theme.dart';

void main() {
  group('sanitizeHtmlForDarkBg', () {
    test('سیاه و خاکستری تیره به خاکستری روشن تبدیل می‌شوند', () {
      expect(sanitizeHtmlForDarkBg('<p style="color:#000">م</p>'),
          '<p style="color:#E2E2E2">م</p>');
      expect(sanitizeHtmlForDarkBg('<p style="color: black">م</p>'),
          '<p style="color: #E2E2E2">م</p>');
      expect(sanitizeHtmlForDarkBg('<p style="color: rgb(17, 17, 17)">م</p>'),
          '<p style="color: #E2E2E2">م</p>');
      expect(sanitizeHtmlForDarkBg('<p style="color:#333333">م</p>'),
          '<p style="color:#E2E2E2">م</p>');
    });

    test('اتریبیوت قدیمی font color هم اصلاح می‌شود', () {
      expect(sanitizeHtmlForDarkBg('<font color="#000000">م</font>'),
          '<font color="#E2E2E2">م</font>');
    });

    test('رنگ تیره‌ی رنگی فام خودش را حفظ می‌کند ولی روشن می‌شود', () {
      final out = sanitizeHtmlForDarkBg('<p style="color:#8B0000">م</p>');
      expect(out, isNot(contains('#8B0000')));
      expect(out, isNot(contains('#E2E2E2')));
      final hex = RegExp(r'#([0-9A-F]{6})').firstMatch(out)!.group(1)!;
      final r = int.parse(hex.substring(0, 2), radix: 16);
      final g = int.parse(hex.substring(2, 4), radix: 16);
      final b = int.parse(hex.substring(4, 6), radix: 16);
      expect(r, greaterThan(g)); // هنوز قرمز است
      expect(r, greaterThan(b));
      expect(r, greaterThan(0x8B)); // روشن‌تر از قبل
    });

    test('رنگ‌های روشن دست‌نخورده می‌مانند', () {
      const html = '<p style="color:#FFD700">م</p>';
      expect(sanitizeHtmlForDarkBg(html), html);
      const white = '<p style="color: #fff">م</p>';
      expect(sanitizeHtmlForDarkBg(white), white);
    });

    test('background-color دست‌نخورده می‌ماند', () {
      const html = '<p style="background-color:#000;color:#111">م</p>';
      expect(sanitizeHtmlForDarkBg(html),
          '<p style="background-color:#000;color:#E2E2E2">م</p>');
    });

    test('مقدار ناشناخته دست‌نخورده می‌ماند', () {
      const html = '<p style="color:var(--x)">م</p>';
      expect(sanitizeHtmlForDarkBg(html), html);
    });

    test('چند رنگ در یک سند همگی پردازش می‌شوند', () {
      const html =
          '<p style="color:#000">الف</p><span style="color:#222">ب</span>';
      expect(sanitizeHtmlForDarkBg(html),
          '<p style="color:#E2E2E2">الف</p><span style="color:#E2E2E2">ب</span>');
    });
  });
}
