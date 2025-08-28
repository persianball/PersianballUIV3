import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/core/model/Category.dart';
import 'package:marketky/core/model/Product.dart';
import 'package:marketky/core/services/CategoryService.dart';
import 'package:marketky/core/services/ProductService.dart';
import 'package:marketky/views/screens/empty_cart_page.dart';
import 'package:marketky/views/screens/message_page.dart';
import 'package:marketky/views/screens/search_page.dart';
import 'package:marketky/views/widgets/category_card.dart';
import 'package:marketky/views/widgets/custom_icon_button_widget.dart';
import 'package:marketky/views/widgets/dummy_search_widget_1.dart';
import 'package:marketky/views/widgets/flashsale_countdown_tile.dart';
import 'package:marketky/views/widgets/item_card.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../widgets/carousel_home_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Category> categoryData = CategoryService.categoryData;
  List<Product> productData = ProductService.productData;

  Timer? flashsaleCountdownTimer;
  Duration flashsaleCountdownDuration = Duration(
    hours: 24 - DateTime.now().hour,
    minutes: 60 - DateTime.now().minute,
    seconds: 60 - DateTime.now().second,
  );

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    Timer.periodic(Duration(seconds: 1), (_) {
      setCountdown();
    });
  }

  void setCountdown() {
    if (this.mounted) {
      setState(() {
        final seconds = flashsaleCountdownDuration.inSeconds - 1;

        if (seconds < 1) {
          flashsaleCountdownTimer?.cancel();
        } else {
          flashsaleCountdownDuration = Duration(seconds: seconds);
        }
      });
    }
  }

  @override
  void dispose() {
    flashsaleCountdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String seconds = flashsaleCountdownDuration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    String minutes = flashsaleCountdownDuration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    String hours = flashsaleCountdownDuration.inHours
        .remainder(24)
        .toString()
        .padLeft(2, '0');

    return Scaffold(
      body: ListView(
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        children: [
          // بخش ۱ - هدر
          // بخش ۱ - هدر با کاروسل در پس‌زمینه و محتوای ثابت
          Stack(
            children: [
              // پس‌زمینه: کاروسل اسلایدر
              CarouselSlider(
                items: [
                  Opacity(opacity: 0.5,child: Image.asset('assets/images/background.png', fit: BoxFit.cover, width: double.infinity,)),
                  Opacity(opacity: 0.5,child: Image.asset('assets/images/background2.png', fit: BoxFit.cover, width: double.infinity,))
                ],
                options: CarouselOptions(
                  height: 190,
                  autoPlay: true,
                  autoPlayInterval: Duration(seconds: 3),
                  autoPlayAnimationDuration: Duration(milliseconds: 400),
                  autoPlayCurve: Curves.easeInCirc,
                  scrollDirection: Axis.horizontal,
                  viewportFraction: 1.0,
                  pauseAutoPlayOnTouch: true,
                  // بدون رنگ تیره کردن، ولی اگر متن خوانا نبود، بعداً اضافه می‌کنیم
                ),
              ),

              Container(
                height: 190,
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                ),
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
                                'بهترین ست‌ها\nرا برای خود پیدا کنید.',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontFamily: 'Estedad',
                                  color: Colors.black,
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
                              CustomIconButtonWidget(
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => EmptyCartPage()));
                                },
                                value: 0,
                                icon: SvgPicture.asset(
                                  'assets/icons/Bag.svg',
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 16),
                              CustomIconButtonWidget(
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => MessagePage()));
                                },
                                value: 2,
                                icon: SvgPicture.asset(
                                  'assets/icons/Chat.svg',
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 22,),
                    DummySearchWidget1(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SearchPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // بخش ۲ - دسته‌بندی‌ها
          Container(
            width: MediaQuery.of(context).size.width,
            color: AppColor.secondary,
            padding: EdgeInsets.only(top: 12, bottom: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(
                        'دسته‌بندی',
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
                ),
                // لیست دسته‌ها
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: Container(
                    margin: EdgeInsets.only(top: 12),
                    height: 96,
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categoryData.length,
                      physics: BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      separatorBuilder: (context, index) {
                        return SizedBox(width: 16);
                      },
                      itemBuilder: (context, index) {
                        return CategoryCard(
                          data: categoryData[index],
                          onTap: () {},
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // بخش ۳ - فلش سیل (فروش ویژه)
          Container(
            margin: EdgeInsets.all(16),
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
                          Text(
                            ':',
                            style: TextStyle(
                              fontFamily: 'Estedad',
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          FlashsaleCountdownTile(digit: minutes[0]),
                          FlashsaleCountdownTile(digit: minutes[1]),
                          Text(
                            ':',
                            style: TextStyle(
                              fontFamily: 'Estedad',
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          FlashsaleCountdownTile(digit: seconds[0]),
                          FlashsaleCountdownTile(digit: seconds[1]),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 310,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: productData.length,
                    separatorBuilder: (context, index) => SizedBox(width: 16),
                    itemBuilder: (context, index) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ItemCard(
                          product: productData[index],
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
                                      value: 0.4,
                                      color: AppColor.accent,
                                      backgroundColor: AppColor.border,
                                    ),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.local_fire_department,
                                color: AppColor.accent,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // بخش ۴ - پیشنهاد روز
          Padding(
            padding: EdgeInsets.only(right: 16, top: 16),
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

          // لیست محصولات
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: List.generate(
                productData.length,
                    (index) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: ItemCard(
                    product: productData[index],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}