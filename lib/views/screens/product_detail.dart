// views/screens/product_detail.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/constant/app_text_styles.dart';
import 'package:marketky/views/widgets/accordion_section.dart';
import 'package:marketky/views/widgets/app_buttons.dart';
import 'package:marketky/services/wishlist_service.dart';
import 'package:marketky/services/analytics_service.dart';
import 'package:marketky/constant/urls.dart';
import 'package:marketky/core/model/Review.dart';
import 'package:marketky/models/CartModel.dart';
import 'package:marketky/models/ColorWay.dart';
import 'package:marketky/models/ProductModel.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/views/screens/image_viewer.dart';
import 'package:marketky/views/screens/reviews_page.dart';
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
      backgroundColor: AppColor.milk,
      extendBodyBehindAppBar: true,
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: BlocBuilder<ProductDetailBloc, ProductDetailState>(
          builder: (context, state) {
            if (state is ProductDetailLoaded) {
              return Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const ShapeDecoration(
                  color: AppColor.card,
                  shape: ContinuousRectangleBorder(),
                  shadows: AppColor.floatingShadow,
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
                                  backgroundColor: AppColor.card,
                                  shape: AppShapes.border(AppShapes.rLg),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          color: AppColor.success, size: 60),
                                      const SizedBox(height: 16),
                                      Text(
                                        state.message,
                                        style: const TextStyle(
                                          fontFamily: 'Estedad',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColor.ink,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 18),
                                      GradientButton(
                                        label: 'باشه',
                                        height: 44,
                                        fontSize: 14,
                                        onPressed: () => Navigator.of(ctx).pop(),
                                      ),
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
                                  Container(
                                    width: 54,
                                    height: 54,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: ShapeDecoration(
                                      color: AppColor.cardMuted,
                                      shape: AppShapes.pill,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      shape: AppShapes.pill,
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: () => Navigator.of(context)
                                            .pushNamed('/cart'),
                                        child: Padding(
                                          padding: const EdgeInsets.all(15),
                                          child: SvgPicture.asset(
                                            'assets/icons/Bag.svg',
                                            fit: BoxFit.contain,
                                            colorFilter: const ColorFilter.mode(
                                                AppColor.pitchGreen,
                                                BlendMode.srcIn),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: SizedBox(
                                      height: 54,
                                      child: _AddToCartButton(
                                        enabled:
                                            variant_state is ProductDetailSizeChanged,
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
                                            // محتوای شیت بلندتر از ارتفاع
                                            // پیش‌فرض است و باید کامل جا شود
                                            isScrollControlled: true,
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
            // مهم: Container() خالی در bottomNavigationBar کل ارتفاع را
            // می‌گیرد؛ باید صراحتاً صفر باشد.
            return const SizedBox.shrink();
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
      color: AppColor.milk,
      child: const Center(
          child: CircularProgressIndicator(color: AppColor.pitchGreen)),
    );
  }

  Widget _buildError(String message, BuildContext context) {
    return Container(
      color: AppColor.milk,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              style: const TextStyle(
                  fontFamily: 'Estedad', color: AppColor.danger),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            GradientButton(
              label: 'تلاش مجدد',
              expand: false,
              height: 42,
              fontSize: 13,
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => context
                  .read<ProductDetailBloc>()
                  .add(FetchProductDetail(widget.productId)),
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
                                    const SizedBox(height: 96),
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
                    // هدر شناور: دکمه‌های گرد برجسته روی تصویر
                    Positioned(
                      top: 0,
                      right: 0,
                      left: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              children: [
                                CircleIconButton(
                                  icon: Icons.arrow_forward_rounded,
                                  tooltip: 'بازگشت',
                                  onTap: () => Navigator.of(context).pop(),
                                ),
                                Expanded(
                                  child: Text(
                                    'جزئیات محصول',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.headlineMd.copyWith(
                                        fontSize: 16, color: AppColor.ink),
                                  ),
                                ),
                                CircleIconButton(
                                  icon: _isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  iconColor: _isFavorite
                                      ? AppColor.danger
                                      : AppColor.ink,
                                  tooltip: 'علاقه‌مندی',
                                  onTap: _toggleFavorite,
                                ),
                                const SizedBox(width: 8),
                                CircleIconButton(
                                  icon: Icons.ios_share_rounded,
                                  tooltip: 'اشتراک‌گذاری',
                                  onTap: () =>
                                      _shareProduct(product.nameFarsi ?? ''),
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


              // بخش ۲ - اطلاعات محصول: ورق سفید برجسته که روی گالری می‌نشیند
              Transform.translate(
                offset: const Offset(0, -26),
                child: Container(
                decoration: ShapeDecoration(
                  color: AppColor.card,
                  shape: ContinuousRectangleBorder(
                    borderRadius: AppShapes.radiusTop(AppShapes.rXl),
                  ),
                  shadows: AppColor.floatingShadow,
                ),
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PillTag(
                            label: product.category.nameFarsi,
                            icon: Icons.sell_outlined,
                            dense: true,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  product.nameFarsi ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'Estedad',
                                    fontSize: 20,
                                    height: 1.4,
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.ink,
                                  ),
                                ),
                              ),
                              Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: RatingTag(
                                      value: product.avgRate,
                                      margin: const EdgeInsets.only(left: 10))),
                            ],
                          ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${thousandSeparator(finalPrice)} تومان',
                                        style: const TextStyle(
                                          fontFamily: 'Estedad',
                                          fontSize: 19,
                                          fontWeight: FontWeight.w800,
                                          color: AppColor.ink,
                                        ),
                                      ),
                                      if (percent > 0) ...[
                                        const SizedBox(width: 10),
                                        PillTag(
                                          label: '٪$percent تخفیف',
                                          icon: Icons.local_offer_outlined,
                                          color: Colors.white,
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFEF4444),
                                              AppColor.danger
                                            ],
                                          ),
                                          dense: true,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          thousandSeparator(originalPrice),
                                          style: const TextStyle(
                                            fontFamily: 'Estedad',
                                            fontSize: 13,
                                            color: AppColor.inkMuted,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            decorationColor: AppColor.inkMuted,
                                          ),
                                        ),
                                      ],
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
                            ? AppColor.danger
                            : (size.isLowStock
                                ? AppColor.warning
                                : AppColor.success);
                        final String label = !size.inStock
                            ? 'ناموجود'
                            : (size.isLowStock
                                ? 'تنها ${size.count} عدد باقی مانده'
                                : 'موجود در انبار');
                        return Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: PillTag(
                                label: label,
                                icon: size.inStock
                                    ? Icons.check_circle_outline
                                    : Icons.remove_shopping_cart_outlined,
                                color: color,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // بخش ۳ - انتخاب رنگ
                    if (product.variants.isNotEmpty)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'رنگ:  ',
                                      style: TextStyle(
                                        fontFamily: 'Estedad',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColor.ink,
                                      ),
                                    ),
                                    Text(
                                      variant_state.productVariant.color!,
                                      style: const TextStyle(
                                        fontFamily: 'Estedad',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: AppColor.inkMuted,
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
                                        color: Color(0xff000000+int.parse(
                                             v.colorRgb!,
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
                        alignment: AlignmentDirectional.centerStart,
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'اندازه',
                                  style: TextStyle(
                                    fontFamily: 'Estedad',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.ink,
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


                    if ((product.description ?? '').trim().isNotEmpty)
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          product.description!,
                          style: const TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 13,
                            color: AppColor.inkMuted,
                            height: 1.8,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                  ],
                ),
              ),
              ),


              // بخش ۵ - آکاردئون جزئیات: توضیحات، مشابه، نظرات، سوالات متداول
              Transform.translate(
                offset: const Offset(0, -26),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    children: [
                      AccordionSection(
                        title: 'توضیحات',
                        icon: Icons.description_outlined,
                        // تصاویر توضیحات از جریان HTML جدا و به‌صورت ویجت
                        // مستقل رندر می‌شوند، چون تصویر «fallback»‌شده (برای
                        // دورزدن CORS در وب) داخل WidgetSpan نامرئی می‌ماند.
                        child: HtmlDescriptionBody(
                          html: product.editor ?? '',
                          onLinkTap: (url, _, __) async {
                            if (await canLaunchUrl(Uri.parse(url!))) {
                              await launchUrl(Uri.parse(url));
                            }
                          },
                        ),
                      ),
                      if (product.similarProducts.isNotEmpty)
                        AccordionSection(
                          title: 'محصولات مشابه',
                          icon: Icons.grid_view_rounded,
                          trailingBadge: '${product.similarProducts.length}',
                          child: SizedBox(
                            height: 232,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true,
                              clipBehavior: Clip.none,
                              physics: const BouncingScrollPhysics(),
                              itemCount: product.similarProducts.length,
                              itemBuilder: (ctx, i) => SimilarProductCard(
                                  product: product.similarProducts[i]),
                            ),
                          ),
                        ),
                      AccordionSection(
                        title: 'نظرات',
                        icon: Icons.chat_bubble_outline_rounded,
                        trailingBadge: product.comments.isEmpty
                            ? null
                            : '${product.comments.length}',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProductReviewsSection(productId: product.id),
                            // نظرات ثبت‌شده روی خود محصول در API
                            if (product.comments.isNotEmpty)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: product.comments.length,
                                itemBuilder: (ctx, i) => ReviewTile(
                                  review: Review(
                                      photoUrl:
                                          "assets/images/avatar_for_comments.png",
                                      name: " $i : ",
                                      review: product.comments[i].text,
                                      rating: 5),
                                ),
                              ),
                            const SizedBox(height: 8),
                            SoftButton(
                              label: 'مشاهده همه نظرات',
                              icon: const Icon(Icons.reviews_outlined),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ReviewsPage(productId: product.id)),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      if (product.faqs != null && product.faqs!.isNotEmpty)
                        AccordionSection(
                          title: 'سوالات متداول',
                          icon: Icons.help_outline_rounded,
                          trailingBadge: '${product.faqs!.length}',
                          child: Column(
                            children: product.faqs!
                                .map((faq) => Theme(
                                      data: Theme.of(context).copyWith(
                                          dividerColor: Colors.transparent),
                                      child: ExpansionTile(
                                        tilePadding: EdgeInsets.zero,
                                        initiallyExpanded: false,
                                        shape: const Border(),
                                        collapsedShape: const Border(),
                                        iconColor: AppColor.pitchGreen,
                                        collapsedIconColor: AppColor.inkMuted,
                                        title: Text(
                                          faq.question,
                                          style: const TextStyle(
                                            fontFamily: 'Estedad',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColor.ink,
                                          ),
                                        ),
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.only(
                                                bottom: 12),
                                            child: Text(
                                              faq.answer,
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                fontFamily: 'Estedad',
                                                fontSize: 12,
                                                height: 1.8,
                                                color: AppColor.inkMuted,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }else{
          // این شاخه وقتی رخ می‌دهد که هنوز رنگ/سایزی برای واریانت انتخاب
          // نشده (رویداد ChangeProductColorEvent اولیه هنوز پردازش نشده)
          return Container(
            color: AppColor.milk,
            child: const Center(
              child: CircularProgressIndicator(color: AppColor.pitchGreen),
            ),
          );
        }

      }
    );
  }
}

/// دکمه‌ی اصلی نوار پایین: قرصی، گرادیان سبز و سایه‌ی برجسته.
/// تا وقتی رنگ/اندازه انتخاب نشده، متن راهنما نشان می‌دهد (همان رفتار قبلی).
class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      label: enabled ? 'افزودن به سبد' : 'لطفا رنگ و اندازه را انتخاب کنید',
      icon: enabled ? const Icon(Icons.add_shopping_cart_rounded) : null,
      fontSize: enabled ? 15 : 13,
      height: 54,
      onPressed: onPressed,
    );
  }
}


