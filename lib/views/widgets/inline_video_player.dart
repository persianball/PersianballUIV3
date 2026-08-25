import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:video_player/video_player.dart';

/// پخش‌کننده‌ی ویدیو *داخل* قاب تصویر محصول (نه دیالوگ جدا).
/// وقتی آیتم ویدیو از ریل تامبنیل انتخاب شود، همین ویجت جای تصویر اصلی
/// می‌نشیند و ویدیو را در همان کادر پخش می‌کند.
class InlineVideoPlayer extends StatefulWidget {
  const InlineVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = true,
  });

  final String videoUrl;
  final bool autoPlay;

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant InlineVideoPlayer old) {
    super.didUpdateWidget(old);
    if (old.videoUrl != widget.videoUrl) {
      _dispose();
      _init();
    }
  }

  Future<void> _init() async {
    try {
      final vc = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await vc.initialize();
      if (!mounted) {
        vc.dispose();
        return;
      }
      final cc = ChewieController(
        videoPlayerController: vc,
        autoPlay: widget.autoPlay,
        looping: true,
        aspectRatio: vc.value.aspectRatio,
        // تمام‌صفحه هم پورتریت می‌ماند
        deviceOrientationsOnEnterFullScreen: const [
          DeviceOrientation.portraitUp,
        ],
        deviceOrientationsAfterFullScreen: const [
          DeviceOrientation.portraitUp,
        ],
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColor.pitchGreen,
          handleColor: AppColor.pitchGreen,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white54,
        ),
      );
      setState(() {
        _video = vc;
        _chewie = cc;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'پخش این ویدیو ممکن نیست');
    }
  }

  void _dispose() {
    _chewie?.dispose();
    _video?.dispose();
    _chewie = null;
    _video = null;
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(
              fontFamily: 'Estedad', fontSize: 12, color: AppColor.inkMuted),
        ),
      );
    }
    if (_chewie == null) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColor.pitchGreen),
        ),
      );
    }
    // نکته: روی وب، ویدیو یک PlatformView است و اگر داخل ClipPath اضافه‌ای
    // قرار بگیرد ممکن است نامرئی شود؛ پس اینجا برش اضافه نمی‌گذاریم.
    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: _video!.value.aspectRatio,
          child: Chewie(controller: _chewie!),
        ),
      ),
    );
  }
}
