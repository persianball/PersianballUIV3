// views/screens/product_detail.dart
import 'package:circular_reveal_animation/circular_reveal_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/urls.dart';
import 'package:marketky/core/model/Review.dart';
import 'package:marketky/models/CartModel.dart';
import 'package:marketky/models/ColorWay.dart';
import 'package:marketky/models/ProductModel.dart';
import 'package:marketky/models/VideoDetail.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/views/screens/image_viewer.dart';
import 'package:marketky/views/screens/reviews_page.dart';
import 'package:marketky/views/widgets/custom_app_bar.dart';
import 'package:marketky/views/widgets/modals/add_to_cart_modal.dart';
import 'package:marketky/views/widgets/rating_tag.dart';
import 'package:marketky/views/widgets/review_tile.dart';
import 'package:marketky/views/widgets/selectable_circle_color.dart';
import 'package:marketky/views/widgets/selectable_circle_size.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_player/video_player.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/product_detail/product_detail_bloc.dart';
import '../../bloc/product_detail/product_detail_event.dart';
import '../../bloc/product_detail/product_detail_state.dart';
import '../widgets/video_player.dart';


class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({Key? key, required this.productId}) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> animation;
  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeIn,

    );


    context.read<ProductDetailBloc>().add(FetchProductDetail(widget.productId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      bottomNavigationBar: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {
          if (state is ProductDetailLoaded) {
            return Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColor.border, width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    margin: EdgeInsets.only(right: 14),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () {},
                      child: SvgPicture.asset('assets/icons/Chat.svg', color: Colors.white),
                    ),
                  ),
                  BlocBuilder<ProductDetailVariantBloc,ProductDetailState>(
                    builder: (context,variant_state) {
                      return Expanded(
                        child: SizedBox(
                          height: 64,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (context) => AddToCartModal(
                                  product: CartModel(
                                    id: state.product.id,
                                    name: "ست لباس پرشین بال",
                                    image: state.product.image!,
                                    price: state.product.price!,
                                    quantity: 1,
                                  ),
                                ),
                              );
                            },
                            child: Builder(
                              builder: (context) {
                                if(variant_state is ProductDetailChangedState){
                                  return Text(
                                    'افزودن به سبد',
                                    style: TextStyle(fontFamily: 'Estedad', fontWeight: FontWeight.w600, color: Colors.white, fontSize: 16),
                                  );
                                }else{
                                  return Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(
                                      'لطفا رنگ و اندازه را انتخاب کنید.',
                                      style: TextStyle(fontFamily: 'Estedad', fontWeight: FontWeight.w600, color: Colors.white, fontSize: 16),
                                    ),
                                  );
                                }

                              }
                            ),
                          ),
                        ),
                      );
                    }
                  ),
                ],
              ),
            );
          }
          return Container(); // در حالت لودینگ یا خطا، نمایش نده
        },
      ),
      body: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {

          if (state is ProductDetailLoading) {
            return _buildLoading();
          } else if (state is ProductDetailError) {
            return _buildError(state.message, context);
          } else if (state is ProductDetailLoaded) {
            if(state.product.image != null){
              state.product.images.add(state.product.image!);
            }
            if(state.product.variants.isNotEmpty &&  state.product.variants[0].sizeVariants.isNotEmpty){
              context.read<ProductDetailVariantBloc>().add(ChangeProductColorEvent(
                state.product.variants[0],state.product.variants[0].sizeVariants[0]
              ));
            }
            return _buildProductContent(state.product, context);
          }

          return _buildLoading();
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildError(String message, BuildContext context) {
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: TextStyle(fontFamily: 'Estedad', color: Colors.red),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () {
              context.read<ProductDetailBloc>().add(FetchProductDetail(widget.productId));
            },
            child: Text('تلاش مجدد', style: TextStyle(fontFamily: 'Estedad')),
          ),
        ],
      ),
    );
  }

  Widget _buildProductContent(ProductDetail product, BuildContext context) {
    final PageController imageController = PageController();
    return BlocBuilder<ProductDetailVariantBloc,ProductDetailState>(
      builder: (context, variant_state) {
        if(variant_state is ProductDetailChangedState){
          return ListView(
            physics: BouncingScrollPhysics(),
            children: [
              // بخش ۱ - تصویر و اپ‌بار
              GestureDetector(
                onTap: (){
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ImageViewer(
                        imageUrl: variant_state.productVariant.images.map((img) => '${URLs.baseUrl}$img').toList(),
                      ),
                    ),
                  );
                },
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ImageViewer(
                              imageUrl: variant_state.productVariant.images.map((img) => '${URLs.baseUrl}$img').toList(),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 360,

                        child: Column(
                          children: [
                            //video

                            Container(
                              width: MediaQuery.of(context).size.width,
                              height: 310,
                              child: PageView(
                                controller: imageController,
                                children: [

                                  product.video!=null && product.video!.isNotEmpty ? Container(child: VideoPlayerPage(videoDetail: new VideoDetail(hlsUrl: product.video!))):Container(),

                                  //images
                                  ...variant_state.productVariant.images.map((url) {
                                  final fullUrl = '${URLs.baseUrl}$url';

                                  return Image.network(
                                    fullUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (ctx, err, stack) => Image.asset('assets/images/placeholder.jpg'),
                                    loadingBuilder: (ctx, child, loading) {
                                      return loading == null ? child : Center(child: CircularProgressIndicator());
                                    },
                                  );
                                }).toList(),



                              ]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    CustomAppBar(
                      title: product.category.nameFarsi,
                      leftIcon: SvgPicture.asset('assets/icons/Arrow-left.svg'),
                      rightIcon: SvgPicture.asset('assets/icons/Bookmark.svg', color: Colors.black.withOpacity(0.5)),
                      leftOnTap: () => Navigator.of(context).pop(),
                      rightOnTap: () {},
                    ),
                    variant_state.productVariant.images.length > 0 ? Positioned(
                      bottom: 16,
                      child: SmoothPageIndicator(
                        controller: imageController,
                        count:  (product.video!=null && product.video!.isNotEmpty) ? variant_state.productVariant.images.length +  1 : variant_state.productVariant.images.length,
                        effect: ExpandingDotsEffect(
                          dotColor: AppColor.primary.withOpacity(0.2),
                          activeDotColor: AppColor.primary.withOpacity(0.2),
                          dotHeight: 8,
                        ),
                      )
                      ,
                    ):Positioned(
                      bottom: 1,
                      child: Container(
                        child: Image.asset(
                          "assets/images/placeholder.jpg",
                          fit: BoxFit.fitWidth,
                          width: MediaQuery.of(context).size.width,
                        ),
                      ),
                    ),
                  ],
                ),
              ),



              // بخش ۲ - اطلاعات محصول
              Container(
                decoration: BoxDecoration(
                  color: Color(int.parse("ff"+ variant_state.productVariant.colorRgb! ?? "00000000",radix: 16))
                      .withOpacity(0.1)
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.nameFarsi ?? '',
                              style: TextStyle(
                                fontFamily: 'Estedad',
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColor.secondary,
                              ),
                            ),
                          ),
                          Directionality(
                              textDirection: TextDirection.ltr,
                              child: RatingTag(value: product.avgRate, margin: EdgeInsets.only(left: 10))),
                        ],
                      ),
                    ),
                    if (product.price != null)
                      Container(
                        margin: EdgeInsets.only(top: 8, bottom: 14),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            '${thousandSeparator(product.price!)} تومان',
                            style: TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColor.primary,
                            ),
                          ),
                        ),
                      ),

                    // بخش ۳ - انتخاب رنگ
                    if (product.variants.isNotEmpty)
                      Align(
                        alignment: AlignmentGeometry.centerRight,
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            margin: EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'رنگ',
                                  style: TextStyle(
                                    fontFamily: 'Estedad',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.secondary,
                                  ),
                                ),
                                SizedBox(height: 12),
                                SelectableCircleColor(
                                  colorWay: product.variants
                                      .map((v) => ColorWay(
                                    color: Color(int.parse("ff"+v.colorRgb! ??"00000000",radix: 16)),
                                    name: v.color??"ناشناس",
                                    imageUrl: v.image != null ? '${URLs.baseUrl}${v.image}' : null,

                                  ))
                                      .toList(),
                                  onColorSelected: (int vIndex) {
                                    print(product.variants[vIndex]);
                                    print(product.variants[vIndex].sizeVariants);
                                    if(product.variants.isNotEmpty && product.variants[vIndex].sizeVariants.isNotEmpty){
                                      context.read<ProductDetailVariantBloc>().add(ChangeProductColorEvent(product.variants[vIndex],product.variants[vIndex].sizeVariants[0]));
                                    }



                                    // if (imageUrl != null) {
                                    //   // پیدا کردن ایندکس تصویر در لیست
                                    //   final index = product.images.indexWhere((img) => '${URLs.baseUrl}$img' == imageUrl);
                                    //   if (index != -1 && index < product.images.length) {
                                    //     imageController.animateToPage(
                                    //       index,
                                    //       duration: Duration(milliseconds: 300),
                                    //       curve: Curves.easeInOut,
                                    //     );
                                    //   }
                                    // }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // بخش ۴ - انتخاب سایز (در صورت وجود)
                    if (variant_state.productVariant.sizeVariants.isNotEmpty)
                      Align(
                        alignment: AlignmentGeometry.centerRight,
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            margin: EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'اندازه',
                                  style: TextStyle(
                                    fontFamily: 'Estedad',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.secondary,
                                  ),
                                ),
                                SizedBox(height: 12),
                                SelectableCircleSize(
                                  productSize: variant_state.productVariant.sizeVariants
                                      .map((s) => s.size)

                                      .toList(),
                                  onSizeSelected: (int sizeVariantIndex) {
                                    context.read<ProductDetailVariantBloc>().add(
                                      ChangeProductColorEvent(variant_state.productVariant, variant_state.productVariant.sizeVariants[sizeVariantIndex])
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),


                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        product.description ?? '',
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          color: AppColor.secondary.withOpacity(0.7),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ],
                ),
              ),





              // بخش ۵ - نظرات
              Directionality(
                textDirection: TextDirection.rtl,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExpansionTile(
                        initiallyExpanded: false,
                        title: Text(
                          'نظرات',
                          style: TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColor.secondary,
                          ),
                        ),
                        children: [
                          // در اینجا می‌تونی لیست نظرات واقعی رو بیاری
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: product.comments.length,
                            itemBuilder: (ctx, i) => ReviewTile(review: Review(photoUrl: "assets/images/avatar_for_comments.png", name: " ${i} : ", review: product.comments[i].text , rating: 5)),
                          ),
                          Container(
                            margin: EdgeInsets.only(left: 52, top: 12, bottom: 6),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => ReviewsPage(reviews: [])),
                                );
                              },
                              child: Text(
                                'مشاهده همه نظرات',
                                style: TextStyle(fontFamily: 'Estedad', color: AppColor.secondary, fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.primarySoft,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                            ),
                          )
                        ],
                      ),
                      ExpansionTile(
                        initiallyExpanded: false,
                        title: Text(
                          'توضیحات تکمیلی',
                          style: TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColor.secondary,
                          ),
                        ),
                        children: [
                          Html(data: product.editor),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }else{
          // return ListView(
          //   physics: BouncingScrollPhysics(),
          //   children: [
          //     // بخش ۱ - تصویر و اپ‌بار
          //     GestureDetector(
          //       onTap: (){
          //         Navigator.of(context).push(
          //           MaterialPageRoute(
          //             builder: (context) => ImageViewer(
          //               imageUrl: product.images.map((img) => '${URLs.baseUrl}$img').toList(),
          //             ),
          //           ),
          //         );
          //       },
          //       child: Stack(
          //         alignment: Alignment.topCenter,
          //         children: [
          //           GestureDetector(
          //             onTap: () {
          //               Navigator.of(context).push(
          //                 MaterialPageRoute(
          //                   builder: (context) => ImageViewer(
          //                     imageUrl: product.images.map((img) => '${URLs.baseUrl}$img').toList(),
          //                   ),
          //                 ),
          //               );
          //             },
          //             child: Column(
          //               children: [
          //                 //video
          //                 Container(child: VideoPlayerPage(videoDetail: new VideoDetail(hlsUrl: product.video!))),
          //                 // Container(
          //                 //   width: MediaQuery.of(context).size.width,
          //                 //   height: 310,
          //                 //   child: PageView(
          //                 //     controller: imageController,
          //                 //     children: [
          //                 //
          //                 //
          //                 //
          //                 //       //images
          //                 //       ...product.images.map((url) {
          //                 //       final fullUrl = '${URLs.baseUrl}$url';
          //                 //
          //                 //       return Image.network(
          //                 //         fullUrl,
          //                 //         fit: BoxFit.contain,
          //                 //         errorBuilder: (ctx, err, stack) => Image.asset('assets/images/placeholder.jpg'),
          //                 //         loadingBuilder: (ctx, child, loading) {
          //                 //           return loading == null ? child : Center(child: CircularProgressIndicator());
          //                 //         },
          //                 //       );
          //                 //     }).toList(),
          //                 //
          //                 //
          //                 //
          //                 //   ]),
          //                 // ),
          //               ],
          //             ),
          //           ),
          //           CustomAppBar(
          //             title: product.category.nameFarsi,
          //             leftIcon: SvgPicture.asset('assets/icons/Arrow-left.svg'),
          //             rightIcon: SvgPicture.asset('assets/icons/Bookmark.svg', color: Colors.black.withOpacity(0.5)),
          //             leftOnTap: () => Navigator.of(context).pop(),
          //             rightOnTap: () {},
          //           ),
          //           product.images.length > 0 ? Positioned(
          //             bottom: 16,
          //             child: SmoothPageIndicator(
          //               controller: imageController,
          //               count: product.images.length,
          //               effect: ExpandingDotsEffect(
          //                 dotColor: AppColor.primary.withOpacity(0.2),
          //                 activeDotColor: AppColor.primary.withOpacity(0.2),
          //                 dotHeight: 8,
          //               ),
          //             )
          //             ,
          //           ):Positioned(
          //             bottom: 1,
          //             child: Container(
          //               child: Image.asset(
          //                 "assets/images/placeholder.jpg",
          //                 fit: BoxFit.fitWidth,
          //                 width: MediaQuery.of(context).size.width,
          //               ),
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //
          //     // بخش ۲ - اطلاعات محصول
          //     Container(
          //       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          //       child: Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           Directionality(
          //             textDirection: TextDirection.rtl,
          //             child: Row(
          //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //               children: [
          //                 Expanded(
          //                   child: Text(
          //                     product.nameFarsi ?? '',
          //                     style: TextStyle(
          //                       fontFamily: 'Estedad',
          //                       fontSize: 24,
          //                       fontWeight: FontWeight.w700,
          //                       color: AppColor.secondary,
          //                     ),
          //                   ),
          //                 ),
          //                 Directionality(
          //                     textDirection: TextDirection.ltr,
          //                     child: RatingTag(value: product.avgRate, margin: EdgeInsets.only(left: 10))),
          //               ],
          //             ),
          //           ),
          //           if (product.price != null)
          //             Container(
          //               margin: EdgeInsets.only(top: 8, bottom: 14),
          //               child: Directionality(
          //                 textDirection: TextDirection.rtl,
          //                 child: Text(
          //                   '${thousandSeparator(product.price!)} تومان',
          //                   style: TextStyle(
          //                     fontFamily: 'Estedad',
          //                     fontSize: 16,
          //                     fontWeight: FontWeight.w700,
          //                     color: AppColor.primary,
          //                   ),
          //                 ),
          //               ),
          //             ),
          //
          //           // بخش ۳ - انتخاب رنگ
          //           if (product.variants.isNotEmpty)
          //             Align(
          //               alignment: AlignmentGeometry.centerRight,
          //               child: Directionality(
          //                 textDirection: TextDirection.rtl,
          //                 child: Container(
          //                   padding: EdgeInsets.symmetric(horizontal: 16),
          //                   margin: EdgeInsets.only(bottom: 20),
          //                   child: Column(
          //                     crossAxisAlignment: CrossAxisAlignment.start,
          //                     children: [
          //                       Text(
          //                         'رنگ',
          //                         style: TextStyle(
          //                           fontFamily: 'Estedad',
          //                           fontSize: 18,
          //                           fontWeight: FontWeight.w600,
          //                           color: AppColor.secondary,
          //                         ),
          //                       ),
          //                       SizedBox(height: 12),
          //                       SelectableCircleColor(
          //                         colorWay: product.variants
          //                             .map((v) => ColorWay(
          //                           color: Color(int.parse("ff"+v.colorRgb! ??"00000000",radix: 16)),
          //                           name: v.color??"ناشناس",
          //                           imageUrl: v.image != null ? '${URLs.baseUrl}${v.image}' : null,
          //
          //                         )).toList(),
          //                         onColorSelected: (int vIndex) {
          //
          //                           context.read<ProductDetailVariantBloc>().add(ChangeProductColorEvent(product.variants[vIndex],product.variants[vIndex].sizeVariants[0]));
          //
          //
          //                           // if (imageUrl != null) {
          //                           //   // پیدا کردن ایندکس تصویر در لیست
          //                           //   final index = product.images.indexWhere((img) => '${URLs.baseUrl}$img' == imageUrl);
          //                           //   if (index != -1 && index < product.images.length) {
          //                           //     imageController.animateToPage(
          //                           //       index,
          //                           //       duration: Duration(milliseconds: 300),
          //                           //       curve: Curves.easeInOut,
          //                           //     );
          //                           //   }
          //                           // }
          //                         },
          //                       ),
          //                     ],
          //                   ),
          //                 ),
          //               ),
          //             ),
          //
          //           Directionality(
          //             textDirection: TextDirection.rtl,
          //             child: Text(
          //               product.description ?? '',
          //               style: TextStyle(
          //                 fontFamily: 'Estedad',
          //                 color: AppColor.secondary.withOpacity(0.7),
          //                 height: 1.5,
          //               ),
          //               textAlign: TextAlign.justify,
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //
          //
          //
          //
          //     // بخش ۴ - انتخاب سایز (در صورت وجود)
          //     // (نیاز به تعریف سایز در مدل دارید — در صورت نیاز اضافه می‌شود)
          //
          //     // بخش ۵ - نظرات
          //     Directionality(
          //       textDirection: TextDirection.rtl,
          //       child: Container(
          //         padding: EdgeInsets.symmetric(horizontal: 16),
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             ExpansionTile(
          //               initiallyExpanded: true,
          //               title: Text(
          //                 'نظرات',
          //                 style: TextStyle(
          //                   fontFamily: 'Estedad',
          //                   fontSize: 18,
          //                   fontWeight: FontWeight.w600,
          //                   color: AppColor.secondary,
          //                 ),
          //               ),
          //               children: [
          //                 // در اینجا می‌تونی لیست نظرات واقعی رو بیاری
          //                 ListView.builder(
          //                   shrinkWrap: true,
          //                   physics: NeverScrollableScrollPhysics(),
          //                   itemCount: product.comments.length,
          //                   itemBuilder: (ctx, i) => ReviewTile(review: Review(photoUrl: "assets/images/avatar_for_comments.png", name: " ${i} : ", review: product.comments[i].text , rating: 5)),
          //                 ),
          //                 Container(
          //                   margin: EdgeInsets.only(left: 52, top: 12, bottom: 6),
          //                   child: ElevatedButton(
          //                     onPressed: () {
          //                       Navigator.of(context).push(
          //                         MaterialPageRoute(builder: (context) => ReviewsPage(reviews: [])),
          //                       );
          //                     },
          //                     child: Text(
          //                       'مشاهده همه نظرات',
          //                       style: TextStyle(fontFamily: 'Estedad', color: AppColor.secondary, fontWeight: FontWeight.w600),
          //                     ),
          //                     style: ElevatedButton.styleFrom(
          //                       backgroundColor: AppColor.primarySoft,
          //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          //                       elevation: 0,
          //                     ),
          //                   ),
          //                 )
          //               ],
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ],
          // );
          return Center(child: Text("محصولی یافت نشد."),);
        }

      }
    );
  }
}