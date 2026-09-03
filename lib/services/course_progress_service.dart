// lib/services/course_progress_service.dart
//
// پیشرفتِ تماشای ویدیوهای یک دوره، *فقط روی همین دستگاه*
// (SharedPreferences؛ روی وب همان localStorage است).
//
// برای هر ویدیو محلِ توقف و مدتش نگه داشته می‌شود تا دفعه‌ی بعد از همان‌جا
// ادامه پیدا کند، و «آخرین ویدیوی دیده‌شده» جدا ذخیره می‌شود تا صفحه‌ی دوره
// بتواند «ادامه‌ی تماشا» را پیشنهاد بدهد.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// وضعیتِ تماشای یک ویدیو.
class VideoProgress {
  const VideoProgress({
    required this.key,
    required this.title,
    required this.weekNumber,
    required this.position,
    required this.duration,
    required this.seen,
    required this.updatedAt,
  });

  /// شناسه‌ی پایدارِ ویدیو (آدرسِ ویدیو، وگرنه هفته+عنوان).
  final String key;
  final String title;
  final String weekNumber;

  /// محلِ توقف و مدتِ کلِ ویدیو.
  final Duration position;
  final Duration duration;

  /// «تقریباً تا آخر دیده شده».
  final bool seen;
  final DateTime updatedAt;

  /// کسرِ دیده‌شده بین ۰ و ۱ (برای نوارِ پیشرفتِ کارتِ ویدیو).
  double get fraction {
    if (seen) return 1;
    if (duration.inSeconds <= 0) return 0;
    final f = position.inSeconds / duration.inSeconds;
    return f.clamp(0.0, 1.0);
  }

  /// ادامه‌دادن فقط وقتی معنی دارد که نه تازه شروع شده باشد نه تمام شده.
  bool get resumable =>
      !seen && position.inSeconds >= 5 && fraction < CourseProgressService.kSeenAt;

  Map<String, dynamic> toJson() => {
        'key': key,
        'title': title,
        'week': weekNumber,
        'pos': position.inSeconds,
        'dur': duration.inSeconds,
        'seen': seen,
        'at': updatedAt.millisecondsSinceEpoch,
      };

  static VideoProgress? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final key = (raw['key'] ?? '').toString();
    if (key.isEmpty) return null;
    int intOf(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;
    return VideoProgress(
      key: key,
      title: (raw['title'] ?? '').toString(),
      weekNumber: (raw['week'] ?? '').toString(),
      position: Duration(seconds: intOf(raw['pos'])),
      duration: Duration(seconds: intOf(raw['dur'])),
      seen: raw['seen'] == true,
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(intOf(raw['at']), isUtc: false),
    );
  }
}

/// پیشرفتِ کلِ یک دوره روی این دستگاه.
class CourseProgress {
  const CourseProgress({required this.videos, required this.lastKey});

  final Map<String, VideoProgress> videos;

  /// کلیدِ آخرین ویدیویی که کاربر تماشا کرده.
  final String? lastKey;

  static const empty = CourseProgress(videos: {}, lastKey: null);

  VideoProgress? of(String key) => videos[key];

  /// آخرین ویدیوی دیده‌شده (برای پیشنهادِ «ادامه‌ی تماشا»).
  VideoProgress? get last => lastKey == null ? null : videos[lastKey];

  bool isSeen(String key) => videos[key]?.seen ?? false;

  int get seenCount => videos.values.where((v) => v.seen).length;
}

class CourseProgressService {
  CourseProgressService._();

  /// از این کسر به بعد یعنی «دیده شده»؛ تیتراژِ پایانی معمولاً رد می‌شود.
  static const double kSeenAt = 0.92;

  static String _key(int courseId) => 'course_progress_$courseId';

  static final Map<int, CourseProgress> _cache = {};

  /// نسخه‌ی حافظه — برای خواندنِ همزمان وسطِ build.
  static CourseProgress cached(int courseId) =>
      _cache[courseId] ?? CourseProgress.empty;

  static Future<CourseProgress> load(int courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(courseId));
      if (raw == null || raw.isEmpty) return _cache[courseId] = CourseProgress.empty;
      final map = jsonDecode(raw);
      if (map is! Map) return _cache[courseId] = CourseProgress.empty;
      final videos = <String, VideoProgress>{};
      for (final entry in (map['videos'] as Map? ?? {}).entries) {
        final v = VideoProgress.fromJson(entry.value);
        if (v != null) videos[v.key] = v;
      }
      final last = (map['last'] ?? '').toString();
      return _cache[courseId] = CourseProgress(
        videos: videos,
        lastKey: videos.containsKey(last) ? last : null,
      );
    } catch (_) {
      // ذخیره‌ی خرابِ محلی نباید صفحه‌ی دوره را از کار بیندازد.
      return _cache[courseId] = CourseProgress.empty;
    }
  }

  /// ثبتِ محلِ توقفِ یک ویدیو. با رد شدن از [kSeenAt] خودش «دیده‌شده» می‌شود
  /// و «دیده‌شده» دیگر پس نمی‌گیرد (تماشای دوباره‌ی نصفه آن را صفر نمی‌کند).
  static Future<CourseProgress> record(
    int courseId, {
    required String key,
    required String title,
    required String weekNumber,
    required Duration position,
    required Duration duration,
    bool? seen,
  }) async {
    final current = cached(courseId);
    final wasSeen = current.videos[key]?.seen ?? false;
    final bool done = seen ??
        (duration.inSeconds > 0 &&
            position.inSeconds / duration.inSeconds >= kSeenAt);
    final updated = VideoProgress(
      key: key,
      title: title,
      weekNumber: weekNumber,
      position: position,
      duration: duration,
      seen: wasSeen || done,
      updatedAt: DateTime.now(),
    );
    final videos = Map<String, VideoProgress>.from(current.videos)
      ..[key] = updated;
    final next = CourseProgress(videos: videos, lastKey: key);
    _cache[courseId] = next;
    await _persist(courseId, next);
    return next;
  }

  static Future<void> _persist(int courseId, CourseProgress p) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(courseId),
        jsonEncode({
          'last': p.lastKey,
          'videos': {
            for (final e in p.videos.entries) e.key: e.value.toJson(),
          },
        }),
      );
    } catch (_) {
      // نوشتنِ ناموفق فقط یعنی این دفعه ادامه‌ی تماشا ذخیره نشد.
    }
  }

  /// پاک‌کردنِ پیشرفتِ یک دوره روی این دستگاه.
  static Future<void> clear(int courseId) async {
    _cache[courseId] = CourseProgress.empty;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(courseId));
    } catch (_) {}
  }
}
