// lib/services/hls_quality.dart
//
// کیفیت‌های یک ویدیوی HLS. فایلِ master.m3u8 فهرستِ نسخه‌های هم‌زمانِ یک
// ویدیو است (۱۴۴p تا ۱۰۸۰p) و پخش‌کننده در حالتِ عادی خودش بینِ آن‌ها
// جابه‌جا می‌شود (و معمولاً از پایین‌ترین شروع می‌کند). برای انتخابِ دستی،
// همان فهرست خوانده می‌شود و پخش‌کننده مستقیم با playlistِ یک کیفیت باز
// می‌شود.
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HlsVariant {
  const HlsVariant({
    required this.height,
    required this.bandwidth,
    required this.url,
  });

  /// ارتفاعِ تصویر (۷۲۰ در 1270x720)
  final int height;
  final int bandwidth;
  final String url;

  /// «۷۲۰p»
  String get label => '${HlsQuality.faDigits(height.toString())}p';

  @override
  bool operator ==(Object other) => other is HlsVariant && other.url == url;

  @override
  int get hashCode => url.hashCode;
}

class HlsQuality {
  HlsQuality._();

  static const String _prefKey = 'video_quality_height';

  static final Map<String, List<HlsVariant>> _cache = {};

  static bool isHls(String url) =>
      Uri.tryParse(url)?.path.toLowerCase().endsWith('.m3u8') ?? false;

  /// کیفیت‌های [masterUrl]، از کم به زیاد. اگر فایل master نبود (یا خوانده
  /// نشد) فهرستِ خالی برمی‌گردد و دکمه‌ی کیفیت نمایش داده نمی‌شود.
  static Future<List<HlsVariant>> variants(String masterUrl) async {
    if (!isHls(masterUrl)) return const [];
    final cached = _cache[masterUrl];
    if (cached != null) return cached;
    try {
      final res = await http
          .get(Uri.parse(masterUrl))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return const [];
      final list = parseMaster(res.body, Uri.parse(masterUrl));
      _cache[masterUrl] = list;
      return list;
    } catch (_) {
      return const [];
    }
  }

  /// خواندنِ `#EXT-X-STREAM-INF` ها؛ خطِ بعد از هر کدام آدرسِ آن کیفیت است
  /// (معمولاً نسبی به خودِ master). کیفیت‌های هم‌ارتفاع یکی می‌شوند.
  static List<HlsVariant> parseMaster(String body, Uri base) {
    final lines = body.split(RegExp(r'\r?\n')).map((l) => l.trim()).toList();
    final byHeight = <int, HlsVariant>{};
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!line.startsWith('#EXT-X-STREAM-INF:')) continue;
      String? uri;
      for (int j = i + 1; j < lines.length; j++) {
        if (lines[j].isEmpty || lines[j].startsWith('#')) continue;
        uri = lines[j];
        break;
      }
      if (uri == null) continue;
      final res = RegExp(r'RESOLUTION=(\d+)x(\d+)').firstMatch(line);
      if (res == null) continue; // فقط صدا، یا بی‌مشخصات
      final height = int.parse(res.group(2)!);
      final bw = int.tryParse(
              RegExp(r'[^-]BANDWIDTH=(\d+)').firstMatch(',$line')?.group(1) ??
                  '') ??
          0;
      final v = HlsVariant(
        height: height,
        bandwidth: bw,
        url: base.resolve(uri).toString(),
      );
      final prev = byHeight[height];
      if (prev == null || bw > prev.bandwidth) byHeight[height] = v;
    }
    return byHeight.values.toList()
      ..sort((a, b) => a.height.compareTo(b.height));
  }

  /// نزدیک‌ترین کیفیت به [height] (بدونِ بالاتر رفتن، مگر چاره نباشد).
  static HlsVariant? closest(List<HlsVariant> list, int? height) {
    if (height == null || list.isEmpty) return null;
    HlsVariant? best;
    for (final v in list) {
      if (v.height <= height) best = v;
    }
    return best ?? list.first;
  }

  /// کیفیتی که کاربر آخرین بار انتخاب کرد (null = خودکار)؛ روی ویدیوهای
  /// بعدی هم اعمال می‌شود.
  static Future<int?> preferredHeight() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_prefKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> savePreferredHeight(int? height) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (height == null) {
        await prefs.remove(_prefKey);
      } else {
        await prefs.setInt(_prefKey, height);
      }
    } catch (_) {}
  }

  static String faDigits(String s) {
    const d = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    return s.split('').map((c) {
      final i = c.codeUnitAt(0) - 48;
      return (i >= 0 && i <= 9) ? d[i] : c;
    }).join();
  }
}
