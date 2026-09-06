// lib/views/screens/my_course_detail_page.dart
//
// صفحه‌ی تماشای دوره‌ی خریداری‌شده.
//
// چیدمان: پخش‌کننده در یک SliverAppBarِ سنجاق‌شده (همیشه دیده می‌شود و با
// اسکرول بریده نمی‌شود)، محتوای دوره زیرِ آن اسکرول می‌کند و فهرستِ کاملِ
// هفته‌ها/ویدیوها در یک باتم‌شیتِ کشیدنی باز می‌شود.
//
// پیشرفتِ تماشا از [CourseProgressService] می‌آید (همان سرویسی که صفحه‌ی
// معرفیِ دوره استفاده می‌کند)، پس با بازکردنِ صفحه دقیقاً همان ویدیویی که
// کاربر آخرین‌بار می‌دید، از همان ثانیه‌ای که رها کرده بود، بارگذاری می‌شود.
import 'dart:async';
import 'dart:math' as math;

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'package:marketky/constant/app_breakpoints.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/models/course_models.dart';
import 'package:marketky/services/course_progress_service.dart';
import 'package:marketky/views/widgets/app_buttons.dart';
import 'package:marketky/views/widgets/app_network_image.dart';
import 'package:marketky/views/widgets/course_lesson_list.dart';
import 'package:marketky/views/widgets/motion.dart';
import 'package:marketky/views/widgets/shimmer.dart';

/// ثانیه‌های شمارشِ معکوسِ «درسِ بعدی» بعد از تمام‌شدنِ یک ویدیو.
const int _kAutoNextSeconds = 6;

/// ارتفاعِ کارتِ نوارِ «در ادامه» — تصویر ۸۸ + عنوانِ دو خطی + نامِ هفته.
const double _kUpNextCardHeight = 166;

class MyCourseDetailPage extends StatefulWidget {
  final MyCourse myCourse;
  const MyCourseDetailPage({super.key, required this.myCourse});

  @override
  State<MyCourseDetailPage> createState() => _MyCourseDetailPageState();
}

class _MyCourseDetailPageState extends State<MyCourseDetailPage> {
  late final List<CourseLesson> _lessons =
      flattenLessons(widget.myCourse.courseDetail.detail.weeks);

  /// پیشرفت و درسِ فعلی به‌صورت Listenable نگه داشته می‌شوند تا فهرستِ
  /// درس‌ها (چه در شیت، چه در ستونِ دسکتاپ) بدون rebuildِ کلِ صفحه
  /// به‌روز شود — شیت حتی وقتی باز است زنده می‌ماند.
  final ValueNotifier<CourseProgress> _progress =
      ValueNotifier(CourseProgress.empty);
  final ValueNotifier<String?> _currentKey = ValueNotifier(null);

  final ScrollController _scroll = ScrollController();

  VideoPlayerController? _video;
  ChewieController? _chewie;

  CourseLesson? _current;
  bool _booting = true;
  bool _videoLoading = false;
  String? _videoError;

  /// پوششِ «درسِ بعدی» که بعد از پایانِ ویدیو با شمارشِ معکوس ظاهر می‌شود.
  CourseLesson? _nextUp;
  int _countdown = _kAutoNextSeconds;
  Timer? _countdownTimer;

  Duration _lastReported = Duration.zero;
  bool _reachedEnd = false;

