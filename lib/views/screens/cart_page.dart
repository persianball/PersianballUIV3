// views/screens/cart_page.dart
import 'package:flutter/material.dart';
import 'package:marketky/views/widgets/app_buttons.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/CartModel.dart';
import 'package:marketky/views/widgets/pro_cart_item.dart';
import 'package:marketky/views/widgets/course_cart_item.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/views/widgets/checkout_timeline.dart';
import 'package:marketky/views/screens/address_selection_page.dart';
import 'package:marketky/views/screens/login_page.dart';
import '../../bloc/cart/cart_bloc.dart';
import 'package:marketky/views/widgets/page_container.dart';
import 'package:marketky/views/widgets/motion.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}


class _CartPageState extends State<CartPage> {
  bool _productsExpanded = true;
  bool _coursesExpanded = true;

  @override
  void initState() {
    super.initState();
    context.read<CartBloc>().add(LoadCart(context));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.milk,
      appBar: _buildAppBar(),
      bottomNavigationBar: _buildCheckoutButton(),
      body: BlocBuilder<CartBloc, CartState>(
        buildWhen: (previous, current) => (current is CartLoaded ||
            current is CartError ||
            current is CartInitial),
        builder: (context, state) {
          if (state is CartLoaded) {
            return _buildCartContent(state.cart);
          } else if (state is CartError) {
            return _buildErrorOrLoginPrompt(context, state.message);
          }
          return const Center(
              child: CircularProgressIndicator(color: AppColor.pitchGreen));
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    // چیدمان اپ‌بار راست‌به‌چپ: عنوان سمت راست و دکمه بازگشت سمت راست
    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: AppBar(
          backgroundColor: AppColor.milk,
          elevation: 0,
          title: BlocBuilder<CartBloc, CartState>(
            buildWhen: (previous, current) =>
                current is CartLoaded ||
                current is CartError ||
                current is CartInitial,
            builder: (context, state) {
              final count = state is CartLoaded
                  ? (state.cart.results.length > 0
                      ? state.cart.results[0].items.length
                      : 0)
                  : 0;
              return Column(
                children: [
                  Text('سبد خرید',
                      style: TextStyle(
                          fontFamily: 'Estedad', color: AppColor.onSurface)),
                  Text(' $count آیتم ',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColor.onSurfaceVariant)),
                ],
              );
            },
          ),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColor.ink),
          ),
        ),
      ),
    );
  }

  /// حالت خالی سبد خرید
  Widget _buildEmptyCart() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: const ShapeDecoration(
                  color: AppColor.pitchGreenSoft,
                  shape: CircleBorder(),
                ),
                child: const Icon(Icons.shopping_bag_outlined,
                    size: 56, color: AppColor.pitchGreen),
              ),
              const SizedBox(height: 22),
              const Text(
                'سبد خرید خالی است',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColor.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'هنوز کالایی به سبد اضافه نکرده‌اید',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 13,
                  color: AppColor.inkMuted,
                ),
              ),
              const SizedBox(height: 22),
              GradientButton(
                label: 'مشاهده محصولات',
                expand: false,
                height: 46,
                icon: const Icon(Icons.storefront_outlined),
                onPressed: () => Navigator.of(context).pushNamed('/catalog'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// حالت مهمان یا خطا: پیام مناسب همراه با دکمه ورود
  Widget _buildErrorOrLoginPrompt(BuildContext context, String message) {
    final needsLogin = message.contains('ورود');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: const ShapeDecoration(
                  color: AppColor.pitchGreenSoft,
                  shape: CircleBorder(),
                ),
                child: Icon(
                  needsLogin ? Icons.lock_outline : Icons.error_outline,
                  size: 56,
                  color: AppColor.pitchGreen,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                needsLogin ? 'وارد حساب کاربری نشده‌اید' : 'خطایی رخ داد',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColor.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                needsLogin
                    ? 'برای مشاهده سبد خرید ابتدا وارد حساب کاربری شوید'
                    : message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 13,
                  color: AppColor.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 20),
              GradientButton(
                label: needsLogin ? 'ورود به حساب کاربری' : 'تلاش مجدد',
                expand: false,
                height: 46,
                icon: Icon(
                    needsLogin ? Icons.login_rounded : Icons.refresh_rounded),
                onPressed: () async {
                  if (needsLogin) {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LoginPage(popOnSuccess: true),
                      ),
                    );
                    if (context.mounted) {
                      context.read<CartBloc>().add(LoadCart(context));
                    }
                  } else {
                    context.read<CartBloc>().add(LoadCart(context));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartContent(AllCartFromBackend cart) {
    if (cart.count == 0 ||
        cart.results.isEmpty ||
        cart.results[0].items.isEmpty) {
      return _buildEmptyCart();
    }

    final items = cart.results[0].items;
    final products = items.where((item) => item.product != null).toList();
    final courses = items.where((item) => item.course != null).toList();

    return PageContainer(
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Step 1 timeline
          const CheckoutTimeline(currentStep: 0),
          const SizedBox(height: 12),

          // Products Section
          if (products.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'محصولات',
              icon: Icons.shopping_bag,
              count: products.length,
              expanded: _productsExpanded,
              onToggle: () =>
                  setState(() => _productsExpanded = !_productsExpanded),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _productsExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  separatorBuilder: (_, i) => SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 45 * (i % 6)),
                      child: ProCartItemCard(
                        cartItemFromBackend: products[i],
                        priceFromBack: cart.results[0].price,
                      ),
                    );
                  },
                ),
              ),
              secondChild: const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: 20),
          ],

          // Courses Section
          if (courses.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'دوره‌های آموزشی',
              icon: Icons.school,
              count: courses.length,
              expanded: _coursesExpanded,
              onToggle: () =>
                  setState(() => _coursesExpanded = !_coursesExpanded),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _coursesExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: courses.length,
                  separatorBuilder: (_, i) => SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 45 * (i % 6)),
                      child: CourseCartItemCard(
                        cartItemFromBackend: courses[i],
                        priceFromBack: cart.results[0].price,
                      ),
                    );
                  },
                ),
              ),
              secondChild: const SizedBox(width: double.infinity),
            ),
          ],
        ],
      ),
    );
  }

  /// هدر راست‌چین و قابل جمع‌شدن هر بخش، با تعداد آیتم به‌صورت مینیمال.
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required int count,
    required bool expanded,
    required VoidCallback onToggle,
  }) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: InkWell(
        onTap: onToggle,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColor.goldEnd.withOpacity(0.08),
            border: Border.all(color: AppColor.goldEnd.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColor.goldEnd, size: 18),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColor.goldEnd,
                  fontFamily: 'Estedad',
                ),
              ),
              SizedBox(width: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColor.goldEnd.withOpacity(0.15),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColor.goldEnd,
                    fontFamily: 'Estedad',
                  ),
                ),
              ),
              Spacer(),
              AnimatedRotation(
                turns: expanded ? 0 : -0.25,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.expand_more, color: AppColor.goldEnd, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return SafeArea(
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoaded) {
            // سبد خالی: دکمه تسویه و انتخاب آدرس نمایش داده نمی‌شود
            final cart = state.cart;
            final isEmpty = cart.count == 0 ||
                cart.results.isEmpty ||
                cart.results[0].items.isEmpty;
            if (isEmpty) return SizedBox.shrink();

            return Container(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColor.milk,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: AppColor.outlineVariantDark),
                      borderRadius: AppShapes.radius(AppShapes.rMd),
                    ),
                    builder: (ctx) {
                      return DraggableScrollableSheet(
                        expand: false,
                        initialChildSize: 0.55,
                        minChildSize: 0.35,
                        maxChildSize: 0.9,
                        builder: (context, scrollController) {
                          String? selectedMethod; // 'post' | 'peyk' | 'free'
                          return StatefulBuilder(
                            builder: (context, setModalState) {
                              final price =
                                  (context.read<CartBloc>().state as CartLoaded)
                                          .cart
                                          .results
                                          .isNotEmpty
                                      ? (context.read<CartBloc>().state
                                              as CartLoaded)
                                          .cart
                                          .results[0]
                                          .price
                                      : TotalPriceFromBack();
                              final int base = price.price ?? 0;
                              final int discounted =
                                  price.discountedPrice ?? base;
                              final int tax = price.nat ?? 0;
                              final bool isFree = price.isFreeShipping ?? false;
                              final int postPrice =
                                  price.postShippingPrice ?? 0;
                              final int peykPrice =
                                  price.peykShippingPrice ?? 0;

                              selectedMethod ??= isFree ? 'free' : 'post';
                              final int shippingCost =
                                  (selectedMethod == 'free')
                                      ? 0
                                      : (selectedMethod == 'peyk'
                                          ? peykPrice
                                          : postPrice);
                              final int payable =
                                  base - discounted + tax + shippingCost;

                              Widget priceRow(String label, String value,
                                  {Color? valueColor}) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(label,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColor.onSurfaceVariant)),
                                      Text(value,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: valueColor ??
                                                  AppColor.onSurface)),
                                    ],
                                  ),
                                );
                              }

                              return Directionality(
                                textDirection: TextDirection.rtl,
                                child: Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                          color: AppColor.outlineVariantDark,
                                          borderRadius:
                                              BorderRadius.circular(2)),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text('جزئیات سفارش',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColor.onSurface)),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: ListView(
                                        controller: scrollController,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        children: [
                                          // Totals
                                          Card(
                                            elevation: 0,
                                            color: AppColor.surfaceContainer,
                                            shape: RoundedRectangleBorder(
                                                borderRadius: AppShapes.radius(AppShapes.rMd),
                                                side: BorderSide(
                                                    color: AppColor
                                                        .outlineVariantDark)),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Column(
                                                children: [
                                                  priceRow('قیمت کل',
                                                      '${thousandSeparator(base)} تومان'),
                                                  priceRow('تخفیف',
                                                      '${thousandSeparator(discounted)} تومان',
                                                      valueColor:
                                                          AppColor.errorDark),
                                                  priceRow('مالیات',
                                                      '${thousandSeparator(tax)} تومان'),
                                                  priceRow(
                                                      'هزینه ارسال',
                                                      isFree
                                                          ? 'رایگان'
                                                          : '${thousandSeparator(shippingCost)} تومان',
                                                      valueColor: isFree
                                                          ? AppColor.successDark
                                                          : null),
                                                  Divider(
                                                      height: 24,
                                                      color: AppColor
                                                          .outlineVariantDark),
                                                  priceRow('مبلغ قابل پرداخت',
                                                      '${thousandSeparator(payable)} تومان',
                                                      valueColor:
                                                          AppColor.goldEnd),
                                                ],
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 12),

                                          // Shipping method
                                          Text('روش ارسال',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppColor.onSurfaceVariant)),
                                          const SizedBox(height: 8),
                                          if (isFree)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10),
                                              decoration: BoxDecoration(
                                                color: AppColor.successDark
                                                    .withOpacity(0.1),
                                                border: Border.all(
                                                    color: AppColor
                                                        .successDark
                                                        .withOpacity(0.4)),
                                              ),
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.local_shipping,
                                                      color:
                                                          AppColor.successDark),
                                                  SizedBox(width: 8),
                                                  Text(
                                                      'ارسال رایگان برای سفارش شما فعال است',
                                                      style: TextStyle(
                                                          color: AppColor
                                                              .onSurface)),
                                                ],
                                              ),
                                            )
                                          else ...[
                                            RadioListTile<String>(
                                              value: 'post',
                                              groupValue: selectedMethod,
                                              activeColor: AppColor.goldEnd,
                                              onChanged: (v) => setModalState(
                                                  () => selectedMethod = v),
                                              title: const Text('ارسال توسط پست',
                                                  style: TextStyle(
                                                      color:
                                                          AppColor.onSurface)),
                                              secondary: Text(
                                                  '${thousandSeparator(postPrice)} تومان',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppColor.onSurface)),
                                            ),
                                            RadioListTile<String>(
                                              value: 'peyk',
                                              groupValue: selectedMethod,
                                              activeColor: AppColor.goldEnd,
                                              onChanged: (v) => setModalState(
                                                  () => selectedMethod = v),
                                              title: const Text('ارسال توسط پیک',
                                                  style: TextStyle(
                                                      color:
                                                          AppColor.onSurface)),
                                              secondary: Text(
                                                  '${thousandSeparator(peykPrice)} تومان',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppColor.onSurface)),
                                            ),
                                          ],

                                          const SizedBox(height: 16),

                                          // Continue button
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                // Pass cart and selected delivery method forward
                                                final cart = (context
                                                        .read<CartBloc>()
                                                        .state as CartLoaded)
                                                    .cart;
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const AddressSelectionPage(),
                                                    settings: RouteSettings(
                                                        arguments: {
                                                          'cart': cart,
                                                          'delivery_method':
                                                              selectedMethod,
                                                        }),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColor.goldEnd,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16),
                                                shape:
                                                    AppShapes.pill,
                                              ),
                                              child: const Text('انتخاب آدرس',
                                                  style: TextStyle(
                                                      color: AppColor.onGold)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
                child: const Text(
                  'تسویه و انتخاب آدرس',
                  style: TextStyle(color: AppColor.onGold, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.goldEnd,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: AppShapes.pill,
                ),
              ),
            );
          }
          // مهم: Container() خالی در bottomNavigationBar تمام ارتفاع صفحه را
          // می‌گیرد و بدنه‌ی صفحه را به ارتفاع صفر می‌رساند (سبد خالی دیده
          // نمی‌شد). باید صراحتاً صفر باشد.
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
