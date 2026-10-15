import 'dart:async';
// lib/views/widgets/app_slider.dart
//
// اسلایدرِ گالریِ بک‌اند (`/v1/gallery/slider/`) با دو حالت:
//   • نمایشگرِ بزرگ (>= tablet): هیروی تمام‌عرض
//   • موبایل: کروسل «کاورفلو» — تصویرِ وسط بزرگ‌تر، دو طرف گوشه‌ای از
//     تصاویرِ مجاور دیده می‌شود.
//
// `page` تعیین می‌کند اسلایدهای کدام صفحه گرفته شوند؛ دسته‌ی بک‌اند از روی
// همین و اندازه‌ی نمایشگر ساخته می‌شود (site_… برای بزرگ، app_… برای موبایل)
// و فیلتر سمتِ سرور با `?category=` انجام می‌شود.
//
// نوعِ هر اسلاید (`slider_type`) رفتارش را تعیین می‌کند: video پخش می‌شود،
// picture فقط تصویر است، و product/course با ضربه به صفحه‌ی همان آیتم
// می‌روند.
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:persian_ball/constant/app_breakpoints.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:persian_ball/constant/app_text_styles.dart';
import 'package:persian_ball/core/slider_link.dart';
import 'package:persian_ball/models/slider_item.dart';
import 'package:persian_ball/services/slider_service.dart';
import 'package:persian_ball/views/widgets/app_network_image.dart';
import 'package:persian_ball/views/widgets/slider_video.dart';
import 'package:persian_ball/views/widgets/motion.dart';

class AppSlider extends StatefulWidget {
  const AppSlider({
    super.key,
    required this.page,
    this.desktopHeight,
    this.showScrollHint = false,
    this.onScrollHint,
  });

  /// صفحه‌ای که اسلایدر در آن است؛ دسته‌ی بک‌اند از روی این و اندازه‌ی
  /// نمایشگر انتخاب می‌شود.
  final SliderPage page;

  /// ارتفاعِ هیرو در نمایشگر بزرگ. null → تمام‌ارتفاعِ ناحیه‌ی موجود.
  final double? desktopHeight;

  /// نمایشِ فلشِ «به پایین اسکرول کن» (فقط صفحه‌ی خانه).
  final bool showScrollHint;
  final VoidCallback? onScrollHint;

  @override
  State<AppSlider> createState() => _AppSliderState();
}

class _AppSliderState extends State<AppSlider> {
  int? _category;
  List<SliderItem>? _items;
  bool _waiting = false;
  StreamSubscription<int>? _sub;