  int get _courseId => widget.myCourse.courseDetail.id;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _flushProgress();
    _video?.removeListener(_onTick);
    _chewie?.dispose();
    _video?.dispose();
    _scroll.dispose();
    _progress.dispose();
    _currentKey.dispose();
    super.dispose();
  }

  // ==================== بارگذاری و پیشرفت ====================

  Future<void> _boot() async {
    final loaded = await CourseProgressService.load(_courseId);
    final progress = await _importLegacyProgress(loaded);
    if (!mounted) return;
    _progress.value = progress;

    final start = _resumeTarget(progress);
    setState(() => _booting = false);
    if (start != null) {
      await _play(start, autoPlay: false);
    }
  }

  /// نسخه‌ی قدیمیِ صفحه فقط شماره‌ی درس‌های دیده‌شده را ذخیره می‌کرد؛ آن‌ها
  /// یک‌بار به سرویسِ پیشرفت منتقل می‌شوند تا کاربر تیک‌هایش را از دست ندهد.
  Future<CourseProgress> _importLegacyProgress(CourseProgress current) async {
    if (current.videos.isNotEmpty) return current;
    final prefs = await SharedPreferences.getInstance();
    final legacyKey = 'watchedVideos_$_courseId';
    final legacy = prefs.getStringList(legacyKey);
    if (legacy == null || legacy.isEmpty) return current;

    final indices = legacy
        .map(int.tryParse)
        .whereType<int>()
        .where((i) => i >= 0 && i < _lessons.length)
        .toList()
      ..sort();

    var progress = current;
    for (final i in indices) {
      final lesson = _lessons[i];
      progress = await CourseProgressService.setSeen(
        _courseId,
        key: lesson.progressKey,
        title: lesson.title,
        weekNumber: lesson.weekNumber,
        seen: true,
      );
    }
    await prefs.remove(legacyKey);
    return progress;
  }

  /// ویدیویی که صفحه باید با آن باز شود: آخرین ویدیوی دیده‌شده، وگرنه
  /// اولین درسِ تماشا‌نشده، وگرنه اولین درسِ قابلِ پخش.
  CourseLesson? _resumeTarget(CourseProgress progress) {
    final last = progress.lastKey;
    if (last != null) {
      for (final lesson in _lessons) {
        if (lesson.playable && lesson.progressKey == last) return lesson;
      }
    }
    for (final lesson in _lessons) {
      if (lesson.playable && !progress.isSeen(lesson.progressKey)) return lesson;
    }
    for (final lesson in _lessons) {
      if (lesson.playable) return lesson;
    }
    return null;
  }

  CourseLesson? _neighbour(int step) {
    final current = _current;
    if (current == null) return null;
    for (int i = current.flatIndex + step;
        i >= 0 && i < _lessons.length;
        i += step) {
      if (_lessons[i].playable) return _lessons[i];
    }
    return null;
  }

  /// درسی که دکمه‌ی «ادامه‌ی تماشا» باید ببرد: نیمه‌تمامِ فعلی، وگرنه
  /// اولین درسِ تماشا‌نشده.
  CourseLesson? get _continueTarget {
    final progress = _progress.value;
    final current = _current;
    if (current != null) {
      final watched = progress.of(current.progressKey);
      if (watched != null && watched.resumable) return current;
    }
    for (final lesson in _lessons) {
      if (lesson.playable && !progress.isSeen(lesson.progressKey)) return lesson;
    }
    return current;
  }

  // ==================== پخش ====================

  Future<void> _play(CourseLesson lesson, {bool autoPlay = true}) async {
    if (!lesson.playable) return;

    _cancelAutoNext();
    _flushProgress();
    _video?.removeListener(_onTick);
    final oldChewie = _chewie;
    final oldVideo = _video;

    setState(() {
      _current = lesson;
      _chewie = null;
      _video = null;
      _videoLoading = true;
      _videoError = null;
    });
    _currentKey.value = lesson.progressKey;
    _lastReported = Duration.zero;
    _reachedEnd = false;

    oldChewie?.dispose();
    await oldVideo?.dispose();

    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(lesson.videoUrl));
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      // ادامه از محلِ توقف — مگر اینکه عملاً تهِ ویدیو باشد.
      final saved = _progress.value.of(lesson.progressKey);
      if (saved != null && saved.resumable) {
        final total = controller.value.duration;
        if (saved.position < total - const Duration(seconds: 3)) {
          await controller.seekTo(saved.position);
          _lastReported = saved.position;
        }
      }

      controller.addListener(_onTick);
      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: autoPlay,
        looping: false,
        allowPlaybackSpeedChanging: true,
        playbackSpeeds: const [0.75, 1, 1.25, 1.5, 1.75, 2],
        deviceOrientationsOnEnterFullScreen: const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: const [DeviceOrientation.portraitUp],
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColor.pitchGreenLight,
          handleColor: AppColor.pitchGreenLight,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white54,
        ),
      );

      if (!mounted) {
        chewie.dispose();
        await controller.dispose();
        return;
      }
      setState(() {
        _video = controller;
        _chewie = chewie;
        _videoLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _videoLoading = false;
        _videoError = 'پخش این ویدیو ممکن نیست. اتصالت را بررسی کن.';
      });
    }
  }

  /// هر ۵ ثانیه محلِ توقف ذخیره می‌شود؛ نوشتنِ بیشتر فقط حافظه را می‌ساید.
  void _onTick() {
    final value = _video?.value;
    if (value == null || !value.isInitialized) return;
    if (value.duration <= Duration.zero) return;

    final atEnd =
        value.position >= value.duration - const Duration(milliseconds: 800);
    if (atEnd && !_reachedEnd) {
      _reachedEnd = true;
      _record(value.position, value.duration, seen: true);
      _startAutoNext();
      return;
    }
    if ((value.position - _lastReported).abs() < const Duration(seconds: 5)) {
      return;
    }
    _record(value.position, value.duration);
  }

  void _flushProgress() {
    final value = _video?.value;
    if (value == null || !value.isInitialized) return;
    if (value.duration <= Duration.zero) return;
    _record(value.position, value.duration);
  }

  Future<void> _record(Duration position, Duration duration,
      {bool? seen}) async {
    final lesson = _current;
    if (lesson == null) return;
    _lastReported = position;
    final next = await CourseProgressService.record(
      _courseId,
      key: lesson.progressKey,
      title: lesson.title,
      weekNumber: lesson.weekNumber,
      position: position,
      duration: duration,
      seen: seen,
    );
    if (mounted) _progress.value = next;
  }

  Future<void> _toggleSeen(CourseLesson lesson) async {
    final seen = _progress.value.isSeen(lesson.progressKey);
    final next = await CourseProgressService.setSeen(
      _courseId,
      key: lesson.progressKey,
      title: lesson.title,
      weekNumber: lesson.weekNumber,
      seen: !seen,
    );
    if (mounted) _progress.value = next;
  }

  // ==================== درسِ بعدی ====================

  void _startAutoNext() {
    final next = _neighbour(1);
    if (next == null) return;
    setState(() {
      _nextUp = next;
      _countdown = _kAutoNextSeconds;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_countdown <= 1) {
        timer.cancel();
        final target = _nextUp;
        setState(() => _nextUp = null);
        if (target != null) _play(target);
        return;
      }
      setState(() => _countdown--);
    });
  }

  void _cancelAutoNext() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (_nextUp != null) setState(() => _nextUp = null);
  }

  void _openLessons() {
    showCourseLessonsSheet(
      context,
      lessons: _lessons,
      progress: _progress,
      currentKey: _currentKey,
      onPlay: _play,
      onToggleSeen: _toggleSeen,
    );
  }

  // ==================== پخش‌کننده ====================

  double _playerHeight(BuildContext context, {required bool desktop}) {
    final size = MediaQuery.of(context).size;
    final width = desktop
        ? math.min(size.width * 0.58, 820.0)
        : size.width;
    // روی نمایشگرهای کوتاه، ویدیو نباید بیشتر از نیمِ صفحه را بگیرد.
    return math.min(width * 9 / 16, size.height * 0.46);
  }

  Widget _playerStage({required double height, required bool rounded}) {
    final detail = widget.myCourse.courseDetail;
    final poster = _current?.section.videoThumbnail ??
        detail.videoThumbnail ??
        (detail.images.isNotEmpty ? detail.images.first : detail.image);

    final Widget stage = Container(
      height: height,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1).animate(animation),
                child: child,
              ),
            ),
            child: _playerContent(poster: poster, height: height),
          ),
          _topBar(),
          if (_nextUp != null) _nextUpOverlay(_nextUp!),
        ],
      ),
    );

    if (!rounded) return stage;
    return Container(
      color: AppColor.milk,
      child: ClipPath(
        clipper: ShapeBorderClipper(
          shape: ContinuousRectangleBorder(
            borderRadius: AppShapes.radiusBottom(AppShapes.rLg),
          ),
        ),
        child: stage,
      ),
    );
  }

  Widget _playerContent({required String? poster, required double height}) {
    if (_videoError != null) {
      return Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 34, color: Colors.white70),
              const SizedBox(height: 10),
              Text(
                _videoError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 12.5,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 150,
                child: GradientButton(
                  label: 'تلاش دوباره',
                  height: 38,
                  fontSize: 12,
                  onPressed: () {
                    final lesson = _current;
                    if (lesson != null) _play(lesson);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    final chewie = _chewie;
    final video = _video;
    if (chewie != null && video != null && video.value.isInitialized) {
      return Center(
        key: const ValueKey('player'),
        child: AspectRatio(
          aspectRatio:
              video.value.aspectRatio == 0 ? 16 / 9 : video.value.aspectRatio,
          child: Chewie(controller: chewie),
        ),
      );
    }

    // پیش از آماده‌شدنِ ویدیو، همان تصویری که کاربر در فهرستِ دوره‌ها لمس
    // کرده بود با انتقالِ Hero اینجا می‌نشیند و بعد جایش را به پخش‌کننده
    // می‌دهد؛ صفحه هیچ لحظه‌ای خالی دیده نمی‌شود.
    return Stack(
      key: const ValueKey('poster'),
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'mycourse_${widget.myCourse.courseId}',
          child: AppNetworkImage(
            url: poster,
            fit: BoxFit.cover,
            fallbackAsset: 'assets/images/course_not_found.jpg',
          ),
        ),
        const DecoratedBox(decoration: BoxDecoration(color: Color(0x8C000000))),
        Center(
          child: _videoLoading
              ? const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: Colors.white),
                )
              : Icon(
                  Icons.play_circle_fill_rounded,
                  size: 58,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
        ),
      ],
    );
  }

  /// نوارِ شفافِ بالای ویدیو: بازگشت + عنوانِ درسِ در حالِ پخش.
  Widget _topBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xB3000000), Color(0x00000000)],
            ),
          ),
          child: Row(
            children: [
              _glassButton(
                icon: Icons.arrow_forward_rounded,
                tooltip: 'بازگشت',
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _current?.title ?? widget.myCourse.courseDetail.courseTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                      ),
                    ),
                    if (_current != null)
                      Text(
                        _current!.weekTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 10.5,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
              // در دسکتاپ فهرست همیشه در ستونِ کناری باز است.
              if (!AppBreakpoints.isDesktop(context)) ...[
                const SizedBox(width: 8),
                _glassButton(
                  icon: Icons.playlist_play_rounded,
                  tooltip: 'فهرست درس‌ها',
                  onTap: _openLessons,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: PressableScale(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: ShapeDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            shape: const CircleBorder(
              side: BorderSide(color: Colors.white24),
            ),
          ),
          child: Icon(icon, size: 19, color: Colors.white),
        ),
      ),
    );
  }

  /// بعد از پایانِ ویدیو: کارتِ درسِ بعدی با شمارشِ معکوس.
  Widget _nextUpOverlay(CourseLesson next) {
    return Positioned.fill(
      child: FadeSlideIn(
        duration: const Duration(milliseconds: 320),
        child: Container(
          color: const Color(0xD9000000),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'درس بعدی',
                style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                next.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 148,
                    child: GradientButton(
                      label: 'پخش ($_countdown)',
                      height: 40,
                      fontSize: 12.5,
                      icon: const Icon(Icons.play_arrow_rounded),
                      onPressed: () {
                        _cancelAutoNext();
                        _play(next);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  PressableScale(
                    onTap: _cancelAutoNext,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: ShapeDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: AppShapes.pill.copyWith(
                          side: const BorderSide(color: Colors.white24),
                        ),
                      ),
                      child: const Text(
                        'بی‌خیال',
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== محتوای زیرِ پخش‌کننده ====================

  /// کارتِ «در حالِ پخش»: عنوان، زمانِ زنده و کلیدهای درسِ قبلی/بعدی.
  Widget _nowPlayingCard() {
    final lesson = _current;
    if (lesson == null) return const SizedBox.shrink();
    final previous = _neighbour(-1);
    final next = _neighbour(1);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: const ShapeDecoration(
                  color: AppColor.pitchGreenSoft,
                  shape: AppShapes.pill,
                ),
                child: Text(
                  lesson.weekTitle,
                  style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColor.pitchGreen,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'درس ${lesson.flatIndex + 1} از ${_lessons.length}',
                style: const TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColor.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lesson.title,
            style: const TextStyle(
              fontFamily: 'Estedad',
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w800,
              color: AppColor.ink,
            ),
          ),
          const SizedBox(height: 10),
          _livePosition(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _stepButton(
                  label: 'درس قبلی',
                  icon: Icons.chevron_right_rounded,
                  onTap: previous == null ? null : () => _play(previous),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _stepButton(
                  label: 'درس بعدی',
                  icon: Icons.chevron_left_rounded,
                  onTap: next == null ? null : () => _play(next),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// نوارِ زمانِ ویدیو که مستقیم به کنترلرِ پخش گوش می‌دهد (بدون rebuildِ صفحه).
  Widget _livePosition() {
    final video = _video;
    // پیش از آماده‌شدنِ ویدیو همان ساختار با مقدارِ صفر کشیده می‌شود، وگرنه
    // با آماده‌شدن، ارتفاعِ کارت می‌پرد.
    if (video == null || !video.value.isInitialized) {
      return _timeline(Duration.zero, Duration.zero, 0);
    }
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: video,
      builder: (context, value, _) {
        final total = value.duration;
        final fraction = total.inMilliseconds == 0
            ? 0.0
            : (value.position.inMilliseconds / total.inMilliseconds)
                .clamp(0.0, 1.0);
        return _timeline(value.position, total, fraction);
      },
    );
  }

  Widget _timeline(Duration position, Duration total, double fraction) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: AppColor.cardMuted,
            color: AppColor.pitchGreen,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Text(
              _formatDuration(position),
              style: const TextStyle(
                fontFamily: 'Estedad',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColor.inkMuted,
              ),
            ),
            const Spacer(),
            Text(
              _formatDuration(total),
              style: const TextStyle(
                fontFamily: 'Estedad',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColor.inkMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return PressableScale(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: AppColor.cardMuted,
            shape: AppShapes.pill,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: AppColor.ink),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColor.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// کارتِ دوره: عنوان، مربی، حلقه‌ی پیشرفت و بج‌های خلاصه.
  Widget _courseCard() {
    final course = widget.myCourse;
    final detail = course.courseDetail;

    return ValueListenableBuilder<CourseProgress>(
      valueListenable: _progress,
      builder: (context, progress, _) {
        final total = _lessons.length;
        final seen =
            _lessons.where((l) => progress.isSeen(l.progressKey)).length;
        final fraction = total == 0 ? 0.0 : seen / total;

        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.courseTitle,
                          style: const TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 16.5,
                            height: 1.5,
                            fontWeight: FontWeight.w800,
                            color: AppColor.ink,
                          ),
                        ),
                        if (course.coach.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.person_rounded,
                                  size: 14, color: AppColor.inkMuted),
                              const SizedBox(width: 4),
                              Text(
                                course.coach,
                                style: const TextStyle(
                                  fontFamily: 'Estedad',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  _progressRing(fraction, seen, total),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  PillTag(
                    label: '${detail.weekCount} هفته',
                    icon: Icons.calendar_month_rounded,
                    color: AppColor.categoryBadge,
                    dense: true,
                  ),
                  PillTag(
                    label: '$total ویدیو',
                    icon: Icons.play_circle_outline_rounded,
                    color: AppColor.pitchGreen,
                    dense: true,
                  ),
                  if (detail.courseDuration > 0)
                    PillTag(
                      label: '${detail.courseDuration} ساعت',
                      icon: Icons.schedule_rounded,
                      color: AppColor.warning,
                      dense: true,
                    ),
                  if (detail.courseDifficulty.trim().isNotEmpty)
                    PillTag(
                      label: detail.courseDifficulty,
                      icon: Icons.trending_up_rounded,
                      color: AppColor.levelExpert,
                      dense: true,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Builder(builder: (context) {
                final target = _continueTarget;
                final resumable =
                    progress.of(target?.progressKey ?? '')?.resumable ?? false;
                return GradientButton(
                  label: target == null
                      ? 'درسی برای تماشا نیست'
                      : seen == total
                          ? 'تماشای دوباره‌ی دوره'
                          : resumable
                              ? 'ادامه از ${_formatDuration(progress.of(target.progressKey)!.position)}'
                              : 'ادامه‌ی تماشا',
                  height: 48,
                  icon: const Icon(Icons.play_arrow_rounded),
                  onPressed: target == null ? null : () => _play(target),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _progressRing(double fraction, int seen, int total) {
    return SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 62,
            height: 62,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                backgroundColor: AppColor.cardMuted,
                color: AppColor.pitchGreen,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '٪${(fraction * 100).round()}',
                style: const TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColor.ink,
                ),
              ),
              Text(
                '$seen/$total',
                style: const TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColor.inkMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// نوارِ افقیِ «بعدی‌ها» — دسترسیِ یک‌ضربه‌ای بدون بازکردنِ فهرست.
  Widget _upNextStrip() {
    return ValueListenableBuilder<CourseProgress>(
      valueListenable: _progress,
      builder: (context, progress, _) {
        final current = _current;
        final start = current == null ? 0 : current.flatIndex + 1;
        final upcoming = _lessons
            .skip(start)
            .where((l) => l.playable)
            .take(8)
            .toList();
        if (upcoming.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Row(
                children: [
                  const Text(
                    'در ادامه',
                    style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColor.ink,
                    ),
                  ),
                  const Spacer(),
                  PressableScale(
                    onTap: _openLessons,
                    child: const Row(
                      children: [
                        Text(
                          'همه‌ی درس‌ها',
                          style: TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColor.pitchGreen,
                          ),
                        ),
                        Icon(Icons.chevron_left_rounded,
                            size: 18, color: AppColor.pitchGreen),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: _kUpNextCardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: upcoming.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => FadeSlideIn(
                  delay: Duration(milliseconds: 40 * i),
                  child: _upNextCard(upcoming[i], progress),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _upNextCard(CourseLesson lesson, CourseProgress progress) {
    final watched = progress.of(lesson.progressKey);
    final fraction = watched?.fraction ?? 0;

    return PressableScale(
      onTap: () => _play(lesson),
      child: SizedBox(
        width: 176,
        child: Container(
          decoration: ShapeDecoration(
            color: AppColor.card,
            shape: AppShapes.border(AppShapes.rMd),
            shadows: AppColor.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SquircleClip(
                radius: AppShapes.rMd,
                child: SizedBox(
                  height: 88,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(
                        url: lesson.section.videoThumbnail,
                        fit: BoxFit.cover,
                        fallbackAsset: 'assets/images/course_not_found.jpg',
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(color: Color(0x33000000)),
                      ),
                      const Center(
                        child: Icon(Icons.play_arrow_rounded,
                            size: 28, color: Colors.white),
                      ),
                      if (fraction > 0)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 3,
                            backgroundColor: Colors.white24,
                            color: watched?.seen == true
                                ? AppColor.success
                                : AppColor.pitchGreenLight,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: AppColor.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.weekTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 10,
                        color: AppColor.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// معرفی دوره و پیش‌نیازها — جمع‌شونده تا صفحه شلوغ نشود.
  Widget _aboutCard() {
    final description = widget.myCourse.courseDescription.trim();
    final prerequisite =
        widget.myCourse.courseDetail.detail.preRequirement.trim();
    if (description.isEmpty && prerequisite.isEmpty) {
      return const SizedBox.shrink();
    }

    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 14),
          iconColor: AppColor.pitchGreen,
          collapsedIconColor: AppColor.inkMuted,
          title: const Text(
            'درباره‌ی این دوره',
            style: TextStyle(
              fontFamily: 'Estedad',
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColor.ink,
            ),
          ),
          children: [
            if (description.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 12.5,
                    height: 1.9,
                    color: AppColor.inkMuted,
                  ),
                ),
              ),
            if (prerequisite.isNotEmpty) ...[
              const SizedBox(height: 14),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'پیش‌نیاز',
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColor.ink,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  prerequisite,
                  style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 12.5,
                    height: 1.9,
                    color: AppColor.inkMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: AppColor.card,
          shape: AppShapes.border(AppShapes.rLg),
          shadows: AppColor.cardShadow,
        ),
        child: child,
      ),
    );
  }

  // ==================== ساخت صفحه ====================

  @override
  Widget build(BuildContext context) {
    final desktop = AppBreakpoints.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColor.milk,
      extendBodyBehindAppBar: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: desktop || _booting ? null : _lessonsFab(),
      body: _booting
          ? _CourseSkeleton(
              playerHeight: _playerHeight(context, desktop: desktop),
              desktop: desktop,
            )
          : desktop
              ? _desktopLayout()
              : _mobileLayout(),
    );
  }

  Widget _lessonsFab() {
    return ValueListenableBuilder<CourseProgress>(
      valueListenable: _progress,
      builder: (context, progress, _) {
        final seen =
            _lessons.where((l) => progress.isSeen(l.progressKey)).length;
        return FadeSlideIn(
          child: PressableScale(
            onTap: _openLessons,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: ShapeDecoration(
                gradient: AppColor.greenGradient,
                shape: AppShapes.pill,
                shadows: AppColor.greenShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.playlist_play_rounded,
                      color: AppColor.onPitchGreen, size: 21),
                  const SizedBox(width: 8),
                  const Text(
                    'فهرست درس‌ها',
                    style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColor.onPitchGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: ShapeDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: AppShapes.pill,
                    ),
                    child: Text(
                      '$seen/${_lessons.length}',
                      style: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColor.onPitchGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _mobileLayout() {
    final playerHeight = _playerHeight(context, desktop: false);
    final topPadding = MediaQuery.of(context).padding.top;

    return CustomScrollView(
      controller: _scroll,
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: playerHeight,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          flexibleSpace: Column(
            children: [
              Container(height: topPadding, color: Colors.black),
              _playerStage(height: playerHeight, rounded: true),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: FadeSlideIn(
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _nowPlayingCard(),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 70),
            child: _courseCard(),
          ),
        ),
        SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: _upNextStrip(),
          ),
        ),
        SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _aboutCard(),
            ),
          ),
        ),
        // جای دکمه‌ی شناورِ «فهرست درس‌ها»
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }

  /// دسکتاپ: پخش‌کننده و محتوا در ستونِ اصلی، فهرستِ درس‌ها همیشه باز در
  /// ستونِ کناری (باتم‌شیت روی ماوس معنا ندارد).
  Widget _desktopLayout() {
    final playerHeight = _playerHeight(context, desktop: true);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomScrollView(
                    controller: _scroll,
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      SliverAppBar(
                        pinned: true,
                        primary: false,
                        automaticallyImplyLeading: false,
                        backgroundColor: AppColor.milk,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        toolbarHeight: playerHeight,
                        flexibleSpace: SquircleClip(
                          radius: AppShapes.rLg,
                          child: _playerStage(
                              height: playerHeight, rounded: false),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: FadeSlideIn(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: _nowPlayingCard(),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: FadeSlideIn(
                          delay: const Duration(milliseconds: 70),
                          child: _courseCard(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: FadeSlideIn(
                          delay: const Duration(milliseconds: 140),
                          child: _aboutCard(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 400,
                  child: Container(
                    decoration: ShapeDecoration(
                      color: AppColor.card,
                      shape: AppShapes.border(AppShapes.rLg),
                      shadows: AppColor.cardShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                          child: Row(
                            children: [
                              const Text(
                                'فهرست درس‌ها',
                                style: TextStyle(
                                  fontFamily: 'Estedad',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColor.ink,
                                ),
                              ),
                              const Spacer(),
                              ValueListenableBuilder<CourseProgress>(
                                valueListenable: _progress,
                                builder: (context, progress, _) {
                                  final seen = _lessons
                                      .where(
                                          (l) => progress.isSeen(l.progressKey))
                                      .length;
                                  return Text(
                                    '$seen از ${_lessons.length}',
                                    style: const TextStyle(
                                      fontFamily: 'Estedad',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColor.inkMuted,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: CourseLessonList(
                            lessons: _lessons,
                            progress: _progress,
                            currentKey: _currentKey,
                            onPlay: _play,
                            onToggleSeen: _toggleSeen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '${d.inMinutes}:$seconds';
}

/// اسکلتونِ شیمرِ صفحه — دقیقاً هم‌ساختارِ چیدمانِ نهایی، تا لحظه‌ی
/// جایگزینی پرشِ لِی‌اوت دیده نشود.
class _CourseSkeleton extends StatelessWidget {
  const _CourseSkeleton({required this.playerHeight, required this.desktop});

  final double playerHeight;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: playerHeight, color: AppColor.cardMuted),
        const SizedBox(height: 22),
        _boneCard(
          children: const [
            Bone(width: 96, height: 20, radius: 999),
            SizedBox(height: 14),
            Bone(width: double.infinity, height: 15),
            SizedBox(height: 8),
            Bone(width: 180, height: 15),
            SizedBox(height: 18),
            Bone(width: double.infinity, height: 6, radius: 999),
            SizedBox(height: 20),
            Bone(width: double.infinity, height: 42, radius: 999),
          ],
        ),
        _boneCard(
          children: const [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Bone(width: double.infinity, height: 16),
                      SizedBox(height: 10),
                      Bone(width: 120, height: 12),
                    ],
                  ),
                ),
                SizedBox(width: 14),
                Bone.circle(size: 62),
              ],
            ),
            SizedBox(height: 18),
            Row(
              children: [
                Bone(width: 72, height: 22, radius: 999),
                SizedBox(width: 6),
                Bone(width: 66, height: 22, radius: 999),
                SizedBox(width: 6),
                Bone(width: 58, height: 22, radius: 999),
              ],
            ),
            SizedBox(height: 18),
            Bone(width: double.infinity, height: 48, radius: 999),
          ],
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Bone(width: 90, height: 16),
        ),
        SizedBox(
          height: _kUpNextCardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, __) => const Bone(
              width: 176,
              height: _kUpNextCardHeight,
              radius: AppShapes.rMd * 1.7,
            ),
          ),
        ),
      ],
    );

    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: desktop
            ? Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 20),
                    const SizedBox(
                      width: 400,
                      child: Bone(height: 620, radius: AppShapes.rLg * 1.7),
                    ),
                  ],
                ),
              )
            : content,
      ),
    );
  }

  /// کارتِ اسکلتون بدونِ پس‌زمینه‌ی سفید: شیمر با BlendMode.srcATop رنگِ
  /// هر پیکسلِ مات را عوض می‌کند، پس اگر کارت پس‌زمینه داشته باشد استخوان‌ها
  /// در آن حل می‌شوند و اسکلتون یک بلوکِ یک‌دستِ خاکستری دیده می‌شود.
  Widget _boneCard({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
