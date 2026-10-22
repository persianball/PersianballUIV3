// views/screens/product_detail.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persian_ball/constant/app_breakpoints.dart';
import 'package:persian_ball/utils/login_prompt.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:persian_ball/constant/app_text_styles.dart';
import 'package:persian_ball/views/widgets/accordion_section.dart';
import 'package:persian_ball/views/widgets/app_network_image.dart';
import 'package:persian_ball/views/widgets/inline_video_player.dart';
import 'package:persian_ball/views/widgets/app_buttons.dart';
import 'package:persian_ball/services/recently_viewed_service.dart';
import 'package:persian_ball/services/analytics_service.dart';
import 'package:persian_ball/constant/urls.dart';
import 'package:persian_ball/models/CartModel.dart';
import 'package:persian_ball/models/ProductModel.dart';
import 'package:persian_ball/utils/ThousandsFormatter.dart';
import 'package:persian_ball/views/screens/image_viewer.dart';
import 'package:persian_ball/views/widgets/html_description_image.dart';
import 'package:persian_ball/views/widgets/cart_drop_animation.dart';
import 'package:persian_ball/views/widgets/cart_pop_button.dart';
import 'package:persian_ball/views/widgets/modals/add_to_cart_modal.dart';
import 'package:persian_ball/views/widgets/product_reviews_section.dart';
import 'package:persian_ball/views/widgets/selectable_circle_size.dart';
import 'package:persian_ball/views/widgets/shoe_size_guide.dart';
import 'package:persian_ball/views/widgets/variant_swatch_picker.dart';
import 'package:persian_ball/views/widgets/liquid_reveal.dart';
import 'package:persian_ball/constant/shoe_size_chart.dart';
import 'package:persian_ball/views/widgets/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/product_detail/product_detail_bloc.dart';
import '../../bloc/product_detail/product_detail_event.dart';
import '../../bloc/product_detail/product_detail_state.dart';
import '../widgets/similar_product_card.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({Key? key, required this.productId})
      : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  /// اسلاید فعلی گالری تا با تعویض رنگ همان اسلاید حفظ شود
  int _carouselIndex = 0;

  /// شناسه‌ی محصولی که واریانت اولیه‌اش یک‌بار ست شده است.
  ///
  /// مهم: قبلاً رویداد «انتخاب واریانت اول» در هر بار build ارسال می‌شد، پس
  /// هر setState (مثلاً عوض‌کردن تصویر گالری) رنگ انتخابی کاربر را به رنگ
  /// اول برمی‌گرداند و تغییر رنگ عملاً کار نمی‌کرد.
  int? _variantInitializedFor;

  /// دکمه‌ی گرد سبد در نوار پایین/پنل دسکتاپ؛ بعد از افزودن موفق «پر» می‌شود.
  final GlobalKey<CartPopButtonState> _cartButtonKey =
      GlobalKey<CartPopButtonState>();

  /// انیمیشنِ افتادن کالا داخل سبد در جریان است؟
  bool _dropRunning = false;

  /// پیام «افزوده شد» تا پایان انیمیشن نگه داشته می‌شود تا دیالوگ روی
  /// انیمیشن نیفتد و کاربر هر دو را ببیند.
  String? _pendingAddedMessage;

  /// دکمه‌ی سبد برای همین افزودن یک‌بار «پر» شده است؟
  bool _cartButtonPopped = false;

  /// تعداد اقلام سبد از آخرین وضعیت CartBloc (۰ اگر هنوز بار نشده)
  static int _cartCount(CartState s) {
    AllCartFromBackend? cart;
    if (s is CartLoaded) cart = s.cart;
    if (s is CartItemChangedQuantity) cart = s.productInCart;
    if (cart == null || cart.results.isEmpty) return 0;
    return cart.results.first.items
        .fold<int>(0, (sum, item) => sum + item.quantity);
  }

  /// اشتراک‌گذاری لینک محصول (دیپ‌لینک همین اپ)
  Future<void> _shareProduct(String productName) async {
    final link = '${URLs.origin}/product/${widget.productId}';
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
      backgroundColor: Colors.transparent,
      // بدنه نباید زیر نوار پایین برود، وگرنه انتهای توضیحات پشت دکمه‌ها
      // پنهان می‌ماند.
      extendBody: false,
      bottomNavigationBar: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {
          if (state is! ProductDetailLoaded) return const SizedBox.shrink();
          final product = state.product;
          return BlocBuilder<ProductDetailVariantBloc, ProductDetailState>(
            builder: (context, variantState) {
              // در دسکتاپ نوار پایین حذف می‌شود و همین دکمه‌ها داخل پنل
              // اطلاعات رندر می‌شوند؛ اما BlocListener باید زنده بماند تا
              // دیالوگ موفقیت در هر دو حالت کار کند.
              return BlocListener<CartBloc, CartState>(
                listener: _onCartState,
                child: AppBreakpoints.isDesktop(context)
                    ? const SizedBox.shrink()
                    : Container(
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
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              child: _actionButtons(
                                  context, product, variantState),
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
            return RefreshIndicator(
              color: AppColor.pitchGreen,
              backgroundColor: AppColor.card,
              onRefresh: _refresh,
              child: _buildError(state.message, context),
            );
          } else if (state is ProductDetailLoaded) {
            _ensureInitialVariant(state.product);
            return RefreshIndicator(
              color: AppColor.pitchGreen,
              backgroundColor: AppColor.card,
              onRefresh: _refresh,
              child: _buildProductContent(state.product, context),
            );
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

  /// «کشیدن برای تازه‌سازی»: جزییات محصول را دوباره می‌گیرد و تا رسیدن
  /// وضعیت نهاییِ بلاک منتظر می‌ماند تا حلقه‌ی نشانگر زودتر از داده محو نشود.
  Future<void> _refresh() async {
    final bloc = context.read<ProductDetailBloc>();
    bloc.add(FetchProductDetail(widget.productId));
    await bloc.stream
        .firstWhere((s) => s is! ProductDetailLoading)
        .timeout(const Duration(seconds: 20), onTimeout: () => bloc.state);
  }

  Widget _buildLoading() {
    return _ProductDetailSkeleton(desktop: AppBreakpoints.isDesktop(context));
  }

  Widget _buildError(String message, BuildContext context) {
    return Container(
      color: AppColor.milk,
      // اسکرول‌پذیر تا در حالت خطا هم بتوان صفحه را پایین کشید و تازه کرد
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
    ProductVariant? variant;
    SizeVariant? size;
    if (s is ProductDetailSizeChanged) {
      variant = s.productVariant;
      size = s.productSize;
    } else if (s is ProductDetailChangedState) {
      variant = s.productVariant;
      size = s.productSize; // رنگِ بی‌سایز: null
    }
    String? clean(String? v) {
      final t = (v ?? '').trim();
      return (t.isEmpty || t.toLowerCase() == 'null') ? null : t;
    }

    return CartItem(
      id: size?.id ?? product.id,
      name: product.nameFarsi ?? "",
      image: variant?.image ?? product.image ?? "",
      price: size?.price ?? product.price ?? 0,
      quantity: 1,
      productId: product.id,
      discountPrice: size?.discountPercentage ?? product.discountPercentage,
      size: clean(size?.size),
      // رنگ فقط وقتی معنا دارد که محصول بیش از یک رنگ داشته باشد
      colorName: product.variants.length > 1 ? clean(variant?.color) : null,
      colorRgb: clean(variant?.colorRgb),
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

  Future<void> _openAddToCart(
      BuildContext context, ProductDetail product, ProductDetailState s) async {
    if (!isLoggedIn(context)) {
      promptLoginIfNeeded(context);
      return;
    }
    if (!_guardStock(context, s)) return;

    _dropRunning = false;
    _cartButtonPopped = false;
    _pendingAddedMessage = null;

    final launch = await showModalBottomSheet<AddToCartLaunch>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddToCartModal(cartItem: _cartItemFor(product, s)),
    );

    if (!mounted || launch == null) return;

    // کالا از شیت جدا می‌شود و داخل دکمه‌ی گرد سبد می‌افتد؛ رسیدنش همان
    // لحظه‌ای است که دکمه پر می‌شود و بعد دیالوگ تأیید می‌آید.
    final target = CartDropAnimation.rectOf(_cartButtonKey);
    if (target == null) {
      _finishAdd();
      return;
    }
    _dropRunning = true;
    // بعد از await باید کانتکستِ خودِ State استفاده شود (همان که mounted
    // وضعیتش را می‌گوید)، نه پارامترِ گرفته‌شده پیش از باز شدن شیت.
    CartDropAnimation.run(
      this.context,
      imageUrl: launch.imageUrl,
      from: launch.sourceRect,
      to: target,
      onLanded: () {
        if (!mounted) return;
        _dropRunning = false;
        _finishAdd();
      },
    );
  }

  /// «پر» کردن دکمه‌ی سبد و نمایش دیالوگ تأیید — هر کدام فقط یک‌بار.
  void _finishAdd() {
    if (!_cartButtonPopped) {
      _cartButtonPopped = true;
      _cartButtonKey.currentState?.pop();
    }
    final message = _pendingAddedMessage;
    _pendingAddedMessage = null;
    if (message != null) _showAddedDialog(message);
  }

  /// دیالوگ «به سبد اضافه شد» — همان دیالوگ همیشگی.
  void _showAddedDialog(String message) {
    if (!mounted) return;
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
              message,
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

  /// واکنش به نتیجه‌ی افزودن به سبد؛ بین نوار پایین (موبایل) و دکمه‌های
  /// داخل پنل اطلاعات (دسکتاپ) مشترک است — منطق قبلی بدون تغییر.
  void _onCartState(BuildContext context, CartState cartState) {
    if (cartState is CartItemAdded) {
      _pendingAddedMessage = cartState.message;
      // اگر کالا هنوز در حال افتادن است، دیالوگ صبر می‌کند تا برسد؛ وگرنه
      // (مثلاً وقتی سرور دیرتر جواب داده) همان لحظه نشان داده می‌شود.
      if (!_dropRunning) _finishAdd();
    }
    // بارگذاریِ پس‌زمینه‌ی سبد برای کاربر مهمان خطا نیست؛ پیش‌تر همین
    // حالت روی هر صفحه‌ی محصول/دوره یک اسنک‌بار قرمز «نیاز به ورود دارید»
    // می‌انداخت، بی‌آنکه کاربر کاری کرده باشد.
    if (cartState is CartError &&
        cartState is! CartRequiresLogin &&
        cartState is! CartRefreshFailed) {
      // افزودن انجام نشد: انیمیشن و دیالوگ در انتظار باید لغو شوند.
      CartDropAnimation.cancel();
      _dropRunning = false;
      _pendingAddedMessage = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cartState.message,
              style: const TextStyle(fontFamily: 'Estedad')),
          backgroundColor: AppColor.danger,
        ),
      );
    }
  }

  /// دکمه‌ی «افزودن به سبد» — در موبایل داخل نوار پایین و در دسکتاپ داخل
  /// پنل اطلاعات؛ onPressed دقیقاً همان منطق قبلی است.
  Widget _actionButtons(BuildContext context, ProductDetail product,
      ProductDetailState variantState) {
    return Row(
      children: [
        Expanded(
          child: GradientButton(
            label: 'افزودن به سبد',
            height: 50,
            icon: const Icon(Icons.add_shopping_cart_rounded),
            onPressed: () => _openAddToCart(context, product, variantState),
          ),
        ),
        const SizedBox(width: 10),
        // دکمه‌ی گرد سبد، انتهای نوار (چپ در RTL): تا کالایی نیست سفید و
        // خطی است؛ با افزودن، سبز و توپر می‌شود و شمارنده می‌گیرد.
        BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) => CartPopButton(
            key: _cartButtonKey,
            count: _cartCount(cartState),
            onTap: () => Navigator.of(context).pushNamed('/cart'),
          ),
        ),
      ],
    );
  }

  // ==================== بدنه‌ی صفحه ====================

  Widget _buildProductContent(ProductDetail product, BuildContext context) {
    return BlocBuilder<ProductDetailVariantBloc, ProductDetailState>(
      builder: (context, variantState) {
        ProductVariant? variant;
        SizeVariant? size;
        if (variantState is ProductDetailSizeChanged) {
          variant = variantState.productVariant;
          size = variantState.productSize;
        } else if (variantState is ProductDetailChangedState) {
          variant = variantState.productVariant;
          size = variantState.productSize;
        } else if (_hasAnySize(product)) {
          // محصول سایز دارد ولی هنوز انتخاب اولیه نرسیده است
          return _ProductDetailSkeleton(
              desktop: AppBreakpoints.isDesktop(context));
        } else {
          // محصولی که هیچ سایزی ندارد هرگز رویداد انتخاب سایز نمی‌گیرد؛
          // پیش از این صفحه‌اش برای همیشه روی لودینگ می‌ماند.
          variant = product.variants.isEmpty ? null : product.variants.first;
        }
        // دسکتاپ: چیدمان کلاسیک فروشگاهی — گالری و پنل اطلاعات کنار هم
        // داخل پوسته‌ی ۱۲۰۰ پیکسلی، آکاردئون‌ها زیرشان به عرض کامل پوسته.
        if (AppBreakpoints.isDesktop(context)) {
          return ListView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 24),
              CenteredContent(
                child: Directionality(
                  // در RTL فرزند اول سمت راست می‌نشیند: گالری راست، اطلاعات چپ
                  textDirection: TextDirection.rtl,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 11, // ~۵۵٪ عرض
                        child:
                            _buildGalleryPanel(product, variant, desktop: true),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 9, // ~۴۵٪ عرض
                        child: _buildInfoPanel(
                          product,
                          variant,
                          size,
                          desktopActions:
                              _actionButtons(context, product, variantState),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildAccordions(product, desktop: true),
              const SizedBox(height: 40),
            ],
          );
        }
        return ListView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.zero,
          children: [
            _buildGalleryPanel(product, variant),
            _buildInfoPanel(product, variant, size),
            _buildAccordions(product),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  /// تصاویر گالری: تصاویر خودِ واریانت، و اگر واریانت تصویری نداشت (مثل
  /// محصولاتی که فقط تصاویر عمومی دارند) تصاویر خود محصول.
  List<String> _galleryImages(ProductDetail product, ProductVariant? variant) {
    final source = (variant != null && variant.images.isNotEmpty)
        ? variant.images
        : product.images;
    return source.map((u) => '${URLs.baseUrl}$u').toList();
  }

  /// آیا این محصول اصلاً واریانت سایزداری دارد؟
  static bool _hasAnySize(ProductDetail product) =>
      product.variants.any((v) => v.sizeVariants.isNotEmpty);

  /// رنگ واریانت انتخاب‌شده (برای تینت پس‌زمینه‌ی قاب تصویر)
  Color _variantColor(ProductVariant? variant) {
    final rgb = variant?.colorRgb;
    if (rgb == null || rgb.isEmpty) return AppColor.pitchGreen;
    try {
      return Color(0xff000000 + int.parse(rgb, radix: 16));
    } catch (_) {
      return AppColor.pitchGreen;
    }
  }

  static Color _parseRgb(String? rgb) {
    final hex = (rgb ?? '').trim().replaceFirst('#', '');
    final v = int.tryParse(hex, radix: 16);
    if (v == null || hex.isEmpty || hex.length > 6) return AppColor.lineStrong;
    return Color(0xff000000 + v);
  }

  /// تصویرِ کاشیِ رنگ: `image`ِ واریانت، وگرنه آیکن یا اولین عکسش.
  static String? _variantThumb(ProductVariant v) {
    for (final p in [
      v.image,
      v.icon,
      if (v.images.isNotEmpty) v.images.first
    ]) {
      final s = (p ?? '').trim();
      if (s.isEmpty || s.toLowerCase() == 'null') continue;
      return s.startsWith('http') ? s : '${URLs.baseUrl}$s';
    }
    return null;
  }

  /// با عوض شدنِ رنگ، همان سایزِ قبلی اگر در رنگِ تازه موجود بود می‌ماند؛
  /// وگرنه اولین سایزِ موجود. رنگِ بی‌سایز → null.
  static SizeVariant? _carrySize(ProductVariant next, SizeVariant? current) {
    if (next.sizeVariants.isEmpty) return null;
    if (current != null) {
      for (final sv in next.sizeVariants) {
        if (sv.size.trim() == current.size.trim() && sv.inStock) return sv;
      }
    }
    return firstAvailableSizeVariant(next.sizeVariants);
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
  Widget _buildGalleryPanel(ProductDetail product, ProductVariant? variant,
      {bool desktop = false}) {
    // محصولاتی که واریانت ندارند هم باید گالری داشته باشند؛ شناسه‌ی خود
    // محصول برای کلید انیمیشن استفاده می‌شود.
    final int variantKey = variant?.id ?? product.id;
    final images = _galleryImages(product, variant);
    final video = (variant?.video ?? product.video);
    final hasVideo = video != null && video.isNotEmpty;

    // آخرین آیتم ریل، ویدیو است (اگر وجود داشته باشد)
    final int itemCount = images.length + (hasVideo ? 1 : 0);
    // با تعویض رنگ، همان ایندکسی که کاربر قبلاً انتخاب کرده حفظ می‌شود؛
    // اگر واریانت جدید آن ایندکس را نداشته باشد، تصویر اول نشان داده می‌شود.
    final int index = (_carouselIndex >= 0 && _carouselIndex < itemCount)
        ? _carouselIndex
        : 0;
    final bool showVideo = hasVideo && index == images.length;

    // پس‌زمینه‌ی قاب تصویر با رنگ همان واریانت و آلفای ۰٫۵
    final Color panelTint = Color.alphaBlend(
      _variantColor(variant).withValues(alpha: 0.5),
      AppColor.milk,
    );

    return Padding(
      // در دسکتاپ پوسته‌ی مرکزی خودش گاتر دارد؛ پدینگ اضافی لازم نیست.
      padding: desktop
          ? EdgeInsets.zero
          : EdgeInsets.fromLTRB(
              16, MediaQuery.of(context).padding.top + 10, 16, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        height: desktop ? 520 : 400,
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
                  // عوض شدنِ رنگ: تصویرِ تازه با دایره‌ی مایع از پایین باز
                  // می‌شود. عوض شدنِ تامبنیل در همان رنگ: «مورف»ِ داخلی.
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 720),
                    transitionBuilder: (child, a) =>
                        liquidRevealTransition(child, a),
                    layoutBuilder: (current, previous) => Stack(
                      fit: StackFit.expand,
                      children: [...previous, if (current != null) current],
                    ),
                    child: KeyedSubtree(
                      key: ValueKey('variant-$variantKey'),
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
                                key: ValueKey('video-$variantKey'),
                                videoUrl: video,
                              )
                            : MouseRegion(
                                key: ValueKey('img-$variantKey-$index'),
                                cursor: images.isEmpty
                                    ? MouseCursor.defer
                                    : SystemMouseCursors.click,
                                child: GestureDetector(
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position:
                          Tween(begin: const Offset(0, 0.06), end: Offset.zero)
                              .animate(a),
                      child: child,
                    ),
                  ),
                  child: _buildThumbRail(
                    images: images,
                    selected: index,
                    video: hasVideo ? video : null,
                    variantId: variantKey,
                  ),
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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
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
      ),
    );
  }

  /// بخش پایین: کارت سفید گوشه‌گرد با نام، تعداد، قیمت، رنگ، سایز و توضیح
  ///
  /// [desktopActions] فقط در دسکتاپ پاس داده می‌شود: همان دو دکمه‌ی خرید
  /// نوار پایین که این‌جا داخل خود کارت رندر می‌شوند.
  Widget _buildInfoPanel(
      ProductDetail product, ProductVariant? variant, SizeVariant? size,
      {Widget? desktopActions}) {
    // اگر سایزی وجود ندارد، قیمت از خود محصول خوانده می‌شود؛ اگر آن هم
    // نباشد (بک‌اند price را null داده) به‌جای عدد، «تماس بگیرید» می‌آید.
    final int original = size?.price ?? product.price ?? 0;
    final int? pct = size?.discountPercentage ?? product.discountPercentage;
    final bool hasDiscount =
        pct != null && pct > 0 && pct < 100 && original > 0;
    final int finalPrice =
        hasDiscount ? (original * (1 - pct / 100)).toInt() : original;

    final Color stockColor = size == null
        ? AppColor.inkMuted
        : (!size.inStock
            ? AppColor.danger
            : (size.isLowStock ? AppColor.warning : AppColor.success));
    final String stockLabel = size == null
        ? 'برای اطلاع از موجودی تماس بگیرید'
        : (!size.inStock
            ? 'ناموجود'
            : (size.isLowStock
                ? 'تنها ${size.count} عدد باقی مانده'
                : 'موجود در انبار'));

    return Padding(
      // در دسکتاپ ستون‌بندی و گاتر با پوسته‌ی مرکزی است؛ این پدینگ فقط
      // برای حالت پشته‌ای موبایل لازم است.
      padding: desktopActions != null
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: ShapeDecoration(
          color: AppColor.card,
          shape: AppShapes.border(AppShapes.rXl),
          shadows: AppColor.cardShadow,
        ),
        padding: desktopActions != null
            ? const EdgeInsets.fromLTRB(22, 22, 22, 24)
            : const EdgeInsets.fromLTRB(18, 18, 18, 20),
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
                            Text(
                              original > 0
                                  ? '${thousandSeparator(finalPrice)} تومان'
                                  : 'استعلام قیمت',
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
                ],
              ),

              // انتخابِ رنگ با تصویرِ هر واریانت
              if (product.variants.length > 1) ...[
                const SizedBox(height: 20),
                VariantSwatchPicker(
                  tileSize: AppBreakpoints.isDesktop(context) ? 72 : 60,
                  selectedIndex: variant == null
                      ? 0
                      : product.variants
                          .indexWhere((v) => v.id == variant.id)
                          .clamp(0, product.variants.length - 1),
                  swatches: [
                    for (final v in product.variants)
                      VariantSwatch(
                        name: (v.color ?? '').trim().isEmpty ||
                                v.color!.trim().toLowerCase() == 'null'
                            ? 'رنگ'
                            : v.color!.trim(),
                        color: _parseRgb(v.colorRgb),
                        imageUrl: _variantThumb(v),
                        available: v.sizeVariants.isEmpty ||
                            v.sizeVariants.any((sv) => sv.inStock),
                      ),
                  ],
                  onSelected: (i) {
                    final next = product.variants[i];
                    // ایندکس تصویرِ گالری عمداً ریست نمی‌شود؛ اگر واریانت
                    // جدید همان تعداد تصویر را داشته باشد، کاربر روی همان
                    // زاویه‌ی قبلی می‌ماند.
                    context.read<ProductDetailVariantBloc>().add(
                        ChangeProductColorEvent(next, _carrySize(next, size)));
                  },
                ),
              ],

              if (variant != null && variant.sizeVariants.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'انتخاب سایز',
                      style: TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColor.ink,
                      ),
                    ),
                    const Spacer(),
                    if (ShoeSizeChart.appliesTo(
                      categoryName: product.category.nameFarsi,
                      productName: product.nameFarsi,
                      sizes: variant.sizeVariants.map((s) => s.size),
                    ))
                      _SizeGuideLink(
                        onTap: () => showShoeSizeGuide(
                          context,
                          availability: {
                            for (final sv in variant.sizeVariants)
                              sv.size.trim(): sv.inStock,
                          },
                          selectedSize: size?.size.trim(),
                          onPick: (eu) {
                            final pick = variant.sizeVariants
                                .where((sv) => sv.size.trim() == eu)
                                .firstOrNull;
                            if (pick == null) return;
                            context
                                .read<ProductDetailVariantBloc>()
                                .add(ChangeProductColorEvent(variant, pick));
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                SelectableCircleSize(
                  key: ValueKey(variant.id),
                  productSize: variant.sizeVariants.map((s) => s.size).toList(),
                  sizeAvailability:
                      variant.sizeVariants.map((s) => s.inStock).toList(),
                  // انتخاب از «راهنمای سایز» هم باید اینجا دیده شود
                  selectedSizeIndex: size == null
                      ? null
                      : (() {
                          final i = variant.sizeVariants
                              .indexWhere((sv) => sv.id == size.id);
                          return i < 0 ? null : i;
                        })(),
                  onSizeSelected: (int i) {
                    context.read<ProductDetailVariantBloc>().add(
                        ChangeProductColorEvent(
                            variant, variant.sizeVariants[i]));
                  },
                ),
              ],

              const SizedBox(height: 16),
              PillTag(
                label: stockLabel,
                icon: size == null || size.inStock
                    ? Icons.check_circle_outline
                    : Icons.remove_shopping_cart_outlined,
                color: stockColor,
              ),

              // دسکتاپ: دکمه‌های خرید همین‌جا (نوار پایین پنهان است)
              if (desktopActions != null) ...[
                const SizedBox(height: 22),
                desktopActions,
              ],

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
  ///
  /// در دسکتاپ زیر دو ستون گالری/اطلاعات، به عرض کامل پوسته‌ی مرکزی
  /// رندر می‌شود.
  Widget _buildAccordions(ProductDetail product, {bool desktop = false}) {
    final content = Padding(
      padding: desktop
          ? const EdgeInsets.only(top: 24)
          : const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
              // نظرها فقط یک‌جا رندر می‌شوند. پیش‌تر ProductReviewsSection
              // سه نظر اول را نشان می‌داد و بلافاصله یک ListView دوم همه را
              // دوباره تکرار می‌کرد — با ایندکسِ حلقه به‌جای نامِ کاربر
              // (« ۰ : ») و امتیازِ ثابتِ ۵ ستاره برای هر نظر، که هیچ‌کدام
              // داده‌ی واقعی نبودند.
              child: ProductReviewsSection(
                productId: product.id,
                avgRate: product.avgRate,
                ratingDistribution: product.ratingDistribution,
                comments: product.comments,
                // بعد از ثبت نظر/امتیاز، محصول دوباره از سرور خوانده
                // می‌شود تا میانگین امتیاز به‌روز شود
                onSubmitted: () => context
                    .read<ProductDetailBloc>()
                    .add(FetchProductDetail(widget.productId)),
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
    return desktop ? CenteredContent(child: content) : content;
  }
}

/// اسکلتونِ صفحه‌ی جزئیات محصول: دقیقاً همان چیدمانِ صفحه‌ی بارگذاری‌شده
/// (قابِ گالری + ریلِ تامبنیل، کارتِ اطلاعات، آکاردئون‌ها) با شیمر، تا هنگام
/// آمدنِ داده هیچ پرشِ چیدمانی حس نشود.
///
/// نکته: ShaderMaskِ [Shimmer] روی هر پیکسلِ مات کشیده می‌شود، پس اگر
/// کارت‌ها پس‌زمینه‌ی سفید داشته باشند با استخوان‌ها یکی می‌شوند و ساختار
/// دیده نمی‌شود؛ این‌جا فقط استخوان روی پس‌زمینه‌ی صفحه چیده شده است.
class _ProductDetailSkeleton extends StatelessWidget {
  const _ProductDetailSkeleton({required this.desktop});

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColor.milk,
      child: Shimmer(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          child: desktop ? _desktop(context) : _mobile(context),
        ),
      ),
    );
  }

  // ---- موبایل: گالری، کارت اطلاعات و آکاردئون‌ها روی هم ----
  Widget _mobile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
              16, MediaQuery.of(context).padding.top + 10, 16, 0),
          child: _gallery(height: 400),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(34, 32, 34, 0),
          child: _InfoBones(),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 30, 16, 0),
          child: _AccordionBones(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ---- دسکتاپ: گالری راست، اطلاعات چپ، آکاردئون‌ها تمام‌عرض زیرشان ----
  Widget _desktop(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        CenteredContent(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 11, child: _gallery(height: 520)), // ~۵۵٪ عرض
                const SizedBox(width: 24),
                const Expanded(
                  flex: 9,
                  child: Padding(
                    padding: EdgeInsets.only(top: 22),
                    child: _InfoBones(withActions: true),
                  ),
                ), // ~۴۵٪ عرض
              ],
            ),
          ),
        ),
        const CenteredContent(
          child: Padding(
            padding: EdgeInsets.only(top: 32),
            child: _AccordionBones(),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  /// قابِ گالری: هدرِ شناور، رسانه‌ی اصلی و ریلِ عمودیِ تامبنیل
  Widget _gallery({required double height}) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // رسانه‌ی اصلی — فضای سمت راست برای ریل تامبنیل خالی می‌ماند
          const Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 76, 108, 20),
              child: Bone(radius: AppShapes.rLg),
            ),
          ),
          // هدر شناور: بازگشت (راست)، عنوان و اشتراک‌گذاری (چپ)
          const Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Bone.circle(size: 40),
                Expanded(child: Center(child: Bone(width: 64, height: 16))),
                Bone.circle(size: 40),
              ],
            ),
          ),
          // ریل عمودی تامبنیل، چسبیده به لبه‌ی راست
          const Positioned(
            right: 14,
            top: 76,
            width: 76,
            child: Column(
              children: [
                Bone(height: 72, radius: AppShapes.rMd),
                SizedBox(height: 10),
                Bone(height: 72, radius: AppShapes.rMd),
                SizedBox(height: 10),
                Bone(height: 72, radius: AppShapes.rMd),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// کارتِ اطلاعات: نام، قیمت، نمونه‌های رنگ، سایزها، بجِ موجودی و توضیحات
class _InfoBones extends StatelessWidget {
  const _InfoBones({this.withActions = false});

  /// دسکتاپ دکمه‌های خرید را داخل همین کارت دارد
  final bool withActions;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // نام محصول (دو خط)
          const Bone(height: 19, radius: 6),
          const SizedBox(height: 10),
          const Bone(width: 180, height: 19, radius: 6),
          const SizedBox(height: 18),
          // قیمت + نمونه‌های رنگ
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Bone(width: 150, height: 17, radius: 6),
                    SizedBox(height: 8),
                    Bone(width: 108, height: 12, radius: 6),
                  ],
                ),
              ),
              Bone.circle(size: 22),
              SizedBox(width: 8),
              Bone.circle(size: 22),
              SizedBox(width: 8),
              Bone.circle(size: 22),
            ],
          ),
          // انتخاب سایز
          const SizedBox(height: 22),
          const Bone(width: 72, height: 14, radius: 6),
          const SizedBox(height: 12),
          const Row(
            children: [
              Bone.circle(size: 40),
              SizedBox(width: 10),
              Bone.circle(size: 40),
              SizedBox(width: 10),
              Bone.circle(size: 40),
              SizedBox(width: 10),
              Bone.circle(size: 40),
            ],
          ),
          // بجِ موجودی
          const SizedBox(height: 18),
          const Bone(width: 140, height: 30, radius: 15),
          if (withActions) ...[
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: Bone(height: 52, radius: 26)),
                SizedBox(width: 10),
                Expanded(child: Bone(height: 52, radius: 26)),
              ],
            ),
          ],
          // توضیحات
          const SizedBox(height: 22),
          const Bone(width: 64, height: 14, radius: 6),
          const SizedBox(height: 12),
          const Bone(height: 13, radius: 6),
          const SizedBox(height: 9),
          const Bone(height: 13, radius: 6),
          const SizedBox(height: 9),
          const Bone(width: 220, height: 13, radius: 6),
        ],
      ),
    );
  }
}

/// آکاردئون‌های بسته: فقط سرصفحه‌ها دیده می‌شوند (ارتفاع ۵۸ = ۳۰ آیکن + ۲۸ پدینگ)
class _AccordionBones extends StatelessWidget {
  const _AccordionBones();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Bone(height: 58, radius: AppShapes.rLg),
        SizedBox(height: 12),
        Bone(height: 58, radius: AppShapes.rLg),
        SizedBox(height: 12),
        Bone(height: 58, radius: AppShapes.rLg),
        SizedBox(height: 12),
        Bone(height: 58, radius: AppShapes.rLg),
      ],
    );
  }
}

/// لینکِ «راهنمای سایز» کنارِ عنوانِ انتخابِ سایز
class _SizeGuideLink extends StatelessWidget {
  const _SizeGuideLink({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.pitchGreenSoft,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.straighten_rounded,
                  size: 16, color: AppColor.pitchGreen),
              SizedBox(width: 6),
              Text(
                'راهنمای سایز',
                style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColor.pitchGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
