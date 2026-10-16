// lib/views/widgets/player/glass_video_controls.dart
//
// کنترل‌های پخش‌کننده‌ی دوره، به سبکِ «شیشه‌ی مایع». یک ویجت برای کادرِ
// کوچک و تمام‌صفحه؛ فقط اندازه‌ها با ارتفاعِ موجود عوض می‌شود.
//
// چیدمان:
//   بالا (RTL):  بازگشت/خروج  ·  عنوان و هفته  ·  قرصِ کیفیت  ·  قرصِ سرعت  ·  فهرست
//   وسط  (LTR):  درسِ قبلی  ·  ۱۰− ·  پخش/توقف  ·  ۱۰+  ·  درسِ بعدی
//   پایین (LTR): زمان  ·  نوارِ جست‌وجو  ·  کل  ·  صدا  ·  تمام‌صفحه
//
// کنترل‌های رسانه (وسط و پایین) عمداً چپ‌به‌راست‌اند: «قبلی» سمتِ چپ و
// نوارِ پیشرفت از چپ پر می‌شود، همان قراردادی که همه‌ی پخش‌کننده‌ها دارند.
// بعد از ۳ ثانیه بی‌حرکتی هنگامِ پخش پنهان می‌شوند؛ ضربه/حرکتِ موس
// برمی‌گرداند؛ ضربه‌ی دوتایی روی دو سومِ کناری ±۱۰ ثانیه.
import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:persian_ball/constant/app_breakpoints.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/services/hls_quality.dart';
import 'package:persian_ball/views/widgets/motion.dart';
import 'package:persian_ball/views/widgets/player/glass_player_model.dart';
import 'package:persian_ball/views/widgets/player/glass_surface.dart';

class GlassVideoControls extends StatefulWidget {
  const GlassVideoControls({
    super.key,
    required this.model,
    required this.fullscreen,
    required this.onToggleFullscreen,
  });

  final GlassPlayerModel model;
  final bool fullscreen;
  final VoidCallback onToggleFullscreen;

  @override
  State<GlassVideoControls> createState() => _GlassVideoControlsState();
}

enum _Menu { none, quality, speed }

class _GlassVideoControlsState extends State<GlassVideoControls> {
  static const Duration _hideAfter = Duration(milliseconds: 3200);
  static const Duration _fade = Duration(milliseconds: 220);

  bool _visible = true;
  Timer? _hide;
  _Menu _menu = _Menu.none;

  bool _scrubbing = false;
  Duration _scrubTo = Duration.zero;

  /// ۱+ / ۱− وقتی پرشِ ۱۰ ثانیه‌ای انجام شد (نشانگرِ لحظه‌ای)
  int _flashDir = 0;
  Timer? _flashTimer;

  bool _wasPlaying = false;
  final FocusNode _focus = FocusNode(debugLabel: 'glass-player');

  GlassPlayerModel get m => widget.model;

  @override
  void initState() {
    super.initState();
    m.addListener(_onModel);
    _wasPlaying = m.isPlaying;
    _scheduleHide();
  }

  @override
  void didUpdateWidget(covariant GlassVideoControls old) {
    super.didUpdateWidget(old);
    if (!identical(old.model, widget.model)) {
      old.model.removeListener(_onModel);
      widget.model.addListener(_onModel);
    }
  }

