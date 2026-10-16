// lib/views/widgets/player/glass_video_player.dart
//
// پخش‌کننده‌ی دوره: ویدیو + کنترل‌های شیشه‌ای، و مدیریتِ تمام‌صفحه.
//
// تمام‌صفحه یک مسیرِ جدا روی ناوبریِ ریشه است که همان مدل را می‌گیرد؛ پس
// کیفیت، سرعت، درسِ بعدی و ذخیره‌ی پیشرفت همه وسطِ تمام‌صفحه هم کار
// می‌کنند. روی وب علاوه بر آن، خودِ مرورگر هم تمام‌صفحه می‌شود و Esc ـِ
// مرورگر مسیر را می‌بندد. روی وب عنصرِ ویدیو فقط یک‌جا می‌تواند باشد، پس
// کادرِ کوچک هنگامِ تمام‌صفحه کاور را نشان می‌دهد.
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'package:persian_ball/views/widgets/app_network_image.dart';
import 'package:persian_ball/views/widgets/player/browser_fullscreen.dart';
import 'package:persian_ball/views/widgets/player/glass_player_model.dart';
import 'package:persian_ball/views/widgets/player/glass_surface.dart';
import 'package:persian_ball/views/widgets/player/glass_video_controls.dart';

class GlassVideoPlayer extends StatelessWidget {
  const GlassVideoPlayer({
    super.key,
    required this.model,
    this.heroTag,
    this.posterFallbackAsset = 'assets/images/course_not_found.jpg',
  });

  final GlassPlayerModel model;

  /// همان تگی که کارتِ فهرستِ دوره‌ها دارد؛ کاور با Hero می‌آید.
  final Object? heroTag;
  final String posterFallbackAsset;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: model,
      builder: (context, _) {
        final v = model.video;
        final bool ready = v != null && v.value.isInitialized;
        final bool showVideo = ready && !model.fullscreen;
        return ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!showVideo)
                _Poster(
                    url: model.poster,
                    heroTag: heroTag,
                    fallbackAsset: posterFallbackAsset),
              if (showVideo) _Video(controller: v),
              if (model.fullscreen)
                _FullscreenNotice(onReturn: () => BrowserFullscreen.exit())
              else
                GlassVideoControls(
                  model: model,
                  fullscreen: false,
                  onToggleFullscreen: () => enterGlassFullscreen(context, model),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// ورود به تمام‌صفحه؛ تا خروج صبر می‌کند و بعد همه‌چیز را برمی‌گرداند.
Future<void> enterGlassFullscreen(
    BuildContext context, GlassPlayerModel model) async {
  if (model.fullscreen) return;
  model.setFullscreen(true);
  if (kIsWeb) {
    // ignore: unawaited_futures
    BrowserFullscreen.enter();
  } else {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  await Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: true,
      fullscreenDialog: true,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => _GlassFullscreenPage(model: model),
      transitionsBuilder: (_, a, __, child) {
        final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );

  if (kIsWeb) {
    // ignore: unawaited_futures
    BrowserFullscreen.exit();
  } else {
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
  }
  model.setFullscreen(false);
}

class _GlassFullscreenPage extends StatefulWidget {
  const _GlassFullscreenPage({required this.model});
  final GlassPlayerModel model;

  @override
  State<_GlassFullscreenPage> createState() => _GlassFullscreenPageState();
}

class _GlassFullscreenPageState extends State<_GlassFullscreenPage> {
  void Function()? _unlisten;

  @override
  void initState() {
    super.initState();
    // Esc یا دکمه‌ی خودِ مرورگر: مسیرِ فلاتری هم بسته شود
    _unlisten = BrowserFullscreen.listen(() {
      if (!BrowserFullscreen.isActive && mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    _unlisten?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: AnimatedBuilder(
          animation: model,
          builder: (context, _) {
            final v = model.video;
            final bool ready = v != null && v.value.isInitialized;
            return Stack(
              fit: StackFit.expand,
              children: [
                if (ready)
                  _Video(controller: v)
                else
                  _Poster(url: model.poster, heroTag: null, fallbackAsset: 'assets/images/course_not_found.jpg'),
                GlassVideoControls(
                  model: model,
                  fullscreen: true,
                  onToggleFullscreen: () => Navigator.of(context).maybePop(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Video extends StatelessWidget {
  const _Video({required this.controller});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final ar = controller.value.aspectRatio;
    return Center(
      child: AspectRatio(
        aspectRatio: ar == 0 ? 16 / 9 : ar,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster(
      {required this.url, required this.heroTag, required this.fallbackAsset});
  final String? url;
  final Object? heroTag;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    final img = AppNetworkImage(
      url: url,
      fit: BoxFit.cover,
      fallbackAsset: fallbackAsset,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        heroTag == null ? img : Hero(tag: heroTag!, child: img),
        const DecoratedBox(
            decoration: BoxDecoration(color: Color(0x99000000))),
      ],
    );
  }
}

/// کادرِ کوچک وقتی تمام‌صفحه باز است.
class _FullscreenNotice extends StatelessWidget {
  const _FullscreenNotice({required this.onReturn});
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassSurface(
        circle: true,
        tint: 0.45,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fullscreen_rounded, size: 18, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'در حالِ پخشِ تمام‌صفحه',
              style: TextStyle(
                fontFamily: 'Estedad',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
