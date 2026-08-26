// views/screens/product_detail.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/constant/app_text_styles.dart';
import 'package:marketky/views/widgets/accordion_section.dart';
import 'package:marketky/views/widgets/app_network_image.dart';
import 'package:marketky/views/widgets/inline_video_player.dart';
import 'package:marketky/views/widgets/app_buttons.dart';
import 'package:marketky/services/recently_viewed_service.dart';
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
import 'package:marketky/views/widgets/review_tile.dart';
import 'package:marketky/views/widgets/selectable_circle_color.dart';
import 'package:marketky/views/widgets/selectable_circle_size.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/product_detail/product_detail_bloc.dart';
import '../../bloc/product_detail/product_detail_event.dart';
import '../../bloc/product_detail/product_detail_state.dart';
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

  /// شناسه‌ی محصولی که واریانت اولیه‌اش یک‌بار ست شده است.
  ///
  /// مهم: قبلاً رویداد «انتخاب واریانت اول» در هر بار build ارسال می‌شد، پس
  /// هر setState (مثلاً عوض‌کردن تصویر گالری) رنگ انتخابی کاربر را به رنگ
  /// اول برمی‌گرداند و تغییر رنگ عملاً کار نمی‌کرد.
  int? _variantInitializedFor;

  /// وقتی «خرید فوری» زده شود، بعد از افزودن موفق به‌جای دیالوگ به سبد می‌رود
  bool _buyNowPending = false;

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
    // ثبت در بازدیدهای اخیر و آنالیتیکس
    RecentlyViewedService.markViewed(widget.productId);
    AnalyticsService.viewItem(productId: widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.milk,
      // بدنه نباید زیر نوار پایین برود، وگرنه انتهای توضیحات پشت دکمه‌ها
      // پنهان می‌ماند.
      extendBody: false,
      bottomNavigationBar: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {
          if (state is! ProductDetailLoaded) return const SizedBox.shrink();
          final product = state.product;
          return BlocBuilder<ProductDetailVariantBloc, ProductDetailState>(
            builder: (context, variantState) {
              return BlocListener<CartBloc, CartState>(
                listener: (context, cartState) {
                  if (cartState is CartItemAdded) {
                    // «خرید فوری»: به‌جای دیالوگ، مستقیم به سبد می‌رود
                    if (_buyNowPending) {
                      _buyNowPending = false;
                      Navigator.of(context).pushNamed('/cart');
                      return;
                    }
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
                              cartState.message,
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
                  if (cartState is CartError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(cartState.message,
                            style: const TextStyle(fontFamily: 'Estedad')),
                        backgroundColor: AppColor.danger,
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: ShapeDecoration(
                    color: AppColor.card,
                    shape: AppShapes.borderTop(AppShapes.rXl),
                    shadows: AppColor.floatingShadow,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: SoftButton(
                                label: 'افزودن به سبد',
                                height: 50,
                                icon: const Icon(
                                    Icons.add_shopping_cart_rounded),
                                onPressed: () => _openAddToCart(
                                    context, product, variantState),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GradientButton(
                                label: 'خرید فوری',
                                height: 50,
                                icon: const Icon(Icons.bolt_rounded),
                                onPressed: () =>
                                    _buyNow(context, product, variantState),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      body: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {

          if (state is ProductDetailLoading) {
            return _buildLoading();
          } else if (state is ProductDetailError) {
            return _buildError(state.message, context);
          } else if (state is ProductDetailLoaded) {
            _ensureInitialVariant(state.product);
            return _buildProductContent(state.product, context);
          }

          return _buildLoading();
        },
      ),
    );
  }

  /// فقط یک‌بار برای هر محصول، رنگ/سایز اولیه را انتخاب می‌کند
  void _ensureInitialVariant(ProductDetail product) {
    if (_variantInitializedFor == product.id) return;
    _variantInitializedFor = product.id;

    // تصویر شاخص محصول به انتهای گالری اضافه می‌شود (فقط یک‌بار، وگرنه در
    // هر build لیست بزرگ‌تر می‌شد)
    if (product.image != null && !product.images.contains(product.image)) {
      product.images.add(product.image!);
    }

    if (product.variants.isEmpty || product.variants[0].sizeVariants.isEmpty) {
      return;
    }
    final initialSize =
        firstAvailableSizeVariant(product.variants[0].sizeVariants)!;
    // ارسال بعد از پایان فریم، تا در حین build رویداد فرستاده نشود
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<ProductDetailVariantBloc>()
          .add(ChangeProductColorEvent(product.variants[0], initialSize));
    });
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

  // ==================== منطق افزودن به سبد ====================

  /// سایز انتخاب‌شده‌ی فعلی (اگر واریانت سایز داشته باشد)
  SizeVariant? _selectedSize(ProductDetailState s) {
    if (s is ProductDetailSizeChanged) return s.productSize;
    if (s is ProductDetailChangedState) return s.productSize;
    return null;
  }

  /// ساخت CartItem از همان داده‌های موجود (بدون تغییر منطق قبلی)
  CartItem _cartItemFor(ProductDetail product, ProductDetailState s) {
    if (s is ProductDetailSizeChanged) {
      return CartItem(
        id: s.productSize.id,
        name: product.nameFarsi ?? "",
        image: s.productVariant.image ?? "",
        price: s.productSize.price,
        quantity: 1,
        productId: product.id,
        discountPrice: s.productSize.discountPercentage,
      );
    }
    if (s is ProductDetailChangedState) {
      return CartItem(
        id: s.productSize!.id,
        name: product.nameFarsi ?? "",
        image: s.productVariant.image ?? "",
        price: s.productSize!.price,
        quantity: 1,
        productId: product.id,
        discountPrice: s.productSize!.discountPercentage,
      );
    }
    return CartItem(
      id: product.id,
      name: product.nameFarsi ?? "",
      image: product.image ?? "",
      price: product.price!,
      quantity: 1,
      productId: product.id,
      discountPrice: product.discountPercentage,
    );
  }

  /// جلوگیری از افزودن کالای ناموجود (همان بررسی قبلی)
  bool _guardStock(BuildContext context, ProductDetailState s) {
    final size = _selectedSize(s);
    if (size != null && !size.inStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('این سایز ناموجود است',
              style: TextStyle(fontFamily: 'Estedad')),
          backgroundColor: AppColor.danger,
        ),
      );
      return false;
    }
    return true;
  }

  void _openAddToCart(
      BuildContext context, ProductDetail product, ProductDetailState s) {
    if (!_guardStock(context, s)) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddToCartModal(cartItem: _cartItemFor(product, s)),
    );
  }

  void _buyNow(
      BuildContext context, ProductDetail product, ProductDetailState s) {
    if (!_guardStock(context, s)) return;
    final item = _cartItemFor(product, s);
    AnalyticsService.addToCart(
      productId: item.productId,
      quantity: 1,
      price: item.price,
    );
    _buyNowPending = true;
    context.read<CartBloc>().add(AddToCart(context, item.id, 1));
  }

  // ==================== بدنه‌ی صفحه ====================

  Widget _buildProductContent(ProductDetail product, BuildContext context) {
    return BlocBuilder<ProductDetailVariantBloc, ProductDetailState>(
      builder: (context, variantState) {
        // تا وقتی رنگ/سایز اولیه انتخاب نشده، لودینگ نمایش داده می‌شود
        if (variantState is! ProductDetailSizeChanged) {
          return Container(
            color: AppColor.milk,
            child: const Center(
              child: CircularProgressIndicator(color: AppColor.pitchGreen),
            ),
          );
        }
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _buildGalleryPanel(product, variantState),
            _buildInfoPanel(product, variantState),
            _buildAccordions(product),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  List<String> _galleryImages(ProductVariant variant) =>
      variant.images.map((u) => '${URLs.baseUrl}$u').toList();

  /// رنگ واریانت انتخاب‌شده (برای تینت پس‌زمینه‌ی قاب تصویر)
  Color _variantColor(ProductVariant variant) {
    final rgb = variant.colorRgb;
    if (rgb == null || rgb.isEmpty) return AppColor.pitchGreen;
    try {
      return Color(0xff000000 + int.parse(rgb, radix: 16));
    } catch (_) {
      return AppColor.pitchGreen;
    }
  }

  /// انتقال «مورف»: هم‌زمان محو، مقیاس و کمی جابه‌جایی عمودی، تا تعویض
  /// تصویر/رنگ به‌جای پرش، تبدیل نرم دیده شود.
  Widget _morph(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ),
    );
  }

  /// بخش بالا: کارت گوشه‌گرد با تینت رنگ واریانت، تصویر بزرگ و ریل عمودی
  /// تامبنیل چسبیده به لبه‌ی راست
  Widget _buildGalleryPanel(
      ProductDetail product, ProductDetailSizeChanged state) {
    final variant = state.productVariant;
    final images = _galleryImages(variant);
    final hasVideo = variant.video != null && variant.video!.isNotEmpty;

    // آخرین آیتم ریل، ویدیو است (اگر وجود داشته باشد)
    final int itemCount = images.length + (hasVideo ? 1 : 0);
    // با تعویض رنگ، همان ایندکسی که کاربر قبلاً انتخاب کرده حفظ می‌شود؛
    // اگر واریانت جدید آن ایندکس را نداشته باشد، تصویر اول نشان داده می‌شود.
    final int index =
        (_carouselIndex >= 0 && _carouselIndex < itemCount) ? _carouselIndex : 0;
    final bool showVideo = hasVideo && index == images.length;

    // پس‌زمینه‌ی قاب تصویر با رنگ همان واریانت و آلفای ۰٫۵
    final Color panelTint = Color.alphaBlend(
      _variantColor(variant).withValues(alpha: 0.5),
      AppColor.milk,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 10, 16, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        height: 400,
        decoration: ShapeDecoration(
          color: panelTint,
          shape: AppShapes.border(AppShapes.rXl),
          shadows: AppColor.cardShadow,
        ),
        child: SquircleClip(
          radius: AppShapes.rXl,
          child: Stack(
            children: [
              // رسانه‌ی اصلی — فضای سمت راست برای ریل تامبنیل خالی می‌ماند
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 76, 108, 20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: _morph,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.center,
                      children: [...previous, if (current != null) current],
                    ),
                    child: showVideo
                        // ویدیو داخل همان قاب تصویر پخش می‌شود، نه دیالوگ جدا
                        ? InlineVideoPlayer(
                            key: ValueKey('video-${variant.id}'),
                            videoUrl: variant.video!,
                          )
                        : GestureDetector(
                            key: ValueKey('img-${variant.id}-$index'),
                            onTap: images.isEmpty
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ImageViewer(imageUrl: images),
                                      ),
                                    ),
                            child: AppNetworkImage(
                              url: images.isEmpty ? null : images[index],
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                  ),
                ),
              ),

              // هدر شناور: بازگشت (راست)، عنوان و اشتراک‌گذاری (چپ)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    children: [
                      CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'بازگشت',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          'جزئیات',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headlineMd
                              .copyWith(fontSize: 16, color: AppColor.ink),
                        ),
                      ),
                      CircleIconButton(
                        icon: Icons.ios_share_rounded,
                        tooltip: 'اشتراک‌گذاری',
                        onTap: () => _shareProduct(product.nameFarsi ?? ''),
                      ),
                    ],
                  ),
                ),
              ),

              // ریل عمودی تامبنیل، چسبیده به لبه‌ی راست
              Positioned(
                right: 14,
                top: 76,
                bottom: 18,
                width: 76,
                child: _buildThumbRail(
                  images: images,
                  selected: index,
                  video: hasVideo ? variant.video : null,
                  variantId: variant.id,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbRail({
    required List<String> images,
    required int selected,
    required String? video,
    required int variantId,
  }) {
    return ListView(
      key: ValueKey('rail-$variantId'),
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      children: [
        for (int i = 0; i < images.length; i++)
          _thumb(
            selected: i == selected,
            onTap: () => setState(() => _carouselIndex = i),
            child: AppNetworkImage(
              url: images[i],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        if (video != null)
          _thumb(
            selected: selected == images.length,
            onTap: () => setState(() => _carouselIndex = images.length),
            child: Container(
              color: AppColor.card,
              alignment: Alignment.center,
              child: const Icon(Icons.play_circle_fill_rounded,
                  color: AppColor.pitchGreen, size: 30),
            ),
          ),
      ],
    );
  }

  Widget _thumb({
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: 72,
          decoration: ShapeDecoration(
            color: AppColor.card,
            shape: AppShapes.border(
              AppShapes.rMd,
              side: BorderSide(
                color: selected ? AppColor.pitchGreen : Colors.transparent,
                width: 2,
              ),
            ),
            shadows: selected ? AppColor.greenShadow : AppColor.cardShadow,
          ),
          child: SquircleClip(radius: AppShapes.rMd, child: child),
        ),
      ),
    );
  }

  /// بخش پایین: کارت سفید گوشه‌گرد با نام، تعداد، قیمت، رنگ، سایز و توضیح
  Widget _buildInfoPanel(
      ProductDetail product, ProductDetailSizeChanged state) {
    final size = state.productSize;
    final int original = size.price;
    final int? pct = size.discountPercentage;
    final bool hasDiscount = pct != null && pct > 0 && pct < 100;
    final int finalPrice =
        hasDiscount ? (original * (1 - pct / 100)).toInt() : original;

    final Color stockColor = !size.inStock
        ? AppColor.danger
        : (size.isLowStock ? AppColor.warning : AppColor.success);
    final String stockLabel = !size.inStock
        ? 'ناموجود'
        : (size.isLowStock
            ? 'تنها ${size.count} عدد باقی مانده'
            : 'موجود در انبار');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: ShapeDecoration(
          color: AppColor.card,
          shape: AppShapes.border(AppShapes.rXl),
          shadows: AppColor.cardShadow,
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // نام محصول (انتخاب تعداد در شیت افزودن به سبد انجام می‌شود)
              Text(
                product.nameFarsi ?? '',
                style: const TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 19,
                  height: 1.45,
                  fontWeight: FontWeight.w800,
                  color: AppColor.ink,
                ),
              ),
              const SizedBox(height: 14),

              // قیمت + نمونه‌های رنگ
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'از: ',
                              style: TextStyle(
                                fontFamily: 'Estedad',
                                fontSize: 13,
                                color: AppColor.inkMuted,
                              ),
                            ),
                            Text(
                              '${thousandSeparator(finalPrice)} تومان',
                              style: const TextStyle(
                                fontFamily: 'Estedad',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColor.ink,
                              ),
                            ),
                          ],
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              PillTag(
                                label: '٪$pct تخفیف',
                                icon: Icons.local_offer_outlined,
                                color: Colors.white,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEF4444), AppColor.danger],
                                ),
                                dense: true,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                thousandSeparator(original),
                                style: const TextStyle(
                                  fontFamily: 'Estedad',
                                  fontSize: 12,
                                  color: AppColor.inkMuted,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: AppColor.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (product.variants.isNotEmpty)
                    SelectableCircleColor(
                      circleSize: 22,
                      spacing: 8,
                      colorWay: product.variants
                          .map((v) => ColorWay(
                                color: Color(0xff000000 +
                                    int.parse(v.colorRgb!, radix: 16)),
                                name: v.color ?? 'ناشناس',
                                imageUrl: v.image != null
                                    ? '${URLs.baseUrl}${v.image}'
                                    : null,
                              ))
                          .toList(),
                      onColorSelected: (int vIndex) {
                        if (product.variants[vIndex].sizeVariants.isNotEmpty) {
                          final s = firstAvailableSizeVariant(
                              product.variants[vIndex].sizeVariants)!;
                          // ایندکس تصویر انتخاب‌شده عمداً ریست نمی‌شود؛ اگر
                          // واریانت جدید همان تعداد تصویر را داشته باشد،
                          // کاربر روی همان زاویه‌ی قبلی می‌ماند.
                          context.read<ProductDetailVariantBloc>().add(
                              ChangeProductColorEvent(
                                  product.variants[vIndex], s));
                        }
                      },
                    ),
                ],
              ),

              if (state.productVariant.sizeVariants.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'انتخاب سایز',
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColor.ink,
                  ),
                ),
                const SizedBox(height: 10),
                SelectableCircleSize(
                  key: ValueKey(state.productVariant.id),
                  productSize: state.productVariant.sizeVariants
                      .map((s) => s.size)
                      .toList(),
                  sizeAvailability: state.productVariant.sizeVariants
                      .map((s) => s.inStock)
                      .toList(),
                  onSizeSelected: (int i) {
                    context.read<ProductDetailVariantBloc>().add(
                        ChangeProductColorEvent(state.productVariant,
                            state.productVariant.sizeVariants[i]));
                  },
                ),
              ],

              const SizedBox(height: 16),
              PillTag(
                label: stockLabel,
                icon: size.inStock
                    ? Icons.check_circle_outline
                    : Icons.remove_shopping_cart_outlined,
                color: stockColor,
              ),

              if ((product.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  'توضیحات',
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColor.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.description!,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 13,
                    height: 1.85,
                    color: AppColor.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// آکاردئون جزئیات: توضیحات کامل، مشابه، نظرات، سوالات متداول
  Widget _buildAccordions(ProductDetail product) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            AccordionSection(
              title: 'توضیحات کامل',
              icon: Icons.description_outlined,
              // تصاویر توضیحات از جریان HTML جدا و به‌صورت ویجت مستقل رندر
              // می‌شوند، چون تصویر «fallback»‌شده (برای دورزدن CORS در وب)
              // داخل WidgetSpan نامرئی می‌ماند.
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
                    itemBuilder: (ctx, i) =>
                        SimilarProductCard(product: product.similarProducts[i]),
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
                  ProductReviewsSection(
                    productId: product.id,
                    avgRate: product.avgRate,
                    comments: product.comments,
                    // بعد از ثبت نظر/امتیاز، محصول دوباره از سرور خوانده
                    // می‌شود تا میانگین امتیاز به‌روز شود
                    onSubmitted: () => context
                        .read<ProductDetailBloc>()
                        .add(FetchProductDetail(widget.productId)),
                  ),
                  if (product.comments.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: product.comments.length,
                      itemBuilder: (ctx, i) => ReviewTile(
                        review: Review(
                          photoUrl: "assets/images/avatar_for_comments.png",
                          name: " $i : ",
                          review: product.comments[i].text,
                          rating: 5,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SoftButton(
                    label: 'مشاهده همه نظرات',
                    icon: const Icon(Icons.reviews_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReviewsPage(productId: product.id),
                      ),
                    ),
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
                            data: Theme.of(context)
                                .copyWith(dividerColor: Colors.transparent),
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
                                  padding: const EdgeInsets.only(bottom: 12),
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
    );
  }

}
