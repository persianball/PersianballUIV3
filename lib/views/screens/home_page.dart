// views/screens/home_page.dart
import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/views/widgets/custom_icon_button_widget.dart';
import 'package:marketky/views/widgets/flashsale_countdown_tile.dart';
import 'package:marketky/views/widgets/item_card.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/product/product_bloc.dart';
import '../../models/ProductModel.dart';
import '../../services/catalog_service.dart';
import 'cart_page.dart';
import 'catalog_page.dart';
import '../widgets/page_container.dart';

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

  reloadHomePage() {
    context.read<ProductBloc>().add(FetchProducts());
    context.read<CartBloc>().add(LoadCart(context));
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

    return Scaffold(
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) {
          // برای نمایش SnackBar در صورت خطا یا موفقیت
        },
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

            return RefreshIndicator(
              onRefresh: () async {
                reloadHomePage();
              },
              child: PageContainer(
                child: ListView(
                  physics: BouncingScrollPhysics(),
                  children: [
                    // بخش ۱ - هدر با کاروسل
                    _buildHeader(context),

                    // بخش ۲ - دسته‌بندی
                    _buildCategorySection(products),

                    // بخش ۳ - فروش ویژه
                    if (flashProducts.isNotEmpty)
                      _buildFlashSaleSection(flashProducts, hours, minutes, seconds),

                    // بخش ۴ - پیشنهاد روز
                    _buildRecommendationSection(products),
                  ],
                ),
              ),
            );
          }
          return _buildLoading();
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        CarouselSlider(
          items: [
            Image.asset('assets/images/background.jpg', fit: BoxFit.cover, width: double.infinity),
            Image.asset('assets/images/background.png', fit: BoxFit.cover, width: double.infinity),
            Image.asset('assets/images/background2.png', fit: BoxFit.cover, width: double.infinity),
          ],
          options: CarouselOptions(
            height: 190,
            autoPlay: true,
            autoPlayInterval: Duration(seconds: 5),
            autoPlayAnimationDuration: Duration(milliseconds: 800),
            scrollDirection: Axis.horizontal,
            viewportFraction: 1.0,
          ),
        ),
        Container(
          height: 190,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 26),
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Expanded(
                        child: Text(
                          'بهترینها را برای خود پیدا کنید.',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Estedad',
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      textDirection: TextDirection.ltr,
                      children: [
                        BlocBuilder<CartBloc,CartState>(
                          builder: (context,state) {
                            return CustomIconButtonWidget(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => CartPage()));
                              },
                              value: state is CartLoaded ? state.cart.results.length > 0?
                              state.cart.results[0].items.length
                                  : 0 : 0,
                              icon: SvgPicture.asset(
                                'assets/icons/Bag.svg',
                                color: Colors.white,
                              ),
                            );
                          }
                        ),
                        // SizedBox(width: 16),
                        // CustomIconButtonWidget(
                        //   onTap: () {
                        //     Navigator.of(context).push(MaterialPageRoute(
                        //         builder: (context) => MessagePage()));
                        //   },
                        //   value: 2,
                        //   icon: SvgPicture.asset(
                        //     'assets/icons/Chat.svg',
                        //     color: Colors.white,
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              // نوار جست‌وجو: ورود به صفحه کاتالوگ
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CatalogPage()),
                ),
                child: Container(
                  height: 44,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'جست‌وجو در محصولات…',
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              // DummySearchWidget1(
              //   onTap: () {
              //     Navigator.of(context).push(
              //       MaterialPageRoute(
              //         builder: (context) => SearchPage(),
              //       ),
              //     );
              //   },
              // ),
            ],
          ),
        ),
      ],
    );
  }

  /// دسته‌بندی‌ها از روی محصولات ساخته می‌شوند (بک‌اند endpoint اختصاصی ندارد)
  Widget _buildCategorySection(List<Product> products) {
    final categories = CatalogService.categoriesFrom(products);
    if (categories.isEmpty) return SizedBox.shrink();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'دسته‌بندی‌ها',
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CatalogPage()),
                  ),
                  child: Text(
                    'مشاهده همه',
                    style: TextStyle(fontFamily: 'Estedad', fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = categories[i];
                return ActionChip(
                  label: Text(
                    '${c.nameFarsi} (${CatalogService.countInCategory(products, c.id)})',
                    style: TextStyle(fontFamily: 'Estedad', fontSize: 12),
                  ),
                  backgroundColor: AppColor.primarySoft.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(color: AppColor.border),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CatalogPage(initialCategoryId: c.id),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashSaleSection(List<Product> products, String hours, String minutes, String seconds) {
    return Container(
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  'فروش ویژه',
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    FlashsaleCountdownTile(digit: hours[0]),
                    FlashsaleCountdownTile(digit: hours[1]),
                    Text(':', style: TextStyle(color: Colors.white, fontSize: 16)),
                    FlashsaleCountdownTile(digit: minutes[0]),
                    FlashsaleCountdownTile(digit: minutes[1]),
                    Text(':', style: TextStyle(color: Colors.white, fontSize: 16)),
                    FlashsaleCountdownTile(digit: seconds[0]),
                    FlashsaleCountdownTile(digit: seconds[1]),
                  ],
                ),
              ],
            ),
          ),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              height: 246,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                separatorBuilder: (_, i) => SizedBox(width: 16),
                itemBuilder: (_, index) {
                  final p = products[index];
                  // رنگ‌های پیش‌فرض کارت روی بک‌گراند سفید خوانا هستند
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: ItemCard(product: p, extraSize: 8),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection(List<Product> products) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(right: 16, top: 16),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'پیشنهاد روز برای شما...',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Estedad',
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: products.map((p) => Directionality(
              textDirection: TextDirection.rtl,
              child: ItemCard(product: p),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(child: LoadingAnimationWidget.discreteCircle(color: AppColor.primary, size: 40));
  }

  Widget _buildError(String message, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'خطا: $message',
            style: TextStyle(fontFamily: 'Estedad', color: Colors.red),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () {
              reloadHomePage();
            },
            child: Text('تلاش مجدد', style: TextStyle(fontFamily: 'Estedad')),
          ),
        ],
      ),
    );
  }
}