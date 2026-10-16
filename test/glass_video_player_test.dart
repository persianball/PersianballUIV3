import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:persian_ball/services/hls_quality.dart';
import 'package:persian_ball/views/widgets/player/glass_player_model.dart';
import 'package:persian_ball/views/widgets/player/glass_video_controls.dart';
import 'package:persian_ball/views/widgets/player/glass_video_player.dart';

/// پلتفرمِ جعلی: VideoPlayerController واقعی را «آماده» می‌کند و فراخوانی‌ها
/// را ثبت می‌کند.
class _FakeVideoPlatform extends VideoPlayerPlatform {
  final List<String> calls = [];

  /// یک کنترلرِ رویداد برای هر پخش‌کننده؛ رویدادِ «آماده شد» در onListen
  /// فرستاده می‌شود (نه زودتر)، چون VideoPlayerController بعد از create
  /// گوش می‌دهد و رویدادِ زودتر گم می‌شد.
  final Map<int, StreamController<VideoEvent>> _events = {};
  Duration position = const Duration(minutes: 3, seconds: 5);
  int _next = 1;

  static final VideoEvent _initialized = VideoEvent(
    eventType: VideoEventType.initialized,
    duration: const Duration(minutes: 12, seconds: 34),
    size: const Size(1280, 720),
    rotationCorrection: 0,
  );

  void _emitAll(VideoEvent e) {
    for (final c in _events.values) {
      if (c.hasListener) c.add(e);
    }
  }

  @override
  Future<void> init() async {}
  @override
  Future<int?> create(DataSource dataSource) async => _next++;
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async =>
      _next++;
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    final c = StreamController<VideoEvent>();
    c.onListen = () => c.add(_initialized);
    // بدونِ onCancel، cancel() یک Future از zoneِ ریشه برمی‌گرداند که FakeAsync
    // هرگز نمی‌راند و dispose() تا ابد معطل می‌ماند
    c.onCancel = () async {};
    _events[playerId] = c;
    return c.stream;
  }

  @override
  Future<void> dispose(int playerId) async {}
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> play(int playerId) async {
    calls.add('play');
    _emitAll(VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate, isPlaying: true));
  }

  @override
  Future<void> pause(int playerId) async {
    calls.add('pause');
    _emitAll(VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate, isPlaying: false));
  }
  @override
  Future<void> setVolume(int playerId, double volume) async =>
      calls.add('volume:$volume');
  @override
  Future<void> seekTo(int playerId, Duration p) async {
    position = p;
    calls.add('seek:${p.inSeconds}');
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async =>
      calls.add('speed:$speed');
  @override
  Future<Duration> getPosition(int playerId) async => position;
  @override
  Widget buildView(int playerId) =>
      const ColoredBox(color: Color(0xFF3B4A3F));
  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      buildView(options.playerId);
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
  @override
  Future<void> setWebOptions(int playerId, VideoPlayerWebOptions o) async {}
}

const _v360 = HlsVariant(height: 360, bandwidth: 1, url: 'a/360.m3u8');
const _v720 = HlsVariant(height: 720, bandwidth: 2, url: 'a/720.m3u8');
const _v1080 = HlsVariant(height: 1080, bandwidth: 3, url: 'a/1080.m3u8');

late _FakeVideoPlatform platform;

Future<(GlassPlayerModel, VideoPlayerController)> _readyModel() async {
  final model = GlassPlayerModel()
    ..setInfo(
        title: 'وی کامل با تقه', subtitle: 'دوره دریبلینگ ساکن وی، هفته ۲')
    ..setQualityState(variants: const [_v360, _v720, _v1080], quality: _v720)
    ..setNeighbours(hasNext: true, hasPrevious: true)
    ..onNext = () {}
    ..onPrevious = () {}
    ..onLessons = () {};
  final vc = VideoPlayerController.networkUrl(Uri.parse('https://x/master.m3u8'));
  await vc.initialize();
  // موقعیت فقط هنگامِ پخش از پلتفرم پرسیده می‌شود؛ برای تست صریحاً می‌رویم
  await vc.seekTo(const Duration(minutes: 3, seconds: 5));
  model.attach(vc);
  return (model, vc);
}

