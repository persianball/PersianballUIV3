import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketky/views/widgets/html_description_image.dart';

/// همان HTML واقعی که ادیتور بک‌اند برای ویدیوی امبدشده تولید می‌کند
const _realEditorHtml = '''
<p>توضیح قبل از ویدیو</p>
<figure class="media">
    <oembed url="https://www.youtube.com/watch?v=zd1Jw5hRcaE&amp;pp=ygULcGVyc2lhbmJhbGw%3D"></oembed>
</figure>
<p>توضیح بعد از ویدیو</p>
''';

void main() {
  group('استخراج شناسه‌ی ویدیوی یوتیوب', () {
    test('حالت watch?v= با پارامتر اضافه و &amp; اسکیپ‌شده', () {
      expect(
        HtmlDescriptionVideo.youtubeId(
            'https://www.youtube.com/watch?v=zd1Jw5hRcaE&pp=ygULcGVyc2lhbmJhbGw%3D'),
        'zd1Jw5hRcaE',
      );
    });

    test('حالت کوتاه youtu.be', () {
      expect(HtmlDescriptionVideo.youtubeId('https://youtu.be/zd1Jw5hRcaE'),
          'zd1Jw5hRcaE');
    });

    test('حالت embed و shorts', () {
      expect(
          HtmlDescriptionVideo.youtubeId(
              'https://www.youtube.com/embed/zd1Jw5hRcaE'),
          'zd1Jw5hRcaE');
      expect(
          HtmlDescriptionVideo.youtubeId(
              'https://www.youtube.com/shorts/zd1Jw5hRcaE'),
          'zd1Jw5hRcaE');
    });

    test('لینک غیر یوتیوب شناسه ندارد', () {
      expect(HtmlDescriptionVideo.youtubeId('https://www.aparat.com/v/abc123'),
          isNull);
      expect(HtmlDescriptionVideo.youtubeId('نه-لینک'), isNull);
    });
  });

  testWidgets('figure.media به کارت ویدیو تبدیل می‌شود و متن‌ها می‌مانند',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: HtmlDescriptionBody(html: _realEditorHtml),
        ),
      ),
    ));
    await tester.pump();

    // ویدیو به‌صورت یک ویجت مستقل رندر شده است
    final video = tester.widget<HtmlDescriptionVideo>(
        find.byType(HtmlDescriptionVideo));
    expect(video.url,
        'https://www.youtube.com/watch?v=zd1Jw5hRcaE&pp=ygULcGVyc2lhbmJhbGw%3D',
        reason: 'باید &amp; به & تبدیل شده باشد');

    // دکمه‌ی پخش و برچسب تماشا دیده می‌شوند
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.text('تماشای ویدیو'), findsOneWidget);

    // تگ خام oembed نباید جایی به‌عنوان متن نمایش داده شود
    expect(find.textContaining('oembed'), findsNothing);
  });

  testWidgets('امبد غیر یوتیوب (اینستاگرام) به کارت «باز کردن» تبدیل می‌شود',
      (tester) async {
    // همان چیزی که محصول ۱ واقعاً از بک‌اند برمی‌گرداند: یک امبد اینستاگرام
    // و یک ویدیوی یوتیوب کنار هم
    const html = '''
<figure class="media"><oembed url="https://www.instagram.com/p/BmMZgokAGGQ/?taken-by=nasa"></oembed></figure>
<p>بین دو امبد</p>
<figure class="media"><oembed url="https://www.youtube.com/watch?v=RuTmd4g5K8Q"></oembed></figure>
''';
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: HtmlDescriptionBody(html: html)),
      ),
    ));
    await tester.pump();

    expect(find.byType(HtmlDescriptionVideo), findsNWidgets(2));
    // اینستاگرام ویدیو نیست، پس نه دکمه‌ی پخش قرمز دارد نه برچسب «تماشا»
    expect(find.text('باز کردن در instagram.com'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new_rounded), findsNWidgets(3));
    // یوتیوب همچنان کارت ویدیو است
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.text('تماشای ویدیو'), findsOneWidget);
  });

  testWidgets('توضیحات بدون ویدیو هیچ کارت ویدیویی نمی‌سازد', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: HtmlDescriptionBody(html: '<p>فقط متن ساده</p>'),
      ),
    ));
    await tester.pump();

    expect(find.byType(HtmlDescriptionVideo), findsNothing);
  });
}
