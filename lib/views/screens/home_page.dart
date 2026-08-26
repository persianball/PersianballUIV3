// views/screens/home_page.dart
import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/constant/app_text_styles.dart';
import 'package:marketky/constant/urls.dart';
import 'package:marketky/models/course_models.dart';
import 'package:marketky/services/auth_service.dart';
import 'package:marketky/services/course_service.dart';
import 'package:marketky/views/widgets/app_buttons.dart';
import 'package:marketky/views/widgets/app_network_image.dart';
import 'package:marketky/views/widgets/flashsale_countdown_tile.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/views/widgets/product_grid_card.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/product/product_bloc.dart';
import '../../models/ProductModel.dart';
import '../../services/catalog_service.dart';
import '../../services/notification_service.dart';
import 'catalog_page.dart';
import 'course_detail_page.dart';
import 'profile_page.dart' show UserService;
import 'package:marketky/views/widgets/motion.dart';

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

  reloadHomePage() {
    context.read<ProductBloc>().add(FetchProducts());
    context.read<CartBloc>().add(LoadCart(context));
    _loadFeaturedCourse();
    _loadUserName();
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
    flashsaleCountdownTimer?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.milk,
        body: SafeArea(
          bottom: false,
          child: BlocConsumer<ProductBloc, ProductState>(
            listener: (context, state) {},
            builder: (context, state) {
              if (state is ProductLoading) return _buildLoading();
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
                  onRefresh: () async => reloadHomePage(),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader()),
                      SliverToBoxAdapter(child: _buildGreeting()),
                      SliverToBoxAdapter(child: _buildSearchRow()),
                      if (categories.isNotEmpty)
                        SliverToBoxAdapter(
                            child: _buildCategoryChips(all, categories)),
                      _buildProductSliver(results),
                      SliverToBoxAdapter(child: _buildHero()),
                      if (_featuredCourse != null)
                        SliverToBoxAdapter(
                            child: _buildFeaturedCourse(_featuredCourse!)),
                      if (flashProducts.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _buildFlashSaleSection(
                              flashProducts, hours, minutes, seconds),
                        ),
                      // فضای خالی زیر لیست تا نوار ناوبری شناور روی محتوا نیفتد
                      const SliverToBoxAdapter(child: SizedBox(height: 110)),
                    ],
                  ),
                );
              }
              return _buildLoading();
            },
          ),
        ),
      ),
    );
  }

  // ==== هدر: آواتار | عنوان | زنگ + سبد ====

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const ShapeDecoration(
              shape: CircleBorder(),
              shadows: AppColor.cardShadow,
              image: DecorationImage(
                image: AssetImage('assets/images/avatar_for_comments.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'پرشین شاپ',
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

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _userName == null ? 'سلام، خوش آمدید' : 'سلام $_userName',
            style: AppTextStyles.headlineLg.copyWith(
              fontSize: 26,
              color: AppColor.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'بهترین‌ها را برای خود پیدا کنید.',
            style: AppTextStyles.bodyMd
                .copyWith(fontSize: 13, color: AppColor.inkMuted),
          ),
        ],
      ),
    );
  }

  // ==== جست‌وجو + دکمه‌ی فیلتر ====

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
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
      ),
    );
  }

  // ==== چیپ دسته‌بندی ====

  Widget _buildCategoryChips(List<Product> all, List<Category> categories) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 20),
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _CategoryPill(
            label: 'همه',
            selected: _filter.categoryId == null,
            onTap: () =>
                setState(() => _filter = _filter.copyWith(clearCategory: true)),
          ),
          ...categories.map((c) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CategoryPill(
                label: '${c.nameFarsi} (${CatalogService.countInCategory(all, c.id)})',
                selected: _filter.categoryId == c.id,
                onTap: () =>
                    setState(() => _filter = _filter.copyWith(categoryId: c.id)),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==== گرید محصولات ====

  Widget _buildProductSliver(List<Product> results) {
    if (results.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
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
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          // چیدمان واکنش‌گرا: روی عرض‌های ۳۲۰ تا ۴۳۰ دو ستون، بالاتر بیشتر
          final width = constraints.crossAxisExtent;
          final columns = width >= 620 ? 3 : 2;
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.68,
            ),
            delegate: SliverChildBuilderDelegate(
              // ورود پلکانی کارت‌ها؛ تأخیر سقف دارد تا اسکرول به پایین
              // لیست بلند، منتظر انیمیشن نماند.
              (context, i) => FadeSlideIn(
                delay: Duration(milliseconds: 40 * (i % 8)),
                child: ProductGridCard(product: results[i]),
              ),
              childCount: results.length,
            ),
          );
        },
      ),
    );
  }

  // ==== بنرها (داده‌ی موجود NotificationService.banners) ====

  Widget _buildHero() {
    final banners = NotificationService.banners();
    if (banners.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Container(
        decoration: ShapeDecoration(
          shape: AppShapes.border(AppShapes.rXl),
          shadows: AppColor.floatingShadow,
        ),
        child: SquircleClip(
          radius: AppShapes.rXl,
          child: SizedBox(
            height: 190,
            child: CarouselSlider(
              options: CarouselOptions(
                height: 190,
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
                            padding: const EdgeInsets.all(18),
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
                                  const SizedBox(height: 10),
                                  Text(b.title,
                                      style: AppTextStyles.headlineMd.copyWith(
                                          color: Colors.white, fontSize: 19)),
                                  const SizedBox(height: 4),
                                  Text(b.subtitle,
                                      style: AppTextStyles.bodyMd.copyWith(
                                          color: Colors.white70, fontSize: 12)),
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

  Widget _buildFeaturedCourse(Course course) {
    final price = course.discountPercentage > 0
        ? (course.coursePrice * (1 - course.discountPercentage / 100)).toInt()
        : course.coursePrice;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('دوره‌های ویژه'),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CourseDetailPage(id: course.id)),
            ),
            child: Container(
              decoration: ShapeDecoration(
                color: AppColor.card,
                shape: AppShapes.border(AppShapes.rLg),
                shadows: AppColor.cardShadow,
              ),
              child: SquircleClip(
                radius: AppShapes.rLg,
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: AppNetworkImage(url: _abs(course.image)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(height: 8),
                          Text(course.nameFarsi,
                              style: AppTextStyles.headlineMd
                                  .copyWith(fontSize: 16, color: AppColor.ink)),
                          const SizedBox(height: 4),
                          Text(
                            course.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMd.copyWith(fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text('${thousandSeparator(price)} تومان',
                                  style: AppTextStyles.bodyMd.copyWith(
                                      fontSize: 14,
                                      color: AppColor.ink,
                                      fontWeight: FontWeight.w800)),
                              const Spacer(),
                              GradientButton(
                                label: 'مشاهده دوره',
                                expand: false,
                                height: 38,
                                fontSize: 12,
                                icon: const Icon(Icons.arrow_back_rounded),
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          CourseDetailPage(id: course.id)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==== فروش ویژه ====

  Widget _buildFlashSaleSection(
      List<Product> products, String hours, String minutes, String seconds) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      decoration: ShapeDecoration(
        color: AppColor.card,
        shape: AppShapes.border(AppShapes.rLg),
        shadows: AppColor.cardShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
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
            height: 268,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
              itemCount: products.length,
              separatorBuilder: (_, i) => const SizedBox(width: 12),
              itemBuilder: (_, index) => SizedBox(
                width: 165,
                child: ProductGridCard(product: products[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
        child: CircularProgressIndicator(color: AppColor.pitchGreen));
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

/// چیپ دسته‌بندی قرصی: انتخاب‌شده با پس‌زمینه‌ی گرادیان برند، بقیه خاکستری ملایم
class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        decoration: ShapeDecoration(
          color: selected ? null : AppColor.cardMuted,
          gradient: selected ? AppColor.greenGradient : null,
          shape: AppShapes.pill,
          shadows: selected ? AppColor.greenShadow : null,
        ),
        child: Material(
          color: Colors.transparent,
          shape: AppShapes.pill,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : AppColor.inkMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