Future<void> _pump(WidgetTester t, GlassPlayerModel m, Size box,
    {Size screen = const Size(1200, 800)}) async {
  t.view.physicalSize = screen;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF101410),
        body: Center(
          child: SizedBox(
            width: box.width,
            height: box.height,
            child: GlassVideoPlayer(model: m),
          ),
        ),
      ),
    ),
  ));
  await t.pump();
  await t.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('Estedad');
    for (final f in [
      'Estedad-FD-ExtraLight',
      'Estedad-FD-Regular',
      'Estedad-FD-SemiBold',
      'Estedad-FD-Bold'
    ]) {
      loader.addFont(rootBundle.load('assets/fonts/Estedad/$f.ttf'));
    }
    await loader.load();
  });

  setUp(() {
    platform = _FakeVideoPlatform();
    VideoPlayerPlatform.instance = platform;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  test('قالبِ زمان', () {
    expect(fmtDuration(const Duration(minutes: 4, seconds: 32)), '۰۴:۳۲');
    expect(fmtDuration(const Duration(hours: 1, minutes: 4, seconds: 2)),
        '۱:۰۴:۰۲');
  });

  testWidgets('نمای کوچک (موبایل)', (t) async {
    final (m, vc) = await _readyModel();
    await _pump(t, m, const Size(390, 219), screen: const Size(390, 600));
    expect(find.text('وی کامل با تقه'), findsOneWidget);
    expect(find.text('۷۲۰p'), findsOneWidget);
    expect(find.text('۰۳:۰۵'), findsOneWidget);
    expect(find.text('۱۲:۳۴'), findsOneWidget);
    // در FakeAsync باید همین‌جا منتظر ماند؛ addTearDown بیرون از پمپِ تست می‌ماند و تا ابد معطل می‌شود
    await vc.dispose();
    });

  testWidgets('نمای بزرگ با منوی کیفیت', (t) async {
    final (m, vc) = await _readyModel();
    await _pump(t, m, const Size(1000, 560));
    await t.tap(find.text('۷۲۰p'));
    await t.pump(const Duration(milliseconds: 250));
    expect(find.text('کیفیت ویدیو'), findsOneWidget);
    expect(find.text('۱۰۸۰p'), findsOneWidget);
    // در FakeAsync باید همین‌جا منتظر ماند؛ addTearDown بیرون از پمپِ تست می‌ماند و تا ابد معطل می‌شود
    await vc.dispose();
  });

  testWidgets('پخش، کیفیت، سرعت، صدا', (t) async {
    final (m, vc) = await _readyModel();
    HlsVariant? picked = _v720;
    m.onQuality = (q) => picked = q;
    await _pump(t, m, const Size(1000, 560));

    await t.tap(find.byTooltip('پخش'));
    await t.pump();
    expect(platform.calls, contains('play'));

    await t.tap(find.text('۷۲۰p'));
    await t.pump(const Duration(milliseconds: 250));
    await t.tap(find.text('۱۰۸۰p'));
    await t.pump(const Duration(milliseconds: 250));
    expect(picked, _v1080);
    expect(find.text('کیفیت ویدیو'), findsNothing);

    await t.tap(find.text('۱×'));
    await t.pump(const Duration(milliseconds: 250));
    expect(find.text('سرعت پخش'), findsOneWidget);
    await t.tap(find.text('۱٫۵×'));
    await t.pump(const Duration(milliseconds: 250));
    expect(platform.calls, contains('speed:1.5'));
    expect(find.text('۱٫۵×'), findsOneWidget);

    await t.tap(find.byTooltip('بی‌صدا'));
    await t.pump();
    expect(platform.calls, contains('volume:0.0'));
    expect(m.muted, isTrue);
    // در FakeAsync باید همین‌جا منتظر ماند؛ addTearDown بیرون از پمپِ تست می‌ماند و تا ابد معطل می‌شود
    await vc.dispose();
  });

  testWidgets('تمام‌صفحه: مسیرِ جدا با همان مدل، و برگشت', (t) async {
    final (m, vc) = await _readyModel();
    await _pump(t, m, const Size(390, 219), screen: const Size(390, 600));

    await t.tap(find.byTooltip('تمام‌صفحه'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(m.fullscreen, isTrue);
    final controls = t.widgetList<GlassVideoControls>(
        find.byType(GlassVideoControls));
    expect(controls.where((c) => c.fullscreen), hasLength(1));
    // مسیرِ تمام‌صفحه مات است؛ کادرِ کوچکِ زیرش offstage می‌شود
    expect(find.text('در حالِ پخشِ تمام‌صفحه', skipOffstage: false),
        findsOneWidget);
    // کیفیت وسطِ تمام‌صفحه هم هست
    expect(find.text('۷۲۰p'), findsOneWidget);

    await t.tap(find.byTooltip('خروج از تمام‌صفحه').first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(m.fullscreen, isFalse);
    expect(find.text('در حالِ پخشِ تمام‌صفحه', skipOffstage: false),
        findsNothing);
    // در FakeAsync باید همین‌جا منتظر ماند؛ addTearDown بیرون از پمپِ تست می‌ماند و تا ابد معطل می‌شود
    await vc.dispose();
  });

  testWidgets('درسِ بعدی: کارتِ شمارش و دکمه‌ها', (t) async {
    final (m, vc) = await _readyModel();
    bool playedNext = false, cancelled = false;
    m.onPlayNextNow = () => playedNext = true;
    m.onCancelNext = () => cancelled = true;
    await _pump(t, m, const Size(1000, 560));
    m.setNextUp('زیدانی', 4, total: 6);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('درس بعدی'), findsOneWidget);
    expect(find.text('زیدانی'), findsOneWidget);
    expect(find.text('۴'), findsOneWidget);
    await t.tap(find.text('پخش'));
    await t.pump();
    expect(playedNext, isTrue);
    await t.tap(find.byTooltip('بی‌خیال'));
    await t.pump();
    expect(cancelled, isTrue);
    // در FakeAsync باید همین‌جا منتظر ماند؛ addTearDown بیرون از پمپِ تست می‌ماند و تا ابد معطل می‌شود
    await vc.dispose();
  });
}
