// views/screens/home_page.dart
import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_text_styles.dart';
import 'package:marketky/constant/urls.dart';
import 'package:marketky/models/course_models.dart';
import 'package:marketky/services/course_service.dart';
import 'package:marketky/views/widgets/app_network_image.dart';
import 'package:marketky/views/widgets/flashsale_countdown_tile.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/views/widgets/item_card.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/product/product_bloc.dart';
import '../../models/ProductModel.dart';
import '../../services/catalog_service.dart';
import '../../services/notification_service.dart';
import 'catalog_page.dart';
import 'course_detail_page.dart';

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

  /// اولین دوره‌ی واقعی، برای بخش «دوره‌های ویژه» طرح
  Course? _featuredCourse;

  reloadHomePage() {
    context.read<ProductBloc>().add(FetchProducts());
    context.read<CartBloc>().add(LoadCart(context));
    _loadFeaturedCourse();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String seconds = flashsaleCountdownDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    String minutes = flashsaleCountdownDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    String hours = flashsaleCountdownDuration.inHours.remainder(24).toString().padLeft(2, '0');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.obsidianBg,
        appBar: AppBar(
          backgroundColor: AppColor.obsidianBg,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: AppColor.onSurfaceVariant),
            onPressed: () {},
          ),
          title: Text('فوتبال لوکس',
              style: AppTextStyles.headlineMd.copyWith(color: AppColor.goldEnd)),
          actions: [
            FutureBuilder<int>(
              future: NotificationService.unreadCount(),
              builder: (context, snap) => IconButton(
                icon: Badge(
                  isLabelVisible: (snap.data ?? 0) > 0,
                  label: Text('${snap.data ?? 0}'),
                  child: const Icon(Icons.notifications_outlined,
                      color: AppColor.onSurfaceVariant),
                ),
                onPressed: () async {
                  await Navigator.of(context).pushNamed('/notifications');
                  if (mounted) setState(() {});
                },
              ),
            ),
          ],
        ),
        body: BlocConsumer<ProductBloc, ProductState>(
          listener: (context, state) {},
          builder: (context, state) {
            if (state is ProductLoading) {
              return _buildLoading();
            } else if (state is ProductError) {
              return _buildError(state.message, context);
            } else if (state is ProductLoaded) {
              final products = state.products;
              final flashProducts = products
                  .where((p) => (p.discountPercentage ?? 0) > 0)
                  .toList();
              final newestProducts =
                  CatalogService.apply(products, const CatalogFilter()).take(2).toList();

              return RefreshIndicator(
                color: AppColor.goldEnd,
                backgroundColor: AppColor.obsidianBg,
                onRefresh: () async {
                  reloadHomePage();
                },
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    _buildHero(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_featuredCourse != null) ...[
                            _buildFeaturedCourse(_featuredCourse!),
                            const SizedBox(height: 48),
                          ],
                          if (newestProducts.isNotEmpty) ...[
                            _buildNewestSection(newestProducts),
                            const SizedBox(height: 48),
                          ],
                          _buildCategorySection(products),
                        ],
                      ),
                    ),
                    if (flashProducts.isNotEmpty)
                      _buildFlashSaleSection(flashProducts, hours, minutes, seconds),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }
            return _buildLoading();
          },
        ),
      ),
    );
  }

  /// بخش هرو: همان کاروسل بنر واقعی قبلی، با پوسته‌ی تیره/طلایی
  Widget _buildHero() {
    final banners = NotificationService.banners();
    return SizedBox(
      height: 320,
      child: CarouselSlider(
        options: CarouselOptions(
          height: 320,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 5),
          viewportFraction: 1.0,
        ),
        items: banners
            .map((b) => Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(b.assetImage, fit: BoxFit.cover),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColor.obsidianBg,
                            AppColor.obsidianBg.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Align(
                        alignment: AlignmentDirectional.bottomStart,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(b.title, style: AppTextStyles.headlineMd.copyWith(color: AppColor.goldEnd)),
                            const SizedBox(height: 8),
                            Text(b.subtitle, style: AppTextStyles.bodyMd),
                          ],
                        ),
                      ),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  /// بخش «دوره‌های ویژه»: کارت اول دوره‌ی واقعی از CourseService
  Widget _buildFeaturedCourse(Course course) {
    final price = course.discountPercentage > 0
        ? (course.coursePrice * (1 - course.discountPercentage / 100)).toInt()
        : course.coursePrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('دوره‌های ویژه', style: AppTextStyles.headlineMd),
            const Spacer(),
            Text('مشاهده همه',
                style: AppTextStyles.labelSm.copyWith(color: AppColor.goldEnd)),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CourseDetailPage(id: course.id)),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.surfaceContainer,
              border: Border.all(color: AppColor.outlineVariantDark),
            ),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: AppNetworkImage(url: _abs(course.image)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sports_soccer,
                              color: AppColor.goldEnd, size: 16),
                          const SizedBox(width: 6),
                          Text(course.difficulty, style: AppTextStyles.labelSm),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(course.nameFarsi, style: AppTextStyles.headlineLg.copyWith(fontSize: 20)),
                      const SizedBox(height: 6),
                      Text(
                        course.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMd,
                      ),
                      const SizedBox(height: 12),
                      Text('${thousandSeparator(price)} تومان',
                          style: AppTextStyles.bodyMd
                              .copyWith(color: AppColor.goldEnd, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// بخش «جدیدترین‌ها»: ۲ محصول جدید واقعی
  Widget _buildNewestSection(List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('جدیدترین‌ها', style: AppTextStyles.headlineMd),
        const SizedBox(height: 8),
        ...products.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/product/${p.id}'),
                child: Container(
                  color: AppColor.surfaceContainer,
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: AppNetworkImage(url: '${URLs.baseUrl}${p.image ?? ''}'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.nameFarsi,
                                style: AppTextStyles.bodyLg
                                    .copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 8),
                            if ((p.price ?? 0) > 0)
                              Text('${thousandSeparator(p.price!)} تومان',
                                  style: AppTextStyles.bodyMd.copyWith(
                                      color: AppColor.goldEnd, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  /// دسته‌بندی‌ها از روی محصولات ساخته می‌شوند (بک‌اند endpoint اختصاصی ندارد)
  Widget _buildCategorySection(List<Product> products) {
    final categories = CatalogService.categoriesFrom(products);
    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('دسته‌بندی‌ها', style: AppTextStyles.headlineMd),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final c = categories[i];
              return _CategoryChip(
                label: '${c.nameFarsi} (${CatalogService.countInCategory(products, c.id)})',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CatalogPage(initialCategoryId: c.id),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFlashSaleSection(List<Product> products, String hours, String minutes, String seconds) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColor.surfaceContainer,
        border: Border.all(color: AppColor.outlineVariantDark),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('فروش ویژه',
                    style: AppTextStyles.headlineMd.copyWith(color: AppColor.goldEnd, fontSize: 18)),
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
            // کارت تیره تصویر مربعی دارد (بلندتر از نسخه ۰.۸ روشن)؛ ارتفاع
            // ردیف باید همان اندازه جا داشته باشد
            height: 320,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              separatorBuilder: (_, i) => const SizedBox(width: 16),
              itemBuilder: (_, index) {
                final p = products[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ItemCard(product: p, extraSize: 8, dark: true),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator(color: AppColor.goldEnd));
  }

  Widget _buildError(String message, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('خطا: $message',
              style: AppTextStyles.bodyMd.copyWith(color: AppColor.errorDark),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              reloadHomePage();
            },
            child: Text('تلاش مجدد',
                style: AppTextStyles.labelSm.copyWith(color: AppColor.goldEnd)),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppColor.outlineVariantDark),
        ),
        child: Text(label, style: AppTextStyles.labelSm),
      ),
    );
  }
}
