// views/widgets/modals/video_player_dialog.dart
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/services/hls_quality.dart';
import 'package:persian_ball/views/widgets/video_quality_button.dart';
import 'package:video_player/video_player.dart';

/// دیالوگ پخش ویدیو به صورت پورتریت با انیمیشن نرم.
/// فقط زمانی صدا زده شود که [videoUrl] خالی نباشد.
Future<void> showVideoPlayerDialog(
  BuildContext context, {
  required String videoUrl,
  String? title,
  Duration startAt = Duration.zero,
  ValueChanged<VideoWatchProgress>? onProgress,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'بستن ویدیو',
    barrierColor: Colors.black87,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => VideoPlayerDialog(
      videoUrl: videoUrl,
      title: title,
      startAt: startAt,
      onProgress: onProgress,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// یک گزارشِ «تا کجا دیده شد» که دیالوگ هر چند ثانیه و موقعِ بسته‌شدن می‌دهد.
class VideoWatchProgress {
  const VideoWatchProgress({
    required this.position,
    required this.duration,
    required this.finished,
  });

  final Duration position;
  final Duration duration;

  /// پخش به انتهای ویدیو رسید.
  final bool finished;
}

class VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;
  final String? title;

  /// ادامه از محلِ توقفِ دفعه‌ی قبل.
  final Duration startAt;

  /// هر ۵ ثانیه، در پایانِ ویدیو، و هنگامِ بستنِ دیالوگ صدا زده می‌شود.
  final ValueChanged<VideoWatchProgress>? onProgress;

  const VideoPlayerDialog({
    super.key,
    required this.videoUrl,
    this.title,
    this.startAt = Duration.zero,
    this.onProgress,
  });

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _error;
  Duration _lastReported = Duration.zero;
  bool _finished = false;

  /// کیفیت‌های فایلِ m3u8؛ خالی یعنی دکمه‌ی کیفیت نمایش داده نمی‌شود.
  List<HlsVariant> _variants = const [];

  /// null = خودکار
  HlsVariant? _quality;
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  /// اگر کاربر قبلاً کیفیتی انتخاب کرده بود، ویدیو از همان اول با آن باز
  /// می‌شود، نه اینکه اول خودکار (۱۴۴p) پخش شود و بعد عوض شود.
  Future<void> _boot() async {
    final results = await Future.wait([
      HlsQuality.variants(widget.videoUrl),
      HlsQuality.preferredHeight(),
    ]);
    if (!mounted) return;
    final variants = results[0] as List<HlsVariant>;
    _variants = variants;
    _quality = HlsQuality.closest(variants, results[1] as int?);
    await _init(startAt: widget.startAt);
  }

  Future<void> _setQuality(HlsVariant? q) async {
    final old = _videoController;
    if (q == _quality || old == null) return;
    HlsQuality.savePreferredHeight(q?.height);
    final at = old.value.position;
    final wasPlaying = old.value.isPlaying;
    setState(() {
      _quality = q;
      _switching = true;
    });
    await _init(startAt: at, autoPlay: wasPlaying);
    if (mounted) setState(() => _switching = false);
  }

  Future<void> _init({
    Duration startAt = Duration.zero,
    bool autoPlay = true,
  }) async {
    try {
      final url = _quality?.url ?? widget.videoUrl;
      final vc = VideoPlayerController.networkUrl(Uri.parse(url));
      await vc.initialize();
      if (!mounted) {
        vc.dispose();
        return;
      }
      // ادامه از محلِ توقف؛ اگر آن محل عملاً پایانِ ویدیو بود از اول.
      final total = vc.value.duration;
      if (startAt > Duration.zero &&
          total > Duration.zero &&
          startAt < total - const Duration(seconds: 3)) {
        await vc.seekTo(startAt);
      }
      vc.addListener(_onTick);
      final cc = ChewieController(
        videoPlayerController: vc,
        autoPlay: autoPlay,
        looping: false,
        // پخش و تمام‌صفحه هر دو در حالت پورتریت می‌مانند
        deviceOrientationsOnEnterFullScreen: const [
          DeviceOrientation.portraitUp,
        ],
        deviceOrientationsAfterFullScreen: const [
          DeviceOrientation.portraitUp,
        ],
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColor.goldEnd,
          handleColor: AppColor.goldEnd,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white54,
        ),
      );
      // پخش‌کننده‌ی قبلی (موقعِ عوض کردنِ کیفیت) بعد از آماده شدنِ جدید
      // بسته می‌شود تا تصویر وسطش سیاه نشود.
      final oldVc = _videoController;
      final oldCc = _chewieController;
      oldVc?.removeListener(_onTick);
      setState(() {
        _videoController = vc;
        _chewieController = cc;
      });
      oldCc?.dispose();
      oldVc?.dispose();
    } catch (e) {
      if (mounted) setState(() => _error = 'پخش این ویدیو ممکن نیست');
    }
  }

  /// گزارشِ پیشرفت: هر ۵ ثانیه یک‌بار تا نوشتنِ حافظه‌ی محلی زیاد نشود.
  void _onTick() {
    final v = _videoController?.value;
    if (v == null || !v.isInitialized || v.duration <= Duration.zero) return;
    final atEnd = v.position >= v.duration - const Duration(milliseconds: 800);
    if (atEnd && !_finished) {
      _finished = true;
      _report(v.position, v.duration, finished: true);
      return;
    }
    if ((v.position - _lastReported).abs() < const Duration(seconds: 5)) return;
    _report(v.position, v.duration, finished: false);
  }

  void _report(Duration pos, Duration dur, {required bool finished}) {
    _lastReported = pos;
    widget.onProgress
        ?.call(VideoWatchProgress(position: pos, duration: dur, finished: finished));
  }

  @override
  void dispose() {
    // آخرین محلِ توقف موقعِ بستن هم ثبت می‌شود، وگرنه تا ۵ ثانیه از دست می‌رود.
    final v = _videoController?.value;
    if (v != null && v.isInitialized && v.duration > Duration.zero) {
      _report(v.position, v.duration, finished: _finished);
    }
    _videoController?.removeListener(_onTick);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width * 0.92;
    // قاب پورتریت: نسبت ۹:۱۶ ولی محدود به ارتفاع صفحه
    final maxHeight = size.height * 0.7;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: maxHeight + 56,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // نوار بالای دیالوگ: عنوان و دکمه بستن
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title ?? 'پخش ویدیو',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Estedad',
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          VideoQualityButton(
                            variants: _variants,
                            selected: _quality,
                            busy: _switching,
                            onSelected: _setQuality,
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                            tooltip: 'بستن',
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SizedBox(
                        width: maxWidth,
                        height: maxHeight,
                        child: _buildPlayerArea(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerArea() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Estedad', color: Colors.white),
          ),
        ),
      );
    }

    final cc = _chewieController;
    final vc = _videoController;
    // انیمیشن نرم بین حالت لودینگ و پخش
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: (cc != null && vc != null && vc.value.isInitialized)
          ? Center(
              key: const ValueKey('player'),
              child: AspectRatio(
                aspectRatio:
                    vc.value.aspectRatio == 0 ? 9 / 16 : vc.value.aspectRatio,
                child: Chewie(controller: cc),
              ),
            )
          : const Center(
              key: ValueKey('loading'),
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }
}