  @override
  void dispose() {
    m.removeListener(_onModel);
    _hide?.cancel();
    _flashTimer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  void _onModel() {
    if (!mounted) return;
    final playing = m.isPlaying;
    if (playing != _wasPlaying) {
      _wasPlaying = playing;
      playing ? _scheduleHide() : _show();
    }
    setState(() {});
  }

  /// وقتی چیزی باز است یا پخش نمی‌شود، کنترل‌ها نمی‌روند.
  bool get _pinned =>
      _menu != _Menu.none ||
      _scrubbing ||
      !m.isPlaying ||
      m.loading ||
      m.error != null ||
      m.nextUpTitle != null;

  void _scheduleHide() {
    _hide?.cancel();
    _hide = Timer(_hideAfter, () {
      if (!mounted || _pinned) return;
      setState(() => _visible = false);
    });
  }

  void _show() {
    _hide?.cancel();
    if (!_visible) setState(() => _visible = true);
    _scheduleHide();
  }

  void _toggle() {
    if (_menu != _Menu.none) {
      setState(() => _menu = _Menu.none);
      _scheduleHide();
      return;
    }
    if (_visible && m.isPlaying) {
      _hide?.cancel();
      setState(() => _visible = false);
    } else {
      _show();
    }
  }

  void _openMenu(_Menu menu) {
    _hide?.cancel();
    setState(() {
      _visible = true;
      _menu = _menu == menu ? _Menu.none : menu;
    });
    if (_menu == _Menu.none) _scheduleHide();
  }

  void _closeMenu() {
    setState(() => _menu = _Menu.none);
    _scheduleHide();
  }

  void _skip(int dir) {
    if (!m.isReady) return;
    m.seekBy(Duration(seconds: 10 * dir));
    _flashTimer?.cancel();
    setState(() => _flashDir = dir);
    _flashTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _flashDir = 0);
    });
    _show();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.keyK) {
      m.togglePlay();
      _show();
    } else if (k == LogicalKeyboardKey.arrowRight) {
      _skip(1);
    } else if (k == LogicalKeyboardKey.arrowLeft) {
      _skip(-1);
    } else if (k == LogicalKeyboardKey.keyM) {
      m.toggleMute();
      _show();
    } else if (k == LogicalKeyboardKey.keyF) {
      widget.onToggleFullscreen();
    } else if (k == LogicalKeyboardKey.escape) {
      if (_menu != _Menu.none) {
        _closeMenu();
      } else if (widget.fullscreen) {
        widget.onToggleFullscreen();
      } else {
        return KeyEventResult.ignored;
      }
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // ───────────────────────── ساخت

  @override
  Widget build(BuildContext context) {
    final bool showUi = _visible || _pinned;
    return LayoutBuilder(builder: (context, c) {
      final bool compact = c.maxHeight < 280;
      final bool desktop = AppBreakpoints.isDesktop(context);
      final bool booting = m.loading || (!m.isReady && m.error == null);

      return Focus(
        focusNode: _focus,
        autofocus: widget.fullscreen,
        onKeyEvent: _onKey,
        child: MouseRegion(
          onHover: (_) {
            if (!_visible) _show();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // لایه‌ی ضربه: تک‌ضربه نمایش/پنهان، دوضربه ±۱۰ یا پخش/توقف
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggle,
                onDoubleTapDown: (d) {
                  final dx = d.localPosition.dx;
                  if (dx < c.maxWidth * 0.34) {
                    _skip(-1);
                  } else if (dx > c.maxWidth * 0.66) {
                    _skip(1);
                  } else {
                    m.togglePlay();
                    _show();
                  }
                },
                onDoubleTap: () {},
              ),

              // تاریکیِ ملایمِ بالا و پایین تا متن روی ویدیوی روشن هم خوانا باشد
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: showUi ? 1 : 0,
                  duration: _fade,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x8C000000),
                          Color(0x00000000),
                          Color(0x00000000),
                          Color(0xA6000000),
                        ],
                        stops: [0, 0.3, 0.6, 1],
                      ),
                    ),
                  ),
                ),
              ),

              // در حالِ آماده‌سازی: فقط اسپینر
              if (booting)
                const Center(
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  ),
                ),

              // نشانگرِ ±۱۰
              if (_flashDir != 0)
                Align(
                  alignment: Alignment(_flashDir * 0.55, 0),
                  child: _SeekFlash(dir: _flashDir),
                ),

              // رابط
              AnimatedOpacity(
                opacity: showUi ? 1 : 0,
                duration: _fade,
                child: IgnorePointer(
                  ignoring: !showUi,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          bottom: false,
                          child: _topBar(compact, desktop),
                        ),
                      ),
                      if (!booting && m.error == null && m.nextUpTitle == null)
                        Center(child: _centerControls(compact)),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: SafeArea(
                          top: false,
                          child: _bottomBar(compact),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (m.error != null) Center(child: _errorCard()),

              if (m.nextUpTitle != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: compact ? 60 : 78,
                  child: Center(child: _nextUpToast()),
                ),

              if (_menu != _Menu.none) ..._menuLayer(compact),
            ],
          ),
        ),
      );
    });
  }

  // ───────────────────────── نوارِ بالا (RTL)

  Widget _topBar(bool compact, bool desktop) {
    final double btn = compact ? 34 : 38;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Row(
        children: [
          GlassIconButton(
            icon: widget.fullscreen
                ? Icons.fullscreen_exit_rounded
                : Icons.arrow_back_rounded,
            tooltip: widget.fullscreen ? 'خروج از تمام‌صفحه' : 'بازگشت',
            size: btn,
            onTap: () {
              if (widget.fullscreen) {
                widget.onToggleFullscreen();
              } else {
                m.onBack?.call();
              }
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  m.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: compact ? 12.5 : 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: const [
                      Shadow(blurRadius: 8, color: Colors.black54)
                    ],
                  ),
                ),
                if ((m.subtitle ?? '').isNotEmpty)
                  Text(
                    m.subtitle!,
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
          const SizedBox(width: 8),
          if (m.variants.isNotEmpty) ...[
            GlassPill(
              icon: Icons.tune_rounded,
              label: m.quality?.label ?? 'خودکار',
              active: _menu == _Menu.quality,
              busy: m.switchingQuality,
              onTap: () => _openMenu(_Menu.quality),
            ),
            const SizedBox(width: 6),
          ],
          GlassPill(
            icon: Icons.speed_rounded,
            label: _speedLabel(m.speed),
            active: _menu == _Menu.speed,
            onTap: () => _openMenu(_Menu.speed),
          ),
          // در دسکتاپِ غیرِ تمام‌صفحه فهرست همیشه در ستونِ کناری باز است
          if (m.onLessons != null && (widget.fullscreen || !desktop)) ...[
            const SizedBox(width: 6),
            GlassIconButton(
              icon: Icons.playlist_play_rounded,
              tooltip: 'فهرست درس‌ها',
              size: btn,
              onTap: () {
                _closeMenu();
                m.onLessons!();
              },
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────── کنترل‌های وسط (LTR)

  Widget _centerControls(bool compact) {
    final double big = compact ? 56 : 70;
    final double small = compact ? 38 : 46;
    final double gapIn = compact ? 12 : 20;
    final double gapOut = compact ? 8 : 14;
    final bool ended = m.isEnded;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassIconButton(
            icon: Icons.skip_previous_rounded,
            tooltip: 'درس قبلی',
            size: small,
            enabled: m.hasPrevious && m.onPrevious != null,
            onTap: () => m.onPrevious?.call(),
          ),
          SizedBox(width: gapOut),
          GlassIconButton(
            icon: Icons.replay_10_rounded,
            tooltip: '۱۰ ثانیه عقب',
            size: small,
            onTap: () => _skip(-1),
          ),
          SizedBox(width: gapIn),
          GlassIconButton(
            icon: ended
                ? Icons.replay_rounded
                : (m.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded),
            tooltip: ended ? 'پخشِ دوباره' : (m.isPlaying ? 'توقف' : 'پخش'),
            size: big,
            emphasis: true,
            child: m.isBuffering && m.isPlaying
                ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  )
                : null,
            onTap: () {
              m.togglePlay();
              _show();
            },
          ),
          SizedBox(width: gapIn),
          GlassIconButton(
            icon: Icons.forward_10_rounded,
            tooltip: '۱۰ ثانیه جلو',
            size: small,
            onTap: () => _skip(1),
          ),
          SizedBox(width: gapOut),
          GlassIconButton(
            icon: Icons.skip_next_rounded,
            tooltip: 'درس بعدی',
            size: small,
            enabled: m.hasNext && m.onNext != null,
            onTap: () => m.onNext?.call(),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── نوارِ پایین (LTR)

  Widget _bottomBar(bool compact) {
    final Duration pos = _scrubbing ? _scrubTo : m.position;
    final Duration dur = m.duration;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: GlassSurface(
          radius: 16,
          padding: EdgeInsets.fromLTRB(12, compact ? 4 : 6, 6, compact ? 4 : 6),
          child: Row(
            children: [
              _time(pos),
              const SizedBox(width: 10),
              Expanded(
                child: _GlassSeekBar(
                  position: pos,
                  duration: dur,
                  buffered: m.buffered,
                  enabled: m.isReady && dur > Duration.zero,
                  scrubbing: _scrubbing,
                  onStart: () {
                    _hide?.cancel();
                    setState(() {
                      _scrubbing = true;
                      _scrubTo = m.position;
                    });
                  },
                  onChanged: (d) => setState(() => _scrubTo = d),
                  onEnd: (d) {
                    setState(() => _scrubbing = false);
                    m.seekTo(d);
                    _scheduleHide();
                  },
                ),
              ),
              const SizedBox(width: 10),
              _time(dur, dim: true),
              const SizedBox(width: 2),
              _BarIcon(
                icon: m.muted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                tooltip: m.muted ? 'روشن کردنِ صدا' : 'بی‌صدا',
                onTap: () {
                  m.toggleMute();
                  _show();
                },
              ),
              _BarIcon(
                icon: widget.fullscreen
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
                tooltip: widget.fullscreen ? 'خروج از تمام‌صفحه' : 'تمام‌صفحه',
                onTap: widget.onToggleFullscreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _time(Duration d, {bool dim = false}) => Text(
        fmtDuration(d),
        style: TextStyle(
          fontFamily: 'Estedad',
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: dim ? Colors.white60 : Colors.white,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );

  // ───────────────────────── منوها

  List<Widget> _menuLayer(bool compact) {
    final bool quality = _menu == _Menu.quality;
    final List<_MenuItem> items = quality
        ? [
            for (final v in m.variants.reversed)
              _MenuItem(
                label: v.label,
                hint: _qualityHint(v),
                selected: m.quality?.height == v.height,
                onTap: () => m.selectQuality(v),
              ),
            _MenuItem(
              label: 'خودکار',
              hint: 'بر اساسِ سرعتِ اینترنت',
              selected: m.quality == null,
              onTap: () => m.selectQuality(null),
            ),
          ]
        : [
            for (final s in GlassPlayerModel.speeds)
              _MenuItem(
                label: _speedLabel(s),
                hint: s == 1 ? 'عادی' : null,
                selected: m.speed == s,
                onTap: () => m.setSpeed(s),
              ),
          ];
    return [
      // بیرونِ منو → بستن
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _closeMenu,
          child: const SizedBox.expand(),
        ),
      ),
      // قرص‌ها در RTL سمتِ چپِ نوارِ بالا هستند؛ منو زیرِ همان‌ها
      Positioned(
        top: compact ? 52 : 58,
        left: 12,
        child: _GlassMenu(
          title: quality ? 'کیفیت ویدیو' : 'سرعت پخش',
          items: items,
          onPicked: _closeMenu,
          maxHeight: compact ? 150 : 260,
        ),
      ),
    ];
  }

  static String? _qualityHint(HlsVariant v) {
    if (v.height >= 1080) return 'Full HD';
    if (v.height >= 720) return 'HD';
    if (v.height <= 240) return 'کم‌حجم';
    return null;
  }

  static String _speedLabel(double s) {
    final String n = s == s.roundToDouble()
        ? s.toInt().toString()
        : s.toString();
    return '${faDigits(n).replaceAll('.', '٫')}×';
  }

  // ───────────────────────── خطا و درسِ بعدی

  Widget _errorCard() {
    return GlassSurface(
      radius: 18,
      tint: 0.5,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 30, color: Colors.white70),
            const SizedBox(height: 8),
            Text(
              m.error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Estedad',
                fontSize: 12.5,
                height: 1.6,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _GreenPill(
              label: 'تلاش دوباره',
              icon: Icons.refresh_rounded,
              onTap: m.onRetry,
            ),
          ],
        ),
      ),
    );
  }

  Widget _nextUpToast() {
    final int total = m.nextUpTotal <= 0 ? 1 : m.nextUpTotal;
    return GlassSurface(
      radius: 18,
      tint: 0.5,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: m.nextUpCountdown / total),
                    duration: const Duration(milliseconds: 900),
                    builder: (_, v, __) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: 2.5,
                      color: AppColor.pitchGreenLight,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  Text(
                    faDigits('${m.nextUpCountdown}'),
                    style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'درس بعدی',
                    style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 10.5,
                      color: Colors.white60,
                    ),
                  ),
                  Text(
                    m.nextUpTitle ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _GreenPill(
              label: 'پخش',
              icon: Icons.play_arrow_rounded,
              onTap: m.onPlayNextNow,
            ),
            const SizedBox(width: 6),
            GlassIconButton(
              icon: Icons.close_rounded,
              tooltip: 'بی‌خیال',
              size: 30,
              onTap: () => m.onCancelNext?.call(),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── اجزای کوچک

class _BarIcon extends StatelessWidget {
  const _BarIcon({required this.icon, required this.tooltip, this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 21, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _GreenPill extends StatelessWidget {
  const _GreenPill({required this.label, required this.icon, this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.94,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const ShapeDecoration(
          gradient: AppColor.greenGradient,
          shape: StadiumBorder(),
          shadows: AppColor.greenShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: AppColor.onPitchGreen),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Estedad',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColor.onPitchGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeekFlash extends StatelessWidget {
  const _SeekFlash({required this.dir});
  final int dir;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeSlideIn(
        duration: const Duration(milliseconds: 180),
        child: GlassSurface(
          circle: true,
          tint: 0.4,
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(dir < 0 ? Icons.replay_10_rounded : Icons.forward_10_rounded,
                  size: 30, color: Colors.white),
              const Text(
                '۱۰ ثانیه',
                style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.hint,
  });
  final String label;
  final String? hint;
  final bool selected;
  final VoidCallback onTap;
}

class _GlassMenu extends StatelessWidget {
  const _GlassMenu({
    required this.title,
    required this.items,
    required this.onPicked,
    required this.maxHeight,
  });

  final String title;
  final List<_MenuItem> items;
  final VoidCallback onPicked;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      duration: const Duration(milliseconds: 180),
      child: GlassSurface(
        radius: 16,
        tint: 0.55,
        blur: 22,
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
        child: SizedBox(
          width: 210,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white60,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [for (final it in items) _row(it)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(_MenuItem it) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          it.onTap();
          onPicked();
        },
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: it.selected
                ? AppColor.pitchGreen.withValues(alpha: 0.28)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: it.selected
                    ? const Icon(Icons.check_rounded,
                        size: 18, color: AppColor.pitchGreenLight)
                    : null,
              ),
              const SizedBox(width: 6),
              Text(
                it.label,
                style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 13,
                  fontWeight: it.selected ? FontWeight.w800 : FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              if (it.hint != null) ...[
                const Spacer(),
                Text(
                  it.hint!,
                  style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 10.5,
                    color: Colors.white54,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// نوارِ جست‌وجوی شیشه‌ای: مسیرِ پخش‌شده با گرادیانِ سبز، بافر روشن‌تر، دستگیره‌ی
/// سفید که هنگامِ کشیدن بزرگ می‌شود و زمان را بالای خودش نشان می‌دهد.
class _GlassSeekBar extends StatelessWidget {
  const _GlassSeekBar({
    required this.position,
    required this.duration,
    required this.buffered,
    required this.enabled,
    required this.scrubbing,
    required this.onStart,
    required this.onChanged,
    required this.onEnd,
  });

  final Duration position, duration, buffered;
  final bool enabled, scrubbing;
  final VoidCallback onStart;
  final ValueChanged<Duration> onChanged;
  final ValueChanged<Duration> onEnd;

  double get _frac => duration <= Duration.zero
      ? 0
      : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

  Duration _at(double dx, double width) {
    final f = (dx / width).clamp(0.0, 1.0);
    return Duration(milliseconds: (duration.inMilliseconds * f).round());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final double w = c.maxWidth;
      return Semantics(
        slider: true,
        value: fmtDuration(position),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: enabled ? (_) => onStart() : null,
          onHorizontalDragUpdate:
              enabled ? (d) => onChanged(_at(d.localPosition.dx, w)) : null,
          onHorizontalDragEnd: enabled
              ? (_) => onEnd(position)
              : null,
          onTapDown: enabled ? (_) => onStart() : null,
          onTapUp: enabled ? (d) => onEnd(_at(d.localPosition.dx, w)) : null,
          child: SizedBox(
            height: 32,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SeekPainter(
                      frac: _frac,
                      buffered: duration <= Duration.zero
                          ? 0
                          : (buffered.inMilliseconds / duration.inMilliseconds)
                              .clamp(0.0, 1.0),
                      scrubbing: scrubbing,
                      enabled: enabled,
                    ),
                  ),
                ),
                if (scrubbing)
                  Positioned(
                    left: (_frac * w - 26).clamp(0.0, w - 52),
                    top: -30,
                    child: GlassSurface(
                      radius: 8,
                      tint: 0.6,
                      shadow: false,
                      highlight: false,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      child: Text(
                        fmtDuration(position),
                        style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _SeekPainter extends CustomPainter {
  _SeekPainter({
    required this.frac,
    required this.buffered,
    required this.scrubbing,
    required this.enabled,
  });

  final double frac, buffered;
  final bool scrubbing, enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final double h = scrubbing ? 6 : 4;
    final double y = size.height / 2;
    final double r = h / 2;
    final track = RRect.fromLTRBR(0, y - r, size.width, y + r, Radius.circular(r));
    canvas.drawRRect(track, Paint()..color = Colors.white.withValues(alpha: 0.22));
    if (buffered > 0) {
      canvas.drawRRect(
        RRect.fromLTRBR(0, y - r, size.width * buffered, y + r, Radius.circular(r)),
        Paint()..color = Colors.white.withValues(alpha: 0.32),
      );
    }
    final double px = size.width * frac;
    if (px > 0) {
      final played = Rect.fromLTRB(0, y - r, px, y + r);
      canvas.drawRRect(
        RRect.fromRectAndRadius(played, Radius.circular(r)),
        Paint()
          ..shader = const LinearGradient(
            colors: [AppColor.pitchGreenLight, AppColor.pitchGreen],
          ).createShader(Rect.fromLTRB(0, 0, size.width, 1)),
      );
    }
    if (!enabled) return;
    final double tr = scrubbing ? 9 : 6.5;
    // هاله
    canvas.drawCircle(
      Offset(px, y),
      tr + 6,
      Paint()..color = AppColor.pitchGreenLight.withValues(alpha: scrubbing ? 0.28 : 0.16),
    );
    canvas.drawCircle(Offset(px, y), tr, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(px, y),
      tr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColor.pitchGreen,
    );
  }

  @override
  bool shouldRepaint(_SeekPainter o) =>
      o.frac != frac ||
      o.buffered != buffered ||
      o.scrubbing != scrubbing ||
      o.enabled != enabled;
}

// ───────────────────────── کمکی‌ها

String faDigits(String s) {
  const d = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  return s.split('').map((c) {
    final i = c.codeUnitAt(0) - 48;
    return (i >= 0 && i <= 9) ? d[i] : c;
  }).join();
}

/// «۰۴:۳۲» و با ساعت «۱:۰۴:۳۲»
String fmtDuration(Duration d) {
  if (d < Duration.zero) d = Duration.zero;
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return faDigits(h > 0 ? '$h:$m:$s' : '$m:$s');
}
