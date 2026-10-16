import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/views/widgets/rich_description.dart';

void main() {
  test('**پررنگ** وسطِ جمله', () {
    expect(parseInlineMarkdown('۱. **برنامه‌ریزی هفتگی:** شما را هدایت می‌کند.'), [
      const MdSpan('۱. '),
      const MdSpan('برنامه‌ریزی هفتگی:', bold: true),
      const MdSpan(' شما را هدایت می‌کند.'),
    ]);
  });

  test('***پررنگِ کج*** و *کج*', () {
    expect(parseInlineMarkdown('***(توجه)*** و *مهم*'), [
      const MdSpan('(توجه)', bold: true, italic: true),
      const MdSpan(' و '),
      const MdSpan('مهم', italic: true),
    ]);
  });

  test('ستاره‌ی بی‌جفت متن می‌ماند', () {
    expect(parseInlineMarkdown('۵ * ۳ = ۱۵'), [const MdSpan('۵ * ۳ = ۱۵')]);
  });

  test('بلوک‌ها: عنوان، فهرستِ شماره‌دار، پاراگرافِ چندخطی', () {
    final b = parseMarkdownBlocks(
        'توضیحات کلی:\nخطِ دوم همان پاراگراف\n\n# ویژگی‌ها\n۱. **اول:** الف\n2. دوم\n- بولت');
    expect(b.length, 5);
    expect(b[0].plain, 'توضیحات کلی: خطِ دوم همان پاراگراف');
    expect(b[1].heading, 1);
    expect(b[1].plain, 'ویژگی‌ها');
    expect(b[2].marker, '۱.');
    expect(b[2].spans.first, const MdSpan('اول:', bold: true));
    expect(b[3].marker, '2.');
    expect(b[4].isListItem, isTrue);
    expect(b[4].marker, isNull);
  });

  test('تشخیصِ HTML', () {
    expect(RichDescription.looksLikeHtml('<p>سلام</p>'), isTrue);
    expect(RichDescription.looksLikeHtml('قیمت < ۱۰ و > ۵'), isFalse);
  });
}
