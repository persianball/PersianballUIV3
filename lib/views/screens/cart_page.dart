// views/screens/cart_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/CartModel.dart';
import 'package:marketky/views/screens/order_success_page.dart';
import 'package:marketky/views/widgets/cart_tile.dart';
import 'package:marketky/views/widgets/pro_cart_item.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import '../../bloc/cart/cart_bloc.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    context.read<CartBloc>().add(LoadCart());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      bottomNavigationBar: _buildCheckoutButton(),
      body: BlocBuilder<CartBloc, CartState>(
        buildWhen: (previous, current) =>
        (current is CartLoaded || current is CartError || current is CartInitial),
        builder: (context, state) {
          if (state is CartLoaded) {
            return _buildCartContent(state.cart);
          } else if (state is CartError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  ElevatedButton(
                    onPressed: () => context.read<CartBloc>().add(LoadCart()),
                    child: Text('تلاش مجدد'),
                  ),
                ],
              ),
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: BlocBuilder<CartBloc, CartState>(
        buildWhen: (previous, current) =>
            current is CartLoaded || current is CartError || current is CartInitial,
        builder: (context, state) {
          final count = state is CartLoaded
              ? (state.cart.results.length > 0
                  ? state.cart.results[0].items.length
                  : 0)
              : 0;
          return Column(
            children: [
              Text('سبد خرید', style: TextStyle(fontFamily: 'Estedad', color: Colors.black)),
              Directionality(
                textDirection: TextDirection.rtl,
                  child: Text(' $countمحصول ', style: TextStyle(fontSize: 10, color: Colors.black.withOpacity(0.7)))),
            ],
          );
        },
      ),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: SvgPicture.asset('assets/icons/Arrow-left.svg'),
      ),
    );
  }

  Widget _buildCartContent(AllCartFromBackend cart) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: cart.count > 0 ? cart.results[0].items.length : 0,
          separatorBuilder: (_, i) => SizedBox(height: 16),
          itemBuilder: (_, i) {
            // final item = cart.items[i];
            // return CartTile(
            //   data: item,
            //   onRemove: () => context.read<CartBloc>().add(RemoveFromCart(item.id)),
            //   onChangeQuantity: (qty) => context.read<CartBloc>().add(UpdateQuantity(item.id,item.productId, qty)),
            // );
            return ProCartItemCard(cartItemFromBackend: cart.results[0].items[i],priceFromBack: cart.results[0].price,);
          },
        ),
        // بقیه بخش‌ها (حمل و نقل، قیمت کل و ...)
      ],
    );
  }

  Widget _buildCheckoutButton() {
    return SafeArea(
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoaded) {
            return Container(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                              final price = (context.read<CartBloc>().state as CartLoaded).cart.results.isNotEmpty
                                  ? (context.read<CartBloc>().state as CartLoaded).cart.results[0].price
                                  : TotalPriceFromBack();
                              final int base = price.price ?? 0;
                              final int discounted = price.discountedPrice ?? base;
                              final int tax = price.nat ?? 0;
                              final bool isFree = price.isFreeShipping ?? false;
                              final int postPrice = price.postShippingPrice ?? 0;
                              final int peykPrice = price.peykShippingPrice ?? 0;

                              selectedMethod ??= isFree ? 'free' : 'post';
                              final int shippingCost = (selectedMethod == 'free')
                                  ? 0
                                  : (selectedMethod == 'peyk' ? peykPrice : postPrice);
                              final int discount = (base - discounted) < 0 ? 0 : (base - discounted);
                              final int payable = discounted + tax + shippingCost;

                              Widget priceRow(String label, String value, {Color? valueColor}) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? Colors.black)),
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
                                      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text('جزئیات سفارش', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: ListView(
                                        controller: scrollController,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        children: [
                                          // Totals
                                          Card(
                                            elevation: 0,
                                            color: Colors.grey.shade50,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                children: [
                                                  priceRow('قیمت کل', '${thousandSeparator(price.price??0)} تومان'),
                                                  priceRow('تخفیف', '${thousandSeparator(discounted)} تومان', valueColor: Colors.redAccent),
                                                  priceRow('مالیات', '${thousandSeparator(tax)} تومان'),
                                                  priceRow('هزینه ارسال', isFree ? 'رایگان' : '${thousandSeparator(shippingCost)} تومان', valueColor: isFree ? Colors.green : null),
                                                  const Divider(height: 24),
                                                  priceRow('مبلغ قابل پرداخت', '${thousandSeparator(discount)} تومان', valueColor: Colors.black),
                                                ],
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 12),

                                          // Shipping method
                                          Text('روش ارسال', style: TextStyle(fontSize: 14, color: Colors.grey.shade800)),
                                          const SizedBox(height: 8),
                                          if (isFree)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: Colors.green.shade200),
                                              ),
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.local_shipping, color: Colors.green),
                                                  SizedBox(width: 8),
                                                  Text('ارسال رایگان برای سفارش شما فعال است'),
                                                ],
                                              ),
                                            )
                                          else ...[
                                            RadioListTile<String>(
                                              value: 'post',
                                              groupValue: selectedMethod,
                                              onChanged: (v) => setModalState(() => selectedMethod = v),
                                              title: const Text('ارسال توسط پست'),
                                              secondary: Text('${thousandSeparator(postPrice)} تومان', style: const TextStyle(fontWeight: FontWeight.w600)),
                                            ),
                                            RadioListTile<String>(
                                              value: 'peyk',
                                              groupValue: selectedMethod,
                                              onChanged: (v) => setModalState(() => selectedMethod = v),
                                              title: const Text('ارسال توسط پیک'),
                                              secondary: Text('${thousandSeparator(peykPrice)} تومان', style: const TextStyle(fontWeight: FontWeight.w600)),
                                            ),
                                          ],

                                          const SizedBox(height: 16),

                                          // Continue button
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => OrderSuccessPage()));
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColor.primary,
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              child: const Text('انتخاب آدرس', style: TextStyle(color: Colors.white)),
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
                  'مشاهده جزئیات سفارش',
                  style: TextStyle(color: Colors.white70),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            );
          }
          return Container();
        },
      ),
    );
  }
}