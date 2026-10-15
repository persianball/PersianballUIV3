// lib/views/widgets/slider_video.dart
//
// ویدیوی اسلایدرِ خانه. اسلایدر یک «ویترین» است نه پخش‌کننده: نوارِ پخش،
// دکمه‌ی توقف و تمام‌صفحه‌ی Chewie اینجا فقط شلوغی بود. ویدیو بی‌صدا و
// خودکار پخش می‌شود، کلِ کادر را پر می‌کند (وسط‌چین، لبه‌های اضافه بریده
// می‌شوند) و تنها کنترل یک دکمه‌ی صدا در گوشه‌ی بالا-راست است.
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:persian_ball/constant/app_color.dart';

class SliderVideo extends StatefulWidget {
  const SliderVideo({
    super.key,
    required this.videoUrl,
    this.looping = false,
    this.onCompleted,
  });

  final String videoUrl;

  /// برای اسلایدری که بعدِ پایانِ ویدیو جلو می‌رود باید false باشد.
  final bool looping;

  /// یک‌بار، وقتی پخش به انتهای ویدیو رسید.
  final VoidCallback? onCompleted;

  @override
  State<SliderVideo> createState() => _SliderVideoState();
}

class _SliderVideoState extends State<SliderVideo> {
  VideoPlayerController? _video;
  bool _failed = false;
  bool _completed = false;

  /// پخشِ خودکار در مرورگر فقط بی‌صدا مجاز است؛ صدا را کاربر باز می‌کند.
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant SliderVideo old) {
    super.didUpdateWidget(old);
    if (old.videoUrl != widget.videoUrl) {
      _disposeVideo();
      _completed = false;
      _failed = false;
      _init();
    }
  }

  Future<void> _init() async {
    final vc = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await vc.initialize();
      if (!mounted) {
        vc.dispose();
        return;
      }
      await vc.setVolume(_muted ? 0 : 1);
      await vc.setLooping(widget.looping);
      vc.addListener(_onTick);
      setState(() => _video = vc);
      await vc.play();
    } catch (_) {
      vc.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  /// video_player رویدادِ «تمام شد» ندارد؛ از روی موقعیت تشخیص داده می‌شود.
  void _onTick() {
    final v = _video?.value;
    if (v == null || !v.isInitialized || _completed || widget.looping) return;
    if (v.duration > Duration.zero && v.position >= v.duration) {
      _completed = true;
      widget.onCompleted?.call();
    }
  }

  void _toggleMute() {
    final vc = _video;
    if (vc == null) return;
    setState(() => _muted = !_muted);
    vc.setVolume(_muted ? 0 : 1);
  }

  void _disposeVideo() {
    _video?.removeListener(_onTick);
    _video?.dispose();
    _video = null;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc = _video;
    if (_failed) return const ColoredBox(color: Colors.black);
    if (vc == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColor.pitchGreen),
          ),
        ),
      );
    }

    final Size size = vc.value.size;
    return Stack(
      fit: StackFit.expand,
      children: [
        // cover + وسط‌چین: کادر کامل پر می‌شود و نوارِ سیاهِ کناری نمی‌ماند
        ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.center,
            child: SizedBox(
              width: size.width > 0 ? size.width : 16,
              height: size.height > 0 ? size.height : 9,
              child: VideoPlayer(vc),
            ),
          ),
        ),
        // «بالا-راست» یعنی راستِ فیزیکی، نه شروعِ متن؛ پس Positioned.right
        Positioned(
          top: 12,
          right: 12,
          child: _MuteButton(muted: _muted, onTap: _toggleMute),
        ),
      ],
    );
  }
}

class _MuteButton extends StatelessWidget {
  const _MuteButton({required this.muted, required this.onTap});

  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: muted ? 'روشن کردنِ صدا' : 'قطعِ صدا',
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white24),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, a) =>
                  ScaleTransition(scale: a, child: child),
              child: Icon(
                muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                key: ValueKey(muted),
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
