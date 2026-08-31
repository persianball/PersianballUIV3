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
import 'package:marketky/constant/app_breakpoints.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/constant/app_text_styles.dart';
import 'package:marketky/core/slider_link.dart';
import 'package:marketky/models/slider_item.dart';
import 'package:marketky/services/slider_service.dart';
import 'package:marketky/views/widgets/app_network_image.dart';
import 'package:marketky/views/widgets/inline_video_player.dart';
import 'package:marketky/views/widgets/motion.dart';

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
  Future<List<SliderItem>>? _future;
  int? _category;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // با تغییرِ اندازه‌ی پنجره در وب، دسته از app_… به site_… (و برعکس)
    // عوض می‌شود و باید دوباره واکشی شود.
    final bool desktop =
        MediaQuery.of(context).size.width >= AppBreakpoints.tablet;
    final int category = SliderCategory.of(widget.page, desktop: desktop);
    if (category != _category) {
      _category = category;
      _future = SliderService.fetchCategory(category);
    }
  }

  double _heroHeight(BuildContext context) =>
      widget.desktopHeight ?? MediaQuery.of(context).size.height;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool hero = width >= AppBreakpoints.tablet;

    return FutureBuilder<List<SliderItem>>(
      future: _future,
      builder: (context, snap) {
        final bool loading = snap.connectionState != ConnectionState.done;
        final items = snap.data ?? const <SliderItem>[];

        if (loading) {
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
      },
    );
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

class _DesktopHeroState extends State<_DesktopHero> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final bool multi = items.length > 1;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: CarouselSlider(
              options: CarouselOptions(
                height: widget.height,
                viewportFraction: 1.0,
                autoPlay: !reduceMotion && multi,
                autoPlayInterval: const Duration(seconds: 6),
                autoPlayAnimationDuration: const Duration(milliseconds: 900),
                autoPlayCurve: Curves.easeOutCubic,
                pauseAutoPlayOnTouch: true,
                onPageChanged: (i, _) => setState(() => _index = i),
              ),
              items: [
                for (final item in items) _HeroSlide(item: item),
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
  const _SlideMedia({required this.item});

  final SliderItem item;

  @override
  Widget build(BuildContext context) {
    if (item.isVideo) {
      return InlineVideoPlayer(videoUrl: item.videoUrl!, autoPlay: false);
    }
    return AppNetworkImage(url: item.imageUrl, fit: BoxFit.cover);
  }
}

class _HeroSlide extends StatelessWidget {
  const _HeroSlide({required this.item});

  final SliderItem item;

  @override
  Widget build(BuildContext context) {
    // روی اسلاید ویدیویی نباید لایه‌ی شفاف و ضربه بنشیند، وگرنه کنترل‌های
    // پخش کار نمی‌کنند.
    final bool tappable =
        !item.isVideo && SliderLink.hasTarget(item.clickUrl);

    final Widget slide = Stack(
      fit: StackFit.expand,
      children: [
        _SlideMedia(item: item),
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

class _PhoneCoverflowState extends State<_PhoneCoverflow> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final bool single = items.length < 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _kCoverflowCardHeight,
          child: CarouselSlider.builder(
            itemCount: items.length,
            options: CarouselOptions(
              height: _kCoverflowCardHeight,
              viewportFraction: single ? 0.9 : 0.8,
              enlargeCenterPage: true,
              enlargeFactor: 0.28,
              enlargeStrategy: CenterPageEnlargeStrategy.zoom,
              autoPlay: !reduceMotion && !single,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 850),
              autoPlayCurve: Curves.easeOutCubic,
              pauseAutoPlayOnTouch: true,
              onPageChanged: (i, _) => setState(() => _index = i),
            ),
            itemBuilder: (context, i, _) => _CoverflowCard(item: items[i]),
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
  const _CoverflowCard({required this.item});

  final SliderItem item;

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
              _SlideMedia(item: item),
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
