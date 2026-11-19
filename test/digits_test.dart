import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/utils/digits.dart';

void main() {
  test('رقمِ فارسی و عربی لاتین می‌شود، حروف دست نمی‌خورند', () {
    expect(toEnglishDigits('OFF۲۰'), 'OFF20');
    expect(toEnglishDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    expect(toEnglishDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
    expect(toEnglishDigits('Yalda-1404'), 'Yalda-1404');
    expect(toEnglishDigits('تخفیف۱۰'), 'تخفیف10');
  });

  test('کدِ پیست‌شده: فاصله و نویسه‌های نامرئی حذف می‌شود', () {
    expect(normalizeCode('  OFF ۲۰ \n'), 'OFF20');
    expect(normalizeCode('‏OFF‌۵۰‎'), 'OFF50');
    expect(normalizeCode('aBc۱'), 'aBc1'); // بزرگی/کوچکی حفظ می‌شود
    expect(normalizeCode('   '), '');
  });

  test('هنگامِ تایپ، رقم همان لحظه لاتین می‌شود و مکان‌نما سرِ جایش می‌ماند',
      () {
    const f = EnglishDigitsFormatter();
    const typed = TextEditingValue(
        text: 'OFF۲', selection: TextSelection.collapsed(offset: 4));
    final out = f.formatEditUpdate(TextEditingValue.empty, typed);
    expect(out.text, 'OFF2');
    expect(out.selection, typed.selection);
    const latin = TextEditingValue(text: 'OFF2');
    expect(identical(f.formatEditUpdate(typed, latin), latin), isTrue);
  });
}