  @override
  void initState() {
    super.initState();
    // وقتی واکشیِ پس‌زمینه تمام شد، اسلایدرِ همین‌جا هم تازه می‌شود.
    _sub = SliderService.updates.listen((category) {
      if (!mounted || category != _category) return;
      setState(() {
        _items = SliderService.cached(category);
        _waiting = false;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // با تغییرِ اندازه‌ی پنجره در وب، دسته از app_… به site_… (و برعکس)
    // عوض می‌شود و باید دوباره واکشی شود.
    final bool desktop =
        MediaQuery.of(context).size.width >= AppBreakpoints.tablet;
    final int category = SliderCategory.of(widget.page, desktop: desktop);
    if (category == _category) return;
    _category = category;

    // اگر از کشِ حافظه/دیسک چیزی داریم فوراً نشان بده؛ سرورِ گالری کند است
    // و انتظار برایش یعنی چند ثانیه اسپینر.
    final cached = SliderService.cached(category);
    _items = cached;
    _waiting = cached == null;

    SliderService.fetchCategory(category).then((fresh) {
      if (!mounted || category != _category) return;
      setState(() {
        _items = fresh;
        _waiting = false;
      });
    }).catchError((_) {
      if (mounted) setState(() => _waiting = false);
    });
  }

  double _heroHeight(BuildContext context) =>
      widget.desktopHeight ?? MediaQuery.of(context).size.height;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool hero = width >= AppBreakpoints.tablet;

    final items = _items ?? const <SliderItem>[];

    if (_waiting) {
      return _LoadingPlaceholder(
        height: hero ? _heroHeight(context) : _kCoverflowBlockHeight,
        hero: hero,
      );
    }
    if (items.isEmpty) return const SizedBox.shrink();

    return hero
            ? _DesktopHero(
                items: items,
                height: _heroHeight(context),
                showScrollHint: widget.showScrollHint,
                onScrollHint: widget.onScrollHint,
              )
            : _PhoneCoverflow(items: items);
  }
}

// ===================== زمان‌بندیِ رفتن به اسلاید بعد =====================

/// مدت ماندنِ یک اسلاید *تصویری* روی صفحه.
const Duration _kHeroInterval = Duration(seconds: 6);
const Duration _kPhoneInterval = Duration(seconds: 5);

/// سقفِ ماندن روی اسلاید ویدیویی؛ اگر ویدیو لود نشد یا رویدادِ پایانش
/// نرسید، اسلایدر گیر نمی‌کند.
const Duration _kVideoTimeout = Duration(seconds: 45);

/// اسلاید بعدی خودش می‌آید: تصویرها بعد از [_interval] و ویدیوها بعد از
/// اینکه کامل پخش شدند (یا سقفِ [_kVideoTimeout]).
mixin _AutoAdvance<T extends StatefulWidget> on State<T> {
  final CarouselSliderController carousel = CarouselSliderController();
  Timer? _timer;
  int _index = 0;

  List<SliderItem> get slides;
  Duration get _interval;

  bool get _canAdvance =>
      slides.length > 1 &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => scheduleNext());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// روی اسلاید ویدیویی تایمرِ عادی نداریم؛ فقط تایمرِ ایمنی.
  void scheduleNext() {
    _timer?.cancel();
    if (!mounted || !_canAdvance) return;
    final bool video = slides[_index].isVideo;
    _timer = Timer(video ? _kVideoTimeout : _interval, _advance);
  }

  void _advance() {
    if (!mounted || !_canAdvance) return;
    carousel.nextPage(
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
    );
  }

  /// ویدیوی اسلاید [i] تمام شد؛ فقط اگر همان اسلایدِ روی صفحه باشد جلو می‌رویم.
  void onVideoEnded(int i) {
    if (i != _index) return;
    _timer?.cancel();
    _advance();
  }

  void onPageChanged(int i) {
    setState(() => _index = i);
    scheduleNext();
  }
}

const double _kCoverflowCardHeight = 200;
const double _kCoverflowBlockHeight = _kCoverflowCardHeight + 40; // + نقاط

// ===================== هیروی نمایشگرِ بزرگ =====================

class _DesktopHero extends StatefulWidget {
  const _DesktopHero({
    required this.items,
    required this.height,
    required this.showScrollHint,
    this.onScrollHint,
  });

  final List<SliderItem> items;
  final double height;
  final bool showScrollHint;
  final VoidCallback? onScrollHint;

  @override
  State<_DesktopHero> createState() => _DesktopHeroState();
}

class _DesktopHeroState extends State<_DesktopHero> with _AutoAdvance {
  @override
  List<SliderItem> get slides => widget.items;

  @override
  Duration get _interval => _kHeroInterval;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final bool multi = items.length > 1;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: CarouselSlider(
              carouselController: carousel,
              options: CarouselOptions(
                height: widget.height,
                viewportFraction: 1.0,
                // جلو رفتن دستِ خودمان است تا ویدیو وسطِ پخش قطع نشود.
                autoPlay: false,
                onPageChanged: (i, _) => onPageChanged(i),
              ),
              items: [
                for (int i = 0; i < items.length; i++)
                  _HeroSlide(
                    item: items[i],
                    onVideoEnded: () => onVideoEnded(i),
                  ),
              ],
            ),
          ),
          // نقاط + فلشِ اسکرول، پایینِ هیرو و بیرون از خودِ کروسل تا جابه‌جا نشوند
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (multi) _Dots(count: items.length, index: _index, light: true),
                if (widget.showScrollHint) ...[
                  if (multi) const SizedBox(height: 4),
                  _BouncingChevron(onTap: widget.onScrollHint),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// رسانه‌ی یک اسلاید: اگر نوعش video باشد ویدیو پخش می‌شود، وگرنه تصویر.
class _SlideMedia extends StatelessWidget {
  const _SlideMedia({required this.item, this.onVideoEnded});

  final SliderItem item;

  /// وقتی ویدیوی این اسلاید تا آخر پخش شد؛ اسلایدر با آن به اسلاید بعد می‌رود.
  final VoidCallback? onVideoEnded;

  @override
  Widget build(BuildContext context) {
    if (item.isVideo) {
      // بدونِ نوارِ پخش؛ فقط دکمه‌ی صدا (SliderVideo).
      return SliderVideo(
        videoUrl: item.videoUrl!,
        // تکرار نمی‌شود تا بعدِ پایانِ ویدیو نوبت به اسلاید بعدی برسد.
        looping: onVideoEnded == null,
        onCompleted: onVideoEnded,
      );
    }
    return AppNetworkImage(url: item.imageUrl, fit: BoxFit.cover);
  }
}

class _HeroSlide extends StatelessWidget {
  const _HeroSlide({required this.item, this.onVideoEnded});

  final SliderItem item;
  final VoidCallback? onVideoEnded;

  @override
  Widget build(BuildContext context) {
    // روی اسلاید ویدیویی نباید لایه‌ی شفاف و ضربه بنشیند، وگرنه کنترل‌های
    // پخش کار نمی‌کنند.
    final bool tappable =
        !item.isVideo && SliderLink.hasTarget(item.clickUrl);

    final Widget slide = Stack(
      fit: StackFit.expand,
      children: [
        _SlideMedia(item: item, onVideoEnded: onVideoEnded),
        if (!item.isVideo)
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xE6101A12), Color(0x22101A12)],
            ),
          ),
        ),
        if (item.hasCaption && !item.isVideo)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.contentMaxWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.headerText != null)
                      Text(
                        item.headerText!,
                        style: AppTextStyles.headlineLg.copyWith(
                          color: item.headerColor ?? Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    if (item.text != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        item.text!,
                        style: AppTextStyles.bodyLg.copyWith(
                          color: item.textColor ?? Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    ],
                    if (item.buttonText != null) ...[
                      const SizedBox(height: 22),
                      _CtaPill(
                        label: item.buttonText!,
                        color: item.buttonColor,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    if (!tappable) return slide;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => SliderLink.open(context, item.clickUrl),
        child: slide,
      ),
    );
  }
}

// ===================== کروسلِ کاورفلوِ موبایل =====================

class _PhoneCoverflow extends StatefulWidget {
  const _PhoneCoverflow({required this.items});

  final List<SliderItem> items;

  @override
  State<_PhoneCoverflow> createState() => _PhoneCoverflowState();
}

class _PhoneCoverflowState extends State<_PhoneCoverflow> with _AutoAdvance {
  @override
  List<SliderItem> get slides => widget.items;

  @override
  Duration get _interval => _kPhoneInterval;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final bool single = items.length < 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _kCoverflowCardHeight,
          child: CarouselSlider.builder(
            carouselController: carousel,
            itemCount: items.length,
            options: CarouselOptions(
              height: _kCoverflowCardHeight,
              viewportFraction: single ? 0.9 : 0.8,
              enlargeCenterPage: true,
              enlargeFactor: 0.28,
              enlargeStrategy: CenterPageEnlargeStrategy.zoom,
              // جلو رفتن دستِ خودمان است تا ویدیو وسطِ پخش قطع نشود.
              autoPlay: false,
              onPageChanged: (i, _) => onPageChanged(i),
            ),
            itemBuilder: (context, i, _) => _CoverflowCard(
              item: items[i],
              onVideoEnded: () => onVideoEnded(i),
            ),
          ),
        ),
        if (!single) ...[
          const SizedBox(height: 14),
          _Dots(count: items.length, index: _index),
        ],
      ],
    );
  }
}

