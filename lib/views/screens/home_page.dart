// views/screens/home_page.dart
import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/views/screens/empty_cart_page.dart';
import 'package:marketky/views/screens/message_page.dart';
import 'package:marketky/views/screens/search_page.dart';
import 'package:marketky/views/widgets/custom_icon_button_widget.dart';
import 'package:marketky/views/widgets/dummy_search_widget_1.dart';
import 'package:marketky/views/widgets/flashsale_countdown_tile.dart';
import 'package:marketky/views/widgets/item_card.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/product/product_bloc.dart';
import '../../models/ProductModel.dart';
import 'cart_page.dart';

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

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(FetchProducts());
    context.read<CartBloc>().add(LoadCart());
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
            final flashProducts = products.where((p) => p.discountPercentage != null).toList();

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ProductBloc>().add(FetchProducts());
              },
              child: ListView(
                physics: BouncingScrollPhysics(),
                children: [
                  // بخش ۱ - هدر با کاروسل
                  _buildHeader(context),

                  // بخش ۲ - دسته‌بندی
                  //_buildCategorySection(),

                  // بخش ۳ - فروش ویژه
                  if (flashProducts.isNotEmpty)
                    _buildFlashSaleSection(flashProducts, hours, minutes, seconds),

                  // بخش ۴ - پیشنهاد روز
                  _buildRecommendationSection(products),
                ],
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
              SizedBox(height: 22,),
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

  Widget _buildCategorySection() {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: AppColor.secondary,
      padding: EdgeInsets.only(top: 12, bottom: 24),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  'دسته‌بندی ها',
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'مشاهده بیشتر',
                    style: TextStyle(
                      fontFamily: 'Estedad',
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, i) => SizedBox(width: 16),
                itemBuilder: (_, i) => Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'دسته $i',
                      style: TextStyle(color: Colors.white, fontFamily: 'Estedad'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
              height: 310,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                separatorBuilder: (_, i) => SizedBox(width: 16),
                itemBuilder: (_, index) {
                  final p = products[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ItemCard(
                        product: p,
                        titleColor: AppColor.primarySoft,
                        priceColor: AppColor.accent,
                      ),
                      Container(
                        width: 180,
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    minHeight: 10,
                                    value: 0.6,
                                    color: AppColor.accent,
                                    backgroundColor: AppColor.border,
                                  ),
                                ),
                              ),
                            ),
                            Icon(Icons.local_fire_department, color: AppColor.accent),
                          ],
                        ),
                      ),
                    ],
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
              context.read<ProductBloc>().add(FetchProducts());
            },
            child: Text('تلاش مجدد', style: TextStyle(fontFamily: 'Estedad')),
          ),
        ],
      ),
    );
  }
}