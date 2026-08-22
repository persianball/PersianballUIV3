// views/screens/product_detail.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_text_styles.dart';
import 'package:marketky/services/wishlist_service.dart';
import 'package:marketky/services/analytics_service.dart';
import 'package:marketky/constant/urls.dart';
import 'package:marketky/core/model/Review.dart';
import 'package:marketky/models/CartModel.dart';
import 'package:marketky/models/ColorWay.dart';
import 'package:marketky/models/ProductModel.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/utils/html_dark_theme.dart';
import 'package:marketky/views/screens/image_viewer.dart';
import 'package:marketky/views/screens/reviews_page.dart';
import 'package:marketky/views/widgets/detail_tabs.dart';
import 'package:marketky/views/widgets/html_description_image.dart';
import 'package:marketky/views/widgets/modals/add_to_cart_modal.dart';
import 'package:marketky/views/widgets/product_reviews_section.dart';
import 'package:marketky/views/widgets/rating_tag.dart';
import 'package:marketky/views/widgets/review_tile.dart';
import 'package:marketky/views/widgets/selectable_circle_color.dart';
import 'package:marketky/views/widgets/selectable_circle_size.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/product_detail/product_detail_bloc.dart';
import '../../bloc/product_detail/product_detail_event.dart';
import '../../bloc/product_detail/product_detail_state.dart';
import '../widgets/ProCarousel.dart';
import '../widgets/similar_product_card.dart';


class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({Key? key, required this.productId}) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> with SingleTickerProviderStateMixin {
  /// اسلاید فعلی گالری تا با تعویض رنگ همان اسلاید حفظ شود
  int _carouselIndex = 0;

  /// وضعیت علاقه‌مندی این محصول
  bool _isFavorite = false;

