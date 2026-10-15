// views/screens/home_page.dart
import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persian_ball/views/widgets/app_logo.dart';
import 'package:persian_ball/constant/app_breakpoints.dart';
import 'package:persian_ball/views/widgets/category_pill_bar.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:persian_ball/constant/app_text_styles.dart';
import 'package:persian_ball/constant/urls.dart';
import 'package:persian_ball/models/course_models.dart';
import 'package:persian_ball/services/auth_service.dart';
import 'package:persian_ball/services/course_service.dart';
import 'package:persian_ball/views/widgets/app_buttons.dart';
import 'package:persian_ball/views/widgets/app_network_image.dart';
import 'package:persian_ball/views/widgets/flashsale_countdown_tile.dart';
import 'package:persian_ball/utils/ThousandsFormatter.dart';
import 'package:persian_ball/views/widgets/product_grid_card.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/product/product_bloc.dart';
import '../../models/ProductModel.dart';
import '../../services/catalog_service.dart';
import '../../services/notification_service.dart';
import 'catalog_page.dart';
import 'course_detail_page.dart';
import 'profile_page.dart' show UserService;
import 'package:persian_ball/views/widgets/motion.dart';
import 'package:persian_ball/views/widgets/app_slider.dart';
import 'package:persian_ball/views/widgets/shimmer.dart';
import 'package:persian_ball/models/slider_item.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? flashsaleCountdownTimer;
  Duration flashsaleCountdownDuration = Duration(
    hours: 24 - DateTime.now().hour,
    minutes: 60 - DateTime.now().minute,
    seconds: 60 - DateTime.now().second,
  );

  /// اولین دوره‌ی واقعی، برای بخش «دوره‌های ویژه»
  Course? _featuredCourse;

  /// نام کاربر برای خوش‌آمدگویی — از همان UserService موجود صفحه‌ی پروفایل
  /// خوانده می‌شود (اندپوینت جدیدی ساخته نشده است).
  String? _userName;

  /// همان فیلتر/جست‌وجوی سمت کلاینت موجود (CatalogService)، بدون منطق جدید
  CatalogFilter _filter = const CatalogFilter();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  /// اسکرول صفحه — برای «قفل‌شدن» اسلایدر قهرمانِ تمام‌صفحه در دسکتاپ/تبلت
  final ScrollController _scrollController = ScrollController();
  bool _snappingHero = false;

  /// با هر پایانِ اسکرول، اگر کاربر نیمه‌کاره داخل هیرو مانده باشد، صفحه
  /// را کاملاً به هیرو یا کاملاً به بخش بعدی می‌بَرد (اسکرول تمام‌صفحه).
  void _snapHero(double heroHeight) {
    if (_snappingHero || !_scrollController.hasClients || heroHeight <= 0) return;
    final double offset = _scrollController.offset;
    if (offset <= 0 || offset >= heroHeight) return;
    final double target = offset < heroHeight * 0.2 ? 0.0 : heroHeight;
    if ((target - offset).abs() < 1) return;
    _snappingHero = true;
    _scrollController
        .animateTo(target,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic)
        .whenComplete(() => _snappingHero = false);
  }

  /// همه‌ی داده‌های صفحه‌ی خانه را دوباره می‌گیرد. Future برمی‌گرداند تا
  /// نشانگر «کشیدن برای تازه‌سازی» تا پایان واقعیِ بارگذاری بچرخد؛ پیش‌تر
  /// چون هیچ‌چیز await نمی‌شد، حلقه بلافاصله محو می‌شد.
  Future<void> reloadHomePage() async {
    final productBloc = context.read<ProductBloc>();
    productBloc.add(FetchProducts());
    context.read<CartBloc>().add(LoadCart(context));
    await Future.wait<void>([
      productBloc.stream
          .firstWhere((s) => s is! ProductLoading)
          .timeout(const Duration(seconds: 20),
              onTimeout: () => productBloc.state)
          .then((_) {}),
      _loadFeaturedCourse(),
      _loadUserName(),
    ]);
  }

  Future<void> _loadFeaturedCourse() async {
    try {
      final res = await CourseService.fetchCourses();
      if (!mounted || res.results.isEmpty) return;
      setState(() => _featuredCourse = res.results.first);
    } catch (_) {
      // بخش دوره‌ها اختیاری است؛ خطا فقط یعنی این بخش نمایش داده نمی‌شود
    }
  }

  Future<void> _loadUserName() async {
    try {
      // مهم: getUserProfile برای کاربر بدون توکن دیالوگ «نیاز به ورود» را
      // باز می‌کند. صفحه‌ی خانه نباید کاربر مهمان را مجبور به ورود کند، پس
      // اول وجود توکن بررسی می‌شود.
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) return;
      if (!mounted) return;
      final profile = await UserService.getUserProfile(context);
      if (!mounted || profile == null) return;
      final name = (profile['first_name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) setState(() => _userName = name);
    } catch (_) {
      // مهمان/بدون توکن: فقط خوش‌آمد عمومی نمایش داده می‌شود
    }
  }

  /// همان الگوی debounce ۳۰۰ میلی‌ثانیه‌ای صفحه‌ی فروشگاه
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _filter = _filter.copyWith(query: value));
    });
  }

  String _abs(String rel) {
    if (rel.isEmpty) return '';
    if (rel.startsWith('http')) return rel;
    return '${URLs.baseUrl}$rel';
  }

  @override
  void initState() {
    super.initState();
    reloadHomePage();
    startTimer();
    // نامِ کاربر هم به وضعیت ورود وابسته است؛ سبد را ریشه‌ی برنامه
    // به‌روز می‌کند، ولی خوش‌آمدگویی حالتِ همین صفحه است.
    AuthService.authRevision.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (mounted) _loadUserName();
  }

  void startTimer() {
    flashsaleCountdownTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          final seconds = flashsaleCountdownDuration.inSeconds - 1;
          if (seconds < 1) {
            flashsaleCountdownTimer?.cancel();
          } else {
            flashsaleCountdownDuration = Duration(seconds: seconds);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    AuthService.authRevision.removeListener(_onAuthChanged);
    flashsaleCountdownTimer?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String seconds =
        flashsaleCountdownDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    String minutes =
        flashsaleCountdownDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    String hours =
        flashsaleCountdownDuration.inHours.remainder(24).toString().padLeft(2, '0');

    // دسکتاپ (>=1024): پوسته‌ی بالای صفحه (page_switcher) هدر را نمایش
    // می‌دهد؛ اینجا فقط محتوای مرکزی با عرض حداکثر ۱۲۰۰ چیده می‌شود.
    final bool isDesktop = AppBreakpoints.isDesktop(context);
    // اسلایدر قهرمانِ تمام‌صفحه برای تبلت/لپ‌تاپ/دسکتاپ (>=۷۶۸)
    final bool isBigScreen =
        MediaQuery.of(context).size.width >= AppBreakpoints.tablet;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(builder: (context, viewport) {
            final double heroHeight = viewport.maxHeight;
            return BlocConsumer<ProductBloc, ProductState>(
            listener: (context, state) {},
            builder: (context, state) {
              if (state is ProductLoading) {
                return _HomeSkeleton(
                  isDesktop: isDesktop,
                  isBigScreen: isBigScreen,
                  heroHeight: heroHeight,
                );
              }
              if (state is ProductError) return _buildError(state.message);
              if (state is ProductLoaded) {
                final all = state.products;
                final categories = CatalogService.categoriesFrom(all);
                final results = CatalogService.apply(all, _filter);
                final flashProducts =
                    all.where((p) => (p.discountPercentage ?? 0) > 0).toList();

                return RefreshIndicator(
                  color: AppColor.pitchGreen,
                  backgroundColor: AppColor.card,
                  onRefresh: reloadHomePage,
                  child: NotificationListener<ScrollEndNotification>(
                  onNotification: (n) {
                    if (isBigScreen && n.depth == 0) _snapHero(heroHeight);
                    return false;
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      // اسلایدر قهرمانِ تمام‌صفحه در بالای صفحه (تبلت/لپ‌تاپ/دسکتاپ)
                      if (isBigScreen)
                        SliverToBoxAdapter(
                          child: AppSlider(
                            page: SliderPage.home,
                            desktopHeight: heroHeight,
                            showScrollHint: true,
                            onScrollHint: () {
                              if (_scrollController.hasClients) {
                                _scrollController.animateTo(
                                  heroHeight,
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            },
                          ),
                        ),
                      // هدر موبایل (آواتار/عنوان/زنگ/سبد) در دسکتاپ حذف
                      // می‌شود؛ نوار بالای پوسته همان‌ها را دارد.
                      if (!isDesktop)
                        SliverToBoxAdapter(child: _buildHeader()),
                      SliverToBoxAdapter(child: _buildGreeting(isDesktop)),
                      SliverToBoxAdapter(child: _buildSearchRow(isDesktop)),
                      if (!isBigScreen)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 18),
                            child: AppSlider(page: SliderPage.home),
                          ),
                        ),
                      if (categories.isNotEmpty)
                        SliverToBoxAdapter(
                            child: _buildCategoryChips(
                                all, categories, isDesktop)),
                      _buildProductSliver(results, isDesktop),
                      SliverToBoxAdapter(child: _buildHero(isDesktop)),
                      if (_featuredCourse != null)
                        SliverToBoxAdapter(
                            child: _buildFeaturedCourse(
                                _featuredCourse!, isDesktop)),
                      if (flashProducts.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _buildFlashSaleSection(flashProducts, hours,
                              minutes, seconds, isDesktop),
                        ),
                      // فضای خالی زیر لیست تا نوار ناوبری شناور روی محتوا
                      // نیفتد؛ در دسکتاپ نوار پایینی وجود ندارد.
                      SliverToBoxAdapter(
                          child: SizedBox(height: isDesktop ? 40 : 110)),
                    ],
                  ),
                  ),
                );
              }
              return _HomeSkeleton(
                isDesktop: isDesktop,
                isBigScreen: isBigScreen,
                heroHeight: heroHeight,
              );
            },
          );
          }),
        ),
      ),
    );
  }

  /// پوسته‌ی مشترک بخش‌های دسکتاپ: وسط‌چین با حداکثر عرض ۱۲۰۰.
  /// پدینگ افقی ۲۰ خودِ بخش‌ها نقش لبه (gutter) را بازی می‌کند، پس
  /// gutter اضافه لازم نیست. در موبایل/تبلت همان چیدمان قبلی برمی‌گردد.
  Widget _desktopSection(bool isDesktop, Widget child) {
    if (!isDesktop) return child;
    return CenteredContent(withGutter: false, child: child);
  }

  // ==== هدر: آواتار | عنوان | زنگ + سبد ====

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          // جای برند: پیش‌تر یک عکسِ آواتارِ عمومی اینجا بود.
          const AppLogo(size: 42),
          Expanded(
            child: Text(
              'پرشین بال',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMd.copyWith(
                fontSize: 17,
                color: AppColor.ink,
                letterSpacing: 1,
              ),
            ),
          ),
          FutureBuilder<int>(
            future: NotificationService.unreadCount(),
            builder: (context, snap) => Badge(
              isLabelVisible: (snap.data ?? 0) > 0,
              label: Text('${snap.data ?? 0}'),
              backgroundColor: AppColor.danger,
              child: CircleIconButton(
                icon: Icons.notifications_none_rounded,
                size: 42,
                onTap: () async {
                  await Navigator.of(context).pushNamed('/notifications');
                  if (mounted) setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              final count = cartState is CartLoaded
                  ? (cartState.cart.results.isNotEmpty
                      ? cartState.cart.results[0].items.length
                      : 0)
                  : 0;
              return Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                backgroundColor: AppColor.danger,
                child: CircleIconButton(
                  icon: Icons.shopping_bag_outlined,
                  size: 42,
                  onTap: () => Navigator.of(context).pushNamed('/cart'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(bool isDesktop) {
    // در دسکتاپ خوش‌آمدگویی نقش «قهرمان» صفحه را می‌گیرد: تایپوگرافی
    // بزرگ‌تر و فاصله‌ی بیشتر از بالا (هدر موبایل حذف شده است).
    return _desktopSection(
      isDesktop,
      Padding(
        padding: EdgeInsets.fromLTRB(20, isDesktop ? 40 : 22, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _userName == null ? 'سلام، خوش آمدید' : 'سلام $_userName',
              style: AppTextStyles.headlineLg.copyWith(
                fontSize: isDesktop ? 34 : 26,
                color: AppColor.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: isDesktop ? 8 : 4),
            Text(
              'بهترین‌ها را برای خود پیدا کنید.',
              style: AppTextStyles.bodyMd.copyWith(
                  fontSize: isDesktop ? 15 : 13, color: AppColor.inkMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ==== جست‌وجو + دکمه‌ی فیلتر ====

  Widget _buildSearchRow(bool isDesktop) {
    final Widget row = Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: ShapeDecoration(
                color: AppColor.card,
                shape: AppShapes.pill,
                shadows: AppColor.cardShadow,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onQueryChanged,
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                    fontFamily: 'Estedad', fontSize: 13, color: AppColor.ink),
                decoration: const InputDecoration(
                  hintText: 'جست‌وجو کنید',
                  prefixIcon:
                      Icon(Icons.search_rounded, size: 20, color: AppColor.inkMuted),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // دکمه‌ی فیلتر: صفحه‌ی فروشگاه موجود را با همان عبارت جست‌وجو باز
          // می‌کند تا از شیت فیلتر/مرتب‌سازی موجود همان‌جا استفاده شود.
          GradientButton(
            label: 'فیلتر',
            expand: false,
            height: 50,
            fontSize: 13,
            gradient: const LinearGradient(
              colors: [Color(0xFF1E2A2F), AppColor.darkButton],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CatalogPage(initialQuery: _filter.query),
              ),
            ),
          ),
        ],
      );

    // دسکتاپ: فیلد جست‌وجو در عرض کامل ۱۲۰۰ کشیده نمی‌شود؛ به عرض
    // خوش‌خوان (~۵۶۰) محدود و از سمت شروع (راست در RTL) تراز می‌شود.
    return _desktopSection(
      isDesktop,
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: isDesktop
            ? Align(
                alignment: AlignmentDirectional.centerStart,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: row,
                ),
              )
            : row,
      ),
    );
  }

  // ==== چیپ دسته‌بندی ====

  Widget _buildCategoryChips(
      List<Product> all, List<Category> categories, bool isDesktop) {
    // تعداد محصولِ هر دسته از برچسب حذف شد: عدد داخل نام، خواندنِ سریعِ
    // دسته‌ها را سخت می‌کرد.
    final int selectedIndex = _filter.categoryId == null
        ? 0
        : categories.indexWhere((c) => c.id == _filter.categoryId) + 1;
    final Widget list = CategoryPillBar(
      labels: ['همه', ...categories.map((c) => c.nameFarsi)],
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      height: 44,
      // در دسکتاپ لیست داخل ستون مرکزی ۱۲۰۰ است؛ برش لازم است تا
      // چیپ‌های اسکرول‌شده روی حاشیه‌ی سفید دو طرف نیفتند.
      clipBehavior: isDesktop ? Clip.hardEdge : Clip.none,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      onSelected: (i) => setState(() => _filter = i == 0
          ? _filter.copyWith(clearCategory: true)
          : _filter.copyWith(categoryId: categories[i - 1].id)),
    );

    return _desktopSection(
      isDesktop,
      Container(
        height: 44,
        margin: const EdgeInsets.only(top: 20),
        child: list,
      ),
    );
  }

  // ==== گرید محصولات ====

  Widget _buildProductSliver(List<Product> results, bool isDesktop) {
    if (results.isEmpty) {
      return SliverToBoxAdapter(
        child: _desktopSection(
          isDesktop,
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
            child: Column(
              children: [
                const Icon(Icons.search_off_rounded,
                    size: 44, color: AppColor.lineStrong),
                const SizedBox(height: 12),
                Text('محصولی با این مشخصات پیدا نشد',
                    style: AppTextStyles.bodyMd.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }

    // ورود پلکانی کارت‌ها؛ تأخیر سقف دارد تا اسکرول به پایین
    // لیست بلند، منتظر انیمیشن نماند. (مشترک بین موبایل و دسکتاپ)
    final delegate = SliverChildBuilderDelegate(
      (context, i) => FadeSlideIn(
        delay: Duration(milliseconds: 40 * (i % 8)),
        child: ProductGridCard(product: results[i]),
      ),
      childCount: results.length,
    );

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.crossAxisExtent;
        const double spacing = 16;

        if (!isDesktop) {
          // موبایل/تبلت: دقیقاً همان چیدمان قبلی (۲ ستون، از ۶۲۰ به بالا ۳)
          final width = viewport - 40;
          final columns = width >= 620 ? 3 : 2;
          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: 0.68,
              ),
              delegate: delegate,
            ),
          );
        }

        // دسکتاپ: گرید هم‌عرض با بقیه‌ی بخش‌ها (۱۲۰۰ منهای لبه‌ی ۲۰) و
        // وسط‌چین از طریق پدینگ محاسبه‌شده‌ی دو طرف.
        const double targetWidth = AppBreakpoints.contentMaxWidth - 40;
        final double sidePad =
            ((viewport - targetWidth) / 2).clamp(20.0, double.infinity).toDouble();
        final double gridWidth = viewport - sidePad * 2;
        final int columns = AppBreakpoints.gridColumns(gridWidth);
        // پاورقی متن کارت ارتفاع تقریباً ثابتی دارد؛ نسبت ابعاد بر اساس
        // عرض واقعی کارت محاسبه می‌شود تا در ۴ ستون فضای خالی نماند.
        final double cardWidth =
            (gridWidth - (columns - 1) * spacing) / columns;
        final double ratio = cardWidth / (cardWidth + 80);

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(sidePad, 24, sidePad, 0),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: ratio,
            ),
            delegate: delegate,
          ),
        );
      },
    );
  }

  // ==== بنرها (داده‌ی موجود NotificationService.banners) ====

  Widget _buildHero(bool isDesktop) {
    final banners = NotificationService.banners();
    if (banners.isEmpty) return const SizedBox.shrink();
    // دسکتاپ: بنر بلندتر و تایپوگرافی درشت‌تر، مثل هیروی سایت‌های فروشگاهی
    final double bannerHeight = isDesktop ? 320 : 190;
    return _desktopSection(
      isDesktop,
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
        child: Container(
          decoration: ShapeDecoration(
            shape: AppShapes.border(AppShapes.rXl),
            shadows: AppColor.floatingShadow,
          ),
          child: SquircleClip(
            radius: AppShapes.rXl,
            child: SizedBox(
              height: bannerHeight,
              child: CarouselSlider(
                options: CarouselOptions(
                  height: bannerHeight,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 5),
                  viewportFraction: 1.0,
                ),
                items: banners
                    .map((b) => Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(b.assetImage, fit: BoxFit.cover),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Color(0xE6101A12), Color(0x22101A12)],
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(isDesktop ? 32 : 18),
                              child: Align(
                                alignment: AlignmentDirectional.bottomStart,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const PillTag(
                                      label: 'پیشنهاد ویژه',
                                      icon: Icons.sports_soccer,
                                      color: Colors.white,
                                      gradient: AppColor.greenGradient,
                                    ),
                                    SizedBox(height: isDesktop ? 14 : 10),
                                    Text(b.title,
                                        style: AppTextStyles.headlineMd.copyWith(
                                            color: Colors.white,
                                            fontSize: isDesktop ? 28 : 19)),
                                    SizedBox(height: isDesktop ? 8 : 4),
                                    Text(b.subtitle,
                                        style: AppTextStyles.bodyMd.copyWith(
                                            color: Colors.white70,
                                            fontSize: isDesktop ? 15 : 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: const ShapeDecoration(
            gradient: AppColor.greenGradient,
            shape: StadiumBorder(),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: AppTextStyles.headlineMd
                .copyWith(fontSize: 17, color: AppColor.ink)),
        const Spacer(),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('مشاهده همه', style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }

  // ==== دوره‌ی ویژه (CourseService موجود) ====

  Widget _buildFeaturedCourse(Course course, bool isDesktop) {
    final price = course.discountPercentage > 0
        ? (course.coursePrice * (1 - course.discountPercentage / 100)).toInt()
        : course.coursePrice;

    final Widget info = Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              PillTag(
                  label: course.difficulty,
                  icon: Icons.sports_soccer,
                  dense: true),
              if (course.discountPercentage > 0)
                PillTag(
                  label: '٪${course.discountPercentage} تخفیف',
                  icon: Icons.local_offer_outlined,
                  color: AppColor.danger,
                  dense: true,
                ),
            ],
          ),
          SizedBox(height: isDesktop ? 12 : 8),
          Text(course.nameFarsi,
              style: AppTextStyles.headlineMd.copyWith(
                  fontSize: isDesktop ? 20 : 16, color: AppColor.ink)),
          SizedBox(height: isDesktop ? 8 : 4),
          Text(
            course.description,
            maxLines: isDesktop ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMd
                .copyWith(fontSize: isDesktop ? 13 : 12),
          ),
          SizedBox(height: isDesktop ? 18 : 12),
          Row(
            children: [
              Text('${thousandSeparator(price)} تومان',
                  style: AppTextStyles.bodyMd.copyWith(
                      fontSize: isDesktop ? 16 : 14,
                      color: AppColor.ink,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              GradientButton(
                label: 'مشاهده دوره',
                expand: false,
                height: isDesktop ? 44 : 38,
                fontSize: isDesktop ? 13 : 12,
                // در RTL «جلو» یعنی چپ: arrow_forward خودش آینه می‌شود و ←
                // نشان می‌دهد، و بعد از متن (سمتِ چپ) می‌نشیند.
                trailingIcon: const Icon(Icons.arrow_forward_rounded),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => CourseDetailPage(id: course.id)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // دسکتاپ: کارت افقی (تصویر یک سمت، توضیحات سمت دیگر) تا تصویر ۱۶:۹
    // در عرض ۱۲۰۰ بیش از حد بزرگ نشود؛ موبایل همان کارت عمودی قبلی.
    final Widget cardBody = isDesktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: AppNetworkImage(url: _abs(course.image)),
                ),
              ),
              Expanded(flex: 7, child: info),
            ],
          )
        : Column(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: AppNetworkImage(url: _abs(course.image)),
              ),
              info,
            ],
          );

    return _desktopSection(
      isDesktop,
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('دوره‌های ویژه'),
            const SizedBox(height: 12),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => CourseDetailPage(id: course.id)),
                ),
                child: Container(
                  decoration: ShapeDecoration(
                    color: AppColor.card,
                    shape: AppShapes.border(AppShapes.rLg),
                    shadows: AppColor.cardShadow,
                  ),
                  child: SquircleClip(
                    radius: AppShapes.rLg,
                    child: cardBody,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==== فروش ویژه ====

  Widget _buildFlashSaleSection(List<Product> products, String hours,
      String minutes, String seconds, bool isDesktop) {
    // دسکتاپ: کارت‌های عریض‌تر و فاصله‌ی داخلی بیشتر؛ همان لیست افقی.
    final double itemWidth = isDesktop ? 200 : 165;
    final double listHeight = isDesktop ? 306 : 268;
    final double innerPad = isDesktop ? 18 : 14;

    return _desktopSection(
      isDesktop,
      Container(
        margin: const EdgeInsets.fromLTRB(20, 28, 20, 0),
        decoration: ShapeDecoration(
          color: AppColor.card,
          shape: AppShapes.border(AppShapes.rLg),
          shadows: AppColor.cardShadow,
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(innerPad, innerPad, innerPad, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const PillTag(
                    label: 'فروش ویژه',
                    icon: Icons.flash_on_rounded,
                    color: Colors.white,
                    gradient: AppColor.greenGradient,
                  ),
                  Row(
                    textDirection: TextDirection.ltr,
                    children: [
                      FlashsaleCountdownTile(digit: hours[0]),
                      FlashsaleCountdownTile(digit: hours[1]),
                      Text(':', style: AppTextStyles.bodyLg),
                      FlashsaleCountdownTile(digit: minutes[0]),
                      FlashsaleCountdownTile(digit: minutes[1]),
                      Text(':', style: AppTextStyles.bodyLg),
                      FlashsaleCountdownTile(digit: seconds[0]),
                      FlashsaleCountdownTile(digit: seconds[1]),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: listHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                // در دسکتاپ کارت‌های اسکرول‌شده نباید بیرون کارتِ بخش،
                // روی حاشیه‌ی صفحه کشیده شوند.
                clipBehavior: isDesktop ? Clip.hardEdge : Clip.none,
                padding: EdgeInsets.fromLTRB(innerPad, 6, innerPad, 16),
                itemCount: products.length,
                separatorBuilder: (_, i) => const SizedBox(width: 12),
                itemBuilder: (_, index) => SizedBox(
                  width: itemWidth,
                  child: ProductGridCard(product: products[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('خطا: $message',
              style: AppTextStyles.bodyMd.copyWith(color: AppColor.danger),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          GradientButton(
            label: 'تلاش مجدد',
            expand: false,
            height: 42,
            fontSize: 13,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: reloadHomePage,
          ),
        ],
      ),
    );
  }
}

/// اسکلتونِ شیمرِ صفحه‌ی خانه — دقیقاً هم‌ساختارِ صفحه‌ی بارگذاری‌شده.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton({
    required this.isDesktop,
    required this.isBigScreen,
    required this.heroHeight,
  });

  final bool isDesktop;
  final bool isBigScreen;
  final double heroHeight;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: isBigScreen ? _desktop(context) : _mobile(context),
      ),
    );
  }

  // ---- موبایل: هدر، خوش‌آمد، جست‌وجو، اسلایدر، چیپ‌ها، گریدِ ۲ ستونه ----
  Widget _mobile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: const [
              Bone.circle(size: 42),
              SizedBox(width: 12),
              Expanded(child: Center(child: Bone(width: 110, height: 16))),
              SizedBox(width: 12),
              Bone.circle(size: 42),
              SizedBox(width: 10),
              Bone.circle(size: 42),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Bone(width: 170, height: 28),
              SizedBox(height: 10),
              Bone(width: 230, height: 13),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Expanded(child: Bone(height: 50, radius: 25)),
              SizedBox(width: 10),
              Bone(width: 92, height: 50, radius: 25),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(32, 18, 32, 0),
          child: Bone(height: 200, radius: 24),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: const [
                Bone(width: 56, height: 44, radius: 22),
                SizedBox(width: 8),
                Bone(width: 88, height: 44, radius: 22),
                SizedBox(width: 8),
                Bone(width: 70, height: 44, radius: 22),
                SizedBox(width: 8),
                Bone(width: 64, height: 44, radius: 22),
                SizedBox(width: 8),
                Bone(width: 92, height: 44, radius: 22),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.68,
            children: List.generate(6, (_) => const _ProductBone()),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ---- دسکتاپ: هیروی تمام‌عرض، خوش‌آمدِ درشت، جست‌وجو، گریدِ ۴ ستونه ----
  Widget _desktop(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Bone(height: heroHeight, radius: 0),
        CenteredContent(
          withGutter: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 40, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Bone(width: 240, height: 36),
                    SizedBox(height: 12),
                    Bone(width: 300, height: 15),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Bone(width: 520, height: 50, radius: 25),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                  children: List.generate(8, (_) => const _ProductBone()),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }
}

/// اسکلتونِ یک کارتِ محصول، هم‌ساختارِ ProductGridCard.
class _ProductBone extends StatelessWidget {
  const _ProductBone();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.card,
        borderRadius: AppShapes.radius(AppShapes.rLg),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          AspectRatio(aspectRatio: 1, child: Bone(radius: 12)),
          SizedBox(height: 10),
          Bone(width: 90, height: 12),
          SizedBox(height: 6),
          Bone(width: 54, height: 12),
          SizedBox(height: 10),
          Bone(width: 70, height: 14),
        ],
      ),
    );
  }
}
