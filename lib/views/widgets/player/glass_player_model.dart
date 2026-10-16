// lib/views/widgets/player/glass_player_model.dart
//
// وضعیتِ پخش‌کننده‌ی دوره، جدا از صفحه. صفحه ویدیو را می‌سازد (چون ادامه‌ی
// تماشا و ذخیره‌ی پیشرفت دستِ اوست) و اینجا «وصل» می‌کند؛ کنترل‌ها —
// چه در کادرِ کوچک چه در مسیرِ تمام‌صفحه — فقط به همین مدل گوش می‌دهند.
// به همین خاطر عوض کردنِ کیفیت یا رفتن به درسِ بعدی وسطِ تمام‌صفحه هم
// بدونِ بسته شدنِ آن کار می‌کند.
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import 'package:persian_ball/services/hls_quality.dart';

class GlassPlayerModel extends ChangeNotifier {
  VideoPlayerController? _video;
  VideoPlayerController? get video => _video;

  String title = '';
  String? subtitle;

  /// کاورِ درس؛ تا آماده شدنِ ویدیو و در حالتِ خطا دیده می‌شود.
  String? poster;

  bool loading = false;
  String? error;

  List<HlsVariant> variants = const [];
  HlsVariant? quality;
  bool switchingQuality = false;

  double speed = 1.0;
  bool muted = false;

  /// مسیرِ تمام‌صفحه باز است (کادرِ کوچک در این حالت ویدیو را نشان نمی‌دهد؛
  /// روی وب عنصرِ ویدیو فقط یک‌جا می‌تواند باشد).
  bool fullscreen = false;

  bool hasNext = false;
  bool hasPrevious = false;

  /// «درسِ بعدی» بعد از پایانِ ویدیو، با شمارشِ معکوس.
  String? nextUpTitle;
  int nextUpCountdown = 0;
  int nextUpTotal = 6;

  ValueChanged<HlsVariant?>? onQuality;
  VoidCallback? onBack;
  VoidCallback? onLessons;
  VoidCallback? onNext;
  VoidCallback? onPrevious;
  VoidCallback? onRetry;
  VoidCallback? onPlayNextNow;
  VoidCallback? onCancelNext;

  static const List<double> speeds = [0.75, 1, 1.25, 1.5, 1.75, 2];

  bool get isReady => _video?.value.isInitialized ?? false;
  bool get isPlaying => _video?.value.isPlaying ?? false;
  bool get isBuffering => _video?.value.isBuffering ?? false;
  Duration get position => _video?.value.position ?? Duration.zero;
  Duration get duration => _video?.value.duration ?? Duration.zero;
  bool get isEnded =>
      isReady &&
      duration > Duration.zero &&
      position >= duration - const Duration(milliseconds: 500) &&
      !isPlaying;

  /// آخرین بازه‌ی بافرشده (برای نوارِ پیشرفت)
  Duration get buffered {
    final ranges = _video?.value.buffered ?? const [];
    Duration end = Duration.zero;
    for (final r in ranges) {
      if (r.end > end) end = r.end;
    }
    return end;
  }

  void attach(VideoPlayerController? v) {
    if (identical(_video, v)) return;
    _video?.removeListener(notifyListeners);
    _video = v;
    if (v != null) {
      v.addListener(notifyListeners);
      // تنظیماتِ کاربر روی ویدیوی تازه هم می‌ماند
      if (speed != 1.0) v.setPlaybackSpeed(speed);
      if (muted) v.setVolume(0);
    }
    notifyListeners();
  }

  void setInfo({String? title, String? subtitle, String? poster}) {
    if (title != null) this.title = title;
    this.subtitle = subtitle;
    this.poster = poster;
    notifyListeners();
  }

  void setStatus({bool? loading, String? error, bool clearError = false}) {
    if (loading != null) this.loading = loading;
    if (clearError) this.error = null;
    if (error != null) this.error = error;
    notifyListeners();
  }

  void setQualityState({
    List<HlsVariant>? variants,
    HlsVariant? quality,
    bool clearQuality = false,
    bool? switching,
  }) {
    if (variants != null) this.variants = variants;
    if (clearQuality) this.quality = null;
    if (quality != null) this.quality = quality;
    if (switching != null) switchingQuality = switching;
    notifyListeners();
  }

  void setNeighbours({required bool hasNext, required bool hasPrevious}) {
    this.hasNext = hasNext;
    this.hasPrevious = hasPrevious;
    notifyListeners();
  }

  void setNextUp(String? title, int countdown, {int? total}) {
    nextUpTitle = title;
    nextUpCountdown = countdown;
    if (total != null) nextUpTotal = total;
    notifyListeners();
  }

  void setFullscreen(bool on) {
    if (fullscreen == on) return;
    fullscreen = on;
    notifyListeners();
  }

  Future<void> togglePlay() async {
    final v = _video;
    if (v == null || !v.value.isInitialized) return;
    if (isEnded) {
      await v.seekTo(Duration.zero);
      await v.play();
      return;
    }
    v.value.isPlaying ? await v.pause() : await v.play();
  }

  Future<void> seekTo(Duration d) async {
    final v = _video;
    if (v == null || !v.value.isInitialized) return;
    final total = v.value.duration;
    Duration t = d;
    if (t < Duration.zero) t = Duration.zero;
    if (total > Duration.zero && t > total) t = total;
    await v.seekTo(t);
  }

  Future<void> seekBy(Duration delta) => seekTo(position + delta);

  Future<void> setSpeed(double s) async {
    speed = s;
    await _video?.setPlaybackSpeed(s);
    notifyListeners();
  }

  Future<void> toggleMute() async {
    muted = !muted;
    await _video?.setVolume(muted ? 0 : 1);
    notifyListeners();
  }

  void selectQuality(HlsVariant? q) {
    if (q == quality) return;
    onQuality?.call(q);
  }

  @override
  void dispose() {
    _video?.removeListener(notifyListeners);
    _video = null;
    super.dispose();
  }
}
