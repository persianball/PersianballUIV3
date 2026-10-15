import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/services/hls_quality.dart';
import 'package:persian_ball/views/widgets/video_quality_button.dart';

void main() {
  const v360 = HlsVariant(height: 360, bandwidth: 1, url: 'a/360.m3u8');
  const v720 = HlsVariant(height: 720, bandwidth: 2, url: 'a/720.m3u8');

  Future<void> pump(WidgetTester t, HlsVariant? sel, ValueChanged<HlsVariant?> on,
      {List<HlsVariant> variants = const [v360, v720]}) {
    return t.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: VideoQualityButton(
                variants: variants, selected: sel, onSelected: on),
          ),
        ),
      ),
    ));
  }

  testWidgets('برچسبِ فعلی و انتخاب از فهرست', (t) async {
    HlsVariant? picked = v360;
    await pump(t, null, (v) => picked = v);
    expect(find.text('خودکار'), findsOneWidget);

    await t.tap(find.text('خودکار'));
    await t.pumpAndSettle();
    expect(find.text('۷۲۰p'), findsOneWidget);
    expect(find.text('۳۶۰p'), findsOneWidget);

    await t.tap(find.text('۷۲۰p'));
    await t.pumpAndSettle();
    expect(picked, v720);
  });

  testWidgets('بدونِ کیفیت (ویدیوی mp4) دکمه نمایش داده نمی‌شود', (t) async {
    await pump(t, null, (_) {}, variants: const []);
    expect(find.byType(PopupMenuButton<int>), findsNothing);
  });
}
