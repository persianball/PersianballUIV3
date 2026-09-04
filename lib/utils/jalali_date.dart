// lib/utils/jalali_date.dart
//
// تبدیل تاریخ میلادی به شمسی، بدون هیچ وابستگی جدید.
// الگوریتم استاندارد بر پایه‌ی «روز جولیَن» است (همان روشی که بسته‌های
// رایج شمسی استفاده می‌کنند) و برای بازه‌ی کاربردیِ اپ دقیق است.
//
// تاریخ‌های سرور با آفست +03:30 می‌آیند؛ قبل از تبدیل به وقت محلی همان
// منطقه برده می‌شوند تا سفارشِ ساعت ۲ بامداد یک روز عقب نیفتد.

class JalaliDate {
  final int year;
  final int month;
  final int day;

  const JalaliDate(this.year, this.month, this.day);

  static const List<String> monthNames = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  String get monthName => monthNames[month - 1];

  /// مثل «۱۲ شهریور ۱۴۰۴»
  String get long => '${_fa(day)} $monthName ${_fa(year)}';

  /// مثل «۱۴۰۴/۰۶/۱۲»
  String get short =>
      '${_fa(year)}/${_fa(month, pad: 2)}/${_fa(day, pad: 2)}';

  static const List<String> _digits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  static String _fa(int n, {int pad = 0}) {
    var s = n.toString().padLeft(pad, '0');
    final b = StringBuffer();
    for (final ch in s.codeUnits) {
      if (ch >= 48 && ch <= 57) {
        b.write(_digits[ch - 48]);
      } else {
        b.writeCharCode(ch);
      }
    }
    return b.toString();
  }

  /// ساعت به شکل «۱۴:۱۸»
  static String time(DateTime d) =>
      '${_fa(d.hour, pad: 2)}:${_fa(d.minute, pad: 2)}';

  static int _div(int a, int b) => (a / b).floor();

  factory JalaliDate.fromDateTime(DateTime date) {
    final gy = date.year;
    final gm = date.month;
    final gd = date.day;

    final gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    var gy2 = (gm > 2) ? gy + 1 : gy;
    var days = 355666 +
        (365 * gy) +
        _div(gy2 + 3, 4) -
        _div(gy2 + 99, 100) +
        _div(gy2 + 399, 400) +
        gd +
        gdm[gm - 1];

    var jy = -1595 + (33 * _div(days, 12053));
    days %= 12053;
    jy += 4 * _div(days, 1461);
    days %= 1461;
    if (days > 365) {
      jy += _div(days - 1, 365);
      days = (days - 1) % 365;
    }
    final int jm;
    final int jd;
    if (days < 186) {
      jm = 1 + _div(days, 31);
      jd = 1 + (days % 31);
    } else {
      jm = 7 + _div(days - 186, 30);
      jd = 1 + ((days - 186) % 30);
    }
    return JalaliDate(jy, jm, jd);
  }
}

/// تاریخِ سرور (ISO با آفست) به «۱۲ شهریور ۱۴۰۴ · ۱۴:۱۸».
///
/// اگر آفست منطقه‌ی خودِ رشته موجود باشد همان حفظ می‌شود، پس تاریخِ نمایش
/// با آنچه فروشنده در پنل می‌بیند یکی است — نه وقتِ محلیِ دستگاهِ کاربر.
String formatOrderDate(DateTime? date, {bool withTime = true}) {
  if (date == null) return '—';
  final j = JalaliDate.fromDateTime(date);
  return withTime ? '${j.long} · ${JalaliDate.time(date)}' : j.long;
}

/// تاریخِ سرور را با حفظِ منطقه‌ی زمانیِ خودش می‌خواند.
///
/// DateTime.parse یک رشته‌ی «+03:30» را به UTC تبدیل می‌کند، پس سفارشِ
/// ساعت ۱۴:۱۸ به‌صورت ۱۰:۴۸ نشان داده می‌شد و سفارش‌های بامداد یک روز
/// عقب می‌افتادند. اینجا آفستِ خودِ رشته دوباره اعمال می‌شود تا همان
/// ساعتِ دیوارِ سرور دیده شود.
DateTime? parseServerDate(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty || s.toLowerCase() == 'null') return null;
  final base = DateTime.tryParse(s);
  if (base == null) return null;
  final m = RegExp(r'([+-])(\d{2}):?(\d{2})$').firstMatch(s);
  if (m == null) return base;
  final sign = m.group(1) == '-' ? -1 : 1;
  final offset = Duration(
        hours: int.parse(m.group(2)!),
        minutes: int.parse(m.group(3)!),
      ) *
      sign;
  return base.toUtc().add(offset);
}