class _CoverflowCard extends StatelessWidget {
  const _CoverflowCard({required this.item, this.onVideoEnded});

  final SliderItem item;
  final VoidCallback? onVideoEnded;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      // اسلاید ویدیویی ضربه‌ی ناوبری نمی‌گیرد تا کنترل‌های پخش آزاد بمانند.
      onTap: !item.isVideo && SliderLink.hasTarget(item.clickUrl)
          ? () => SliderLink.open(context, item.clickUrl)
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: ShapeDecoration(
          shape: AppShapes.border(AppShapes.rXl),
          shadows: AppColor.floatingShadow,
        ),
        child: SquircleClip(
          radius: AppShapes.rXl,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _SlideMedia(item: item, onVideoEnded: onVideoEnded),
              if (item.hasCaption && !item.isVideo)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [Color(0xD9101A12), Color(0x00101A12)],
                    ),
                  ),
                ),
              if (item.hasCaption && !item.isVideo)
                Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.headerText != null)
                          Text(
                            item.headerText!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headlineMd.copyWith(
                              color: item.headerColor ?? Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        if (item.text != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              item.text!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: item.textColor ?? Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (item.buttonText != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _CtaPill(
                              label: item.buttonText!,
                              color: item.buttonColor,
                              dense: true,
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
    );
  }
}

// ===================== اجزای مشترک =====================

class _CtaPill extends StatelessWidget {
  const _CtaPill({required this.label, this.color, this.dense = false});

  final String label;
  final Color? color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColor.pitchGreen;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 12 : 20,
        vertical: dense ? 6 : 12,
      ),
      decoration: ShapeDecoration(
        color: bg,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Estedad',
              fontSize: dense ? 11 : 14,
              fontWeight: FontWeight.w700,
              color: _onColor(bg),
            ),
          ),
          SizedBox(width: dense ? 4 : 8),
          Icon(Icons.arrow_back_rounded,
              size: dense ? 14 : 18, color: _onColor(bg)),
        ],
      ),
    );
  }

  static Color _onColor(Color bg) =>
      bg.computeLuminance() > 0.6 ? AppColor.ink : Colors.white;
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index, this.light = false});

  final int count;
  final int index;

  /// روی هیروی تیره: نقاطِ روشن.
  final bool light;

  @override
  Widget build(BuildContext context) {
    final Color active = light ? Colors.white : AppColor.pitchGreen;
    final Color idle =
        light ? Colors.white.withOpacity(0.45) : AppColor.lineStrong;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index ? active : idle,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

class _BouncingChevron extends StatefulWidget {
  const _BouncingChevron({this.onTap});
  final VoidCallback? onTap;

  @override
  State<_BouncingChevron> createState() => _BouncingChevronState();
}

class _BouncingChevronState extends State<_BouncingChevron>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return IconButton(
      onPressed: widget.onTap,
      icon: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, reduceMotion ? 0 : 6 * _c.value),
          child: child,
        ),
        child: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Colors.white70, size: 40),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder({required this.height, required this.hero});

  final double height;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    if (hero) {
      return SkeletonBox(
        height: height,
        borderRadius: BorderRadius.zero,
      );
    }
    return SizedBox(
      height: height,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SkeletonBox(
            height: _kCoverflowCardHeight,
            borderRadius: AppShapes.radius(AppShapes.rXl),
          ),
        ),
      ),
    );
  }
}