  Future<void> _loadFavorite() async {
    final fav = await WishlistService.isFavorite(widget.productId);
    if (mounted) setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    final now = await WishlistService.toggle(widget.productId);
    if (!mounted) return;
    setState(() => _isFavorite = now);
    if (now) AnalyticsService.addToWishlist(productId: widget.productId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          now ? 'به علاقه‌مندی‌ها اضافه شد' : 'از علاقه‌مندی‌ها حذف شد',
          style: const TextStyle(fontFamily: 'Estedad'),
        ),
      ),
    );
  }

  /// اشتراک‌گذاری لینک محصول (دیپ‌لینک همین اپ)
  Future<void> _shareProduct(String productName) async {
    final link = '${URLs.baseUrl}/product/${widget.productId}';
    final text = Uri.encodeComponent('$productName\n$link');
    // بدون وابستگی جدید: ارسال از طریق پیام‌رسان‌های نصب‌شده
    final uri = Uri.parse('sms:?body=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      await Clipboard.setData(ClipboardData(text: '$productName\n$link'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لینک محصول در کلیپ‌بورد کپی شد',
                style: TextStyle(fontFamily: 'Estedad')),
          ),
        );
      }
    }
  }

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
    _loadFavorite();
    // ثبت در بازدیدهای اخیر و آنالیتیکس
    WishlistService.markViewed(widget.productId);
    AnalyticsService.viewItem(productId: widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.obsidianBg,
      extendBodyBehindAppBar: true,
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: BlocBuilder<ProductDetailBloc, ProductDetailState>(
          builder: (context, state) {
            if (state is ProductDetailLoaded) {
              return Container(
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColor.obsidianBg,
                  border: Border(top: BorderSide(color: AppColor.outlineVariantDark, width: 1)),
                ),
                child: Row(
                  children: [
                    BlocBuilder<ProductDetailVariantBloc,ProductDetailState>(
                      builder: (context,variant_state) {
                        return BlocListener<CartBloc,CartState>(
                          listener: (context, state) {
                            if (state is CartItemAdded) {
                              // نمایش دیالوگ موفقیت
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColor.obsidianBg,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(color: AppColor.outlineVariantDark),
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, color: AppColor.successDark, size: 64),
                                      SizedBox(height: 16),
                                      Text(
                                        state.message,
                                        style: TextStyle(
                                          fontFamily: 'Estedad',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.onSurface,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(ctx).pop(),
                                        child: Text('باشه', style: TextStyle(fontFamily: 'Estedad',color: AppColor.onGold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColor.goldEnd,
                                          shape: const RoundedRectangleBorder(),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            }

                            if (state is CartError) {
                              // نمایش خطا
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(state.message, style: TextStyle(fontFamily: 'Estedad')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child:  Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 64,
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      margin: EdgeInsets.only(right: 14),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColor.surfaceContainerHigh,
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(color: AppColor.outlineVariantDark),
                                            borderRadius: BorderRadius.zero,
                                          ),
                                          elevation: 0,
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pushNamed('/cart');
                                        },
                                        child: SvgPicture.asset('assets/icons/Bag.svg', color: AppColor.goldEnd,fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: SizedBox(
                                      height: 64,

                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColor.goldEnd,
                                          shape: const RoundedRectangleBorder(),
                                          elevation: 0,
                                        ),
                                        onPressed: () {
                                          // جلوگیری از افزودن کالای ناموجود
                                          final selectedSize =
                                              (variant_state is ProductDetailSizeChanged)
                                                  ? variant_state.productSize
                                                  : (variant_state is ProductDetailChangedState
                                                      ? variant_state.productSize
                                                      : null);
                                          if (selectedSize != null &&
                                              !selectedSize.inStock) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'این سایز ناموجود است',
                                                    style: TextStyle(
                                                        fontFamily: 'Estedad')),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }
                                          showModalBottomSheet(
                                            context: context,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => AddToCartModal(
                                              cartItem:
                                              (variant_state is ProductDetailSizeChanged) ?
                                                CartItem(
                                                id: variant_state.productSize.id,
                                                name: state.product.nameFarsi??"",
                                                image: variant_state.productVariant.image??"",
                                                price: variant_state.productSize.price,
                                                quantity: 1, productId: state.product.id,
                                                discountPrice: variant_state.productSize.discountPercentage
                                              ):
                                              (variant_state is ProductDetailChangedState) ?
                                              CartItem(
                                                  id: variant_state.productSize!.id,
                                                  name: state.product.nameFarsi??"",
                                                  image: variant_state.productVariant.image??"",
                                                  price: variant_state.productSize!.price,
                                                  quantity: 1, productId: state.product.id,
                                                  discountPrice: variant_state.productSize!.discountPercentage
                                              ):
                                              CartItem(
                                                id: state.product.id,
                                                name: state.product.nameFarsi??"",
                                                image: state.product.image??"",
                                                price: state.product.price!,
                                                quantity: 1, productId: state.product.id,
                                                discountPrice: state.product.discountPercentage,
                                            ),)
                                          );
                                        },
                                        child: Builder(
                                          builder: (context) {
                                            if(variant_state is ProductDetailSizeChanged){
                                              return Text(
                                                'افزودن به سبد',
                                                style: TextStyle(fontFamily: 'Estedad', fontWeight: FontWeight.w600, color: AppColor.onGold, fontSize: 16),
                                              );
                                            }else{
                                              return Directionality(
                                                textDirection: TextDirection.rtl,
                                                child: Text(
                                                  'لطفا رنگ و اندازه را انتخاب کنید.',
                                                  style: TextStyle(fontFamily: 'Estedad', fontWeight: FontWeight.w600, color: AppColor.onGold, fontSize: 16),
                                                ),
                                              );
                                            }

                                          }
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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

            if (state.product.variants.isNotEmpty &&
                state.product.variants[0].sizeVariants.isNotEmpty) {
              // انتخاب اولیه روی اولین سایز موجود، نه صرفاً سایز اول
              final initialSize = firstAvailableSizeVariant(
                  state.product.variants[0].sizeVariants)!;
              context.read<ProductDetailVariantBloc>().add(
                  ChangeProductColorEvent(
                      state.product.variants[0], initialSize));
            }
            return _buildProductContent(state.product, context);
          }

          return _buildLoading();
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      color: AppColor.obsidianBg,
      child: const Center(child: CircularProgressIndicator(color: AppColor.goldEnd)),
    );
  }

  Widget _buildError(String message, BuildContext context) {
    return Container(
      color: AppColor.obsidianBg,
      child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: TextStyle(fontFamily: 'Estedad', color: AppColor.errorDark),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () {
              context.read<ProductDetailBloc>().add(FetchProductDetail(widget.productId));
            },
            child: Text('تلاش مجدد',
                style: TextStyle(fontFamily: 'Estedad', color: AppColor.goldEnd)),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildProductContent(ProductDetail product, BuildContext context) {
    return BlocBuilder<ProductDetailVariantBloc,ProductDetailState>(
      builder: (context, variant_state) {
        if(variant_state is ProductDetailSizeChanged){
          return ListView(
            physics: BouncingScrollPhysics(),
            children: [
              // بخش ۱ - تصویر و اپ‌بار
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ImageViewer(
                            imageUrl: variant_state.productVariant.images.map((
                                img) => '${URLs.baseUrl}$img').toList(),
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
                            builder: (context) =>
                                ImageViewer(
                                  imageUrl: variant_state.productVariant.images
                                      .map((img) => '${URLs.baseUrl}$img')
                                      .toList(),
                                ),
                          ),
                        );
                      },
                      child: Container(
                        width: MediaQuery
                            .of(context)
                            .size
                            .width,


                        child: Column(
                          children: [
                            //video

                            Container(
                                width: MediaQuery
                                    .of(context)
                                    .size
                                    .width,

                                // child: PageView(
                                //   controller: imageController,
                                //   children: [
                                //
                                //     product.video!=null && product.video!.isNotEmpty ? Container(child: VideoPlayerPage(videoDetail: new VideoDetail(hlsUrl: product.video!))):Container(),
                                //
                                //     //images
                                //     ...variant_state.productVariant.images.map((url) {
                                //     final fullUrl = '${URLs.baseUrl}$url';
                                //
                                //     return Image.network(
                                //       fullUrl,
                                //       fit: BoxFit.contain,
                                //       errorBuilder: (ctx, err, stack) => Image.asset('assets/images/placeholder.jpg'),
                                //       loadingBuilder: (ctx, child, loading) {
                                //         return loading == null ? child : Center(child: CircularProgressIndicator());
                                //       },
                                //     );
                                //   }).toList(),
                                //
                                //
                                //
                                // ]),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 90),
                                    // تعویض نرم گالری هنگام تغییر رنگ:
                                    // محو‌شدن همراه با کمی بزرگ‌نمایی (fade through)
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 320),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      transitionBuilder: (child, animation) =>
                                          FadeTransition(
                                        opacity: animation,
                                        child: ScaleTransition(
                                          scale: Tween<double>(
                                                  begin: 0.94, end: 1.0)
                                              .animate(animation),
                                          child: child,
                                        ),
                                      ),
                                      child: CarouselImageViewer(
                                      key: ValueKey(variant_state.productVariant.id),
                                      initialIndex: _carouselIndex,
                                      onIndexChanged: (i) => _carouselIndex = i,
                                      imageUrls: variant_state.productVariant
                                          .images.map((url) => '${URLs
                                          .baseUrl}$url').toList(),
                                      mediaItems: [
                                        ...variant_state.productVariant.images
                                            .map((url) {
                                          return
                                            MediaItem(
                                              url: "${URLs.baseUrl}$url",
                                              type: MediaType.image,
                                              thumbnailUrl: "${URLs
                                                  .baseUrl}$url",
                                            );
                                        }).toList(),
                                        // ویدیو آخرین آیتم گالری است، بعد از همه‌ی عکس‌ها
                                        if (variant_state.productVariant.video != null &&
                                            variant_state.productVariant.video!.isNotEmpty)
                                          MediaItem(
                                            url: variant_state.productVariant.video!,
                                            type: MediaType.video,
                                            thumbnailUrl: product
                                                .videoThumbnail ??
                                                "",
                                          ),
                                      ],
                                      mainImageHeight: 250,
                                      thumbnailSize: 40,
                                      thumbnailSpacing: 12,
                                    ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                )
                            ),
                          ],
                        ),
                      ),
                    ),
                    // هدر شناور تیره: بازگشت، عنوان ثابت اپ، علاقه‌مندی/اشتراک‌گذاری/سبد
                    Positioned(
                      top: 0,
                      right: 0,
                      left: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColor.obsidianBg.withOpacity(0.85),
                              AppColor.obsidianBg.withOpacity(0.0),
                            ],
                          ),
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.arrow_forward,
                                      color: AppColor.onSurface),
                                ),
                                Expanded(
                                  child: Text(
                                    'پرشین شاپ',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.headlineMd
                                        .copyWith(fontSize: 18, color: AppColor.goldEnd),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _toggleFavorite,
                                  icon: Icon(
                                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: _isFavorite ? Colors.red : AppColor.onSurfaceVariant,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _shareProduct(product.nameFarsi ?? ''),
                                  icon: const Icon(Icons.share,
                                      color: AppColor.onSurfaceVariant),
                                ),
                                BlocBuilder<CartBloc, CartState>(
                                  builder: (context, cartState) {
                                    final count = cartState is CartLoaded
                                        ? (cartState.cart.results.isNotEmpty
                                            ? cartState.cart.results[0].items.length
                                            : 0)
                                        : 0;
                                    return IconButton(
                                      onPressed: () =>
                                          Navigator.of(context).pushNamed('/cart'),
                                      icon: Badge(
                                        isLabelVisible: count > 0,
                                        label: Text('$count'),
                                        child: const Icon(Icons.shopping_bag_outlined,
                                            color: AppColor.onSurfaceVariant),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),


              // بخش ۲ - اطلاعات محصول
              Container(
                decoration: BoxDecoration(
                    // تینت داینامیک رنگ واریانت، روی پس‌زمینه تیره ترکیب می‌شود
                    color: Color.alphaBlend(
                        Color(int.parse(
                                "ff" + variant_state.productVariant.colorRgb!,
                                radix: 16))
                            .withOpacity(0.15),
                        AppColor.obsidianBg)),
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
                                color: AppColor.onSurface,
                              ),
                            ),
                          ),
                          Directionality(
                              textDirection: TextDirection.ltr,
                              child: RatingTag(value: product.avgRate,
                                  margin: EdgeInsets.only(left: 10))),
                        ],
                      ),
                    ),
                    if (product.price != null)
                      Container(
                        margin: EdgeInsets.only(top: 8, bottom: 14),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: BlocBuilder<
                              ProductDetailVariantBloc,
                              ProductDetailState>(
                              builder: (context, size_state) {
                                if (size_state is ProductDetailSizeChanged) {
                                  final int originalPrice = size_state.productSize.price;
                                  final int? discountPercentage = size_state.productSize.discountPercentage;

                                  int finalPrice = originalPrice;
                                  int percent = 0;

                                  if (discountPercentage != null &&
                                      discountPercentage > 0 &&
                                      discountPercentage < 100) {
                                    finalPrice = (originalPrice*(1-(discountPercentage/100))).toInt();
                                    percent = discountPercentage;
                                  } else if (product.discountPercentage == null || product.discountPercentage! <= 0) {
                                    percent = 0;
                                    finalPrice = originalPrice;
                                  }

                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      if (percent > 0) SizedBox(width: 8),
                                      Text(
                                        '${thousandSeparator(finalPrice)} تومان',
                                        style: TextStyle(
                                          fontFamily: 'Estedad',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColor.goldEnd,
                                        ),
                                      ),
                                      if (percent > 0) SizedBox(width: 8),

                                      if (percent > 0)
                                      Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                          ),
                                          child: Text(
                                            '%$percent',
                                            style: TextStyle(
                                              fontFamily: 'Estedad',
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      if (percent > 0) SizedBox(width: 8),
                                      if (percent > 0)
                                        Text(
                                          '${thousandSeparator(originalPrice)} تومان',
                                          style: TextStyle(
                                            fontFamily: 'Estedad',
                                            fontSize: 14,
                                            color: AppColor.onSurfaceVariant,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),

                                    ],
                                  );
                                } else {
                                  return Container();
                                }
                              }
                          ),
                        ),
                      ),

                    // وضعیت موجودی (فیلد count در size_variants)
                    BlocBuilder<ProductDetailVariantBloc, ProductDetailState>(
                      builder: (context, stock_state) {
                        if (stock_state is! ProductDetailSizeChanged) {
                          return SizedBox.shrink();
                        }
                        final size = stock_state.productSize;
                        final Color color = !size.inStock
                            ? Colors.red
                            : (size.isLowStock
                                ? Colors.orange.shade800
                                : Colors.green.shade700);
                        final String label = !size.inStock
                            ? 'ناموجود'
                            : (size.isLowStock
                                ? 'تنها ${size.count} عدد باقی مانده'
                                : 'موجود در انبار');
                        return Align(
                          alignment: AlignmentGeometry.centerRight,
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Container(
                              margin: EdgeInsets.only(right: 16, bottom: 14),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                      size.inStock
                                          ? Icons.check_circle_outline
                                          : Icons.remove_shopping_cart_outlined,
                                      size: 14,
                                      color: color),
                                  SizedBox(width: 6),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontFamily: 'Estedad',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
                                Row(
                                  children: [
                                    Text(
                                      'رنگ:  ',
                                      style: TextStyle(
                                        fontFamily: 'Estedad',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.onSurface,
                                      ),
                                    ),
                                    Text(
                                      variant_state.productVariant.color!,
                                      style: TextStyle(
                                        fontFamily: 'Estedad',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: AppColor.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                SelectableCircleColor(
                                  circleSize: 32,
                                  spacing: 12,
                                  colorWay: product.variants
                                      .map((v) =>
                                      ColorWay(
                                        color: Color(int.parse(
                                            "ff" + v.colorRgb!,
                                            radix: 16)),
                                        name: v.color ?? "ناشناس",
                                        imageUrl: v.image != null ? '${URLs
                                            .baseUrl}${v.image}' : null,

                                      ))
                                      .toList(),
                                  onColorSelected: (int vIndex) {
                                    if (product.variants.isNotEmpty &&
                                        product.variants[vIndex].sizeVariants
                                            .isNotEmpty) {
                                      // با تعویض رنگ هم اولین سایز موجود انتخاب شود
                                      final size = firstAvailableSizeVariant(
                                          product.variants[vIndex]
                                              .sizeVariants)!;
                                      context
                                          .read<ProductDetailVariantBloc>()
                                          .add(ChangeProductColorEvent(
                                              product.variants[vIndex], size));
                                    }
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.onSurface,
                                  ),
                                ),
                                SizedBox(height: 12),
                                SelectableCircleSize(
                                  // با تعویض رنگ، وضعیت موجودی سایزها هم عوض می‌شود
                                  key: ValueKey(
                                      variant_state.productVariant.id),
                                  productSize: variant_state.productVariant
                                      .sizeVariants
                                      .map((s) => s.size)
                                      .toList(),
                                  sizeAvailability: variant_state
                                      .productVariant.sizeVariants
                                      .map((s) => s.inStock)
                                      .toList(),
                                  onSizeSelected: (int sizeVariantIndex) {
                                    context
                                        .read<ProductDetailVariantBloc>()
                                        .add(
                                        ChangeProductColorEvent(
                                            variant_state.productVariant,
                                            variant_state.productVariant
                                                .sizeVariants[sizeVariantIndex])
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
                          color: AppColor.onSurfaceVariant,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ],
                ),
              ),


              // بخش ۵ - تب‌های جزئیات: توضیحات، مشابه، نظرات، سوالات متداول
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: DetailTabs(
                  dark: true,
                  tabs: [
                    DetailTab(
                      title: 'توضیحات',
                      // توضیح در HtmlDescriptionBody: تصاویر از جریان
                      // HTML جدا و به‌صورت ویجت مستقل رندر می‌شوند، چون
                      // تصویر «fallback»‌شده (برای دورزدن CORS در وب) وقتی
                      // داخل WidgetSpan یک RichText اسکرول‌شونده باشد در
                      // این نسخه‌ی فلاتر کاملاً نامرئی می‌ماند.
                      builder: (context) => HtmlDescriptionBody(
                        html: sanitizeHtmlForDarkBg(product.editor ?? ''),
                        onLinkTap: (url, _, __) async {
                          if (await canLaunchUrl(Uri.parse(url!))) {
                            await launchUrl(Uri.parse(url));
                          }
                        },
                      ),
                    ),
                    if (product.similarProducts.isNotEmpty)
                      DetailTab(
                        title: 'محصولات مشابه',
                        builder: (context) => SizedBox(
                          // کارت کمی بلندتر از فضای قبلی است؛ کمی حاشیه اضافه شد
                          height: 232,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            physics: BouncingScrollPhysics(),
                            itemCount: product.similarProducts.length,
                            itemBuilder: (ctx, i) => SimilarProductCard(
                                product: product.similarProducts[i]),
                          ),
                        ),
                      ),
                    DetailTab(
                      title: 'نظرات',
                      builder: (context) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProductReviewsSection(productId: product.id),
                          // نظرات ثبت‌شده روی خود محصول در API
                          if (product.comments.isNotEmpty)
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: product.comments.length,
                              itemBuilder: (ctx, i) => ReviewTile(
                                review: Review(
                                    photoUrl:
                                        "assets/images/avatar_for_comments.png",
                                    name: " ${i} : ",
                                    review: product.comments[i].text,
                                    rating: 5),
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ReviewsPage(productId: product.id)),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColor.goldEnd,
                                side: BorderSide(color: AppColor.outlineVariantDark),
                                shape: const RoundedRectangleBorder(),
                              ),
                              child: Text(
                                'مشاهده همه نظرات',
                                style: TextStyle(
                                    fontFamily: 'Estedad',
                                    color: AppColor.goldEnd,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (product.faqs != null && product.faqs!.isNotEmpty)
                      DetailTab(
                        title: 'سوالات متداول',
                        builder: (context) => Column(
                          children: product.faqs!
                              .map((faq) => ExpansionTile(
                                    tilePadding: EdgeInsets.zero,
                                    initiallyExpanded: false,
                                    iconColor: AppColor.goldEnd,
                                    collapsedIconColor: AppColor.onSurfaceVariant,
                                    title: Text(
                                      faq.question,
                                      style: TextStyle(
                                        fontFamily: 'Estedad',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.onSurface,
                                      ),
                                    ),
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.only(bottom: 12),
                                        child: Text(
                                          faq.answer,
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontFamily: 'Estedad',
                                            fontSize: 13,
                                            height: 1.8,
                                            color: AppColor.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),


            ],
          );
        }else{
          // این شاخه وقتی رخ می‌دهد که هنوز رنگ/سایزی برای واریانت انتخاب
          // نشده (رویداد ChangeProductColorEvent اولیه هنوز پردازش نشده)
          return Container(
            color: AppColor.obsidianBg,
            child: const Center(
              child: CircularProgressIndicator(color: AppColor.goldEnd),
            ),
          );
        }

      }
    );
  }
}


