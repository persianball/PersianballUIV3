import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/services/hls_quality.dart';

const _master = '''#EXTM3U
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=919870,RESOLUTION=636x360,CODECS="avc1.4d401e,mp4a.40.2"
index-f3-v1-a1.m3u8
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=273349,RESOLUTION=254x144
index-f1-v1-a1.m3u8
#EXT-X-STREAM-INF:PROGRAM-ID=1,AVERAGE-BANDWIDTH=1,BANDWIDTH=5040864,RESOLUTION=1906x1080
index-f6-v1-a1.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=64000,CODECS="mp4a.40.2"
audio-only.m3u8
''';

void main() {
  final base = Uri.parse(
      'https://cdn.example.ir/ch/vid/,h_144.mp4,h_1080.mp4,.list/master.m3u8');

  test('کیفیت‌ها از کم به زیاد، با آدرسِ کامل، بدونِ نسخه‌ی فقط-صدا', () {
    final v = HlsQuality.parseMaster(_master, base);
    expect(v.map((e) => e.height), [144, 360, 1080]);
    expect(v.last.url,
        'https://cdn.example.ir/ch/vid/,h_144.mp4,h_1080.mp4,.list/index-f6-v1-a1.m3u8');
    expect(v.last.bandwidth, 5040864); // نه AVERAGE-BANDWIDTH
    expect(v.last.label, '۱۰۸۰p');
  });

  test('نزدیک‌ترین کیفیتِ نه‌بالاتر به ترجیحِ ذخیره‌شده', () {
    final v = HlsQuality.parseMaster(_master, base);
    expect(HlsQuality.closest(v, null), isNull); // خودکار
    expect(HlsQuality.closest(v, 720)!.height, 360);
    expect(HlsQuality.closest(v, 1080)!.height, 1080);
    expect(HlsQuality.closest(v, 100)!.height, 144);
  });

  test('فقط m3u8 کیفیت دارد', () {
    expect(HlsQuality.isHls(base.toString()), isTrue);
    expect(HlsQuality.isHls('https://x.ir/v.mp4'), isFalse);
  });
}
