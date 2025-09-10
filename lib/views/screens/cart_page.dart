// views/screens/cart_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/CartModel.dart';
import 'package:marketky/views/screens/order_success_page.dart';
import 'package:marketky/views/widgets/cart_tile.dart';
import 'package:marketky/views/widgets/pro_cart_item.dart';
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
        builder: (context, state) {
          if (state is CartLoading) {
            return Center(child: Column(
              children: [
                //CircularProgressIndicator(),
              ],
            ));
          } else if (state is CartLoaded) {
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
          return Container();
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if(state is CartLoading){
            return CircularProgressIndicator();
          }
          final count = state is CartLoaded ? state.cart.results.length>0?
              state.cart.results[0].items.length:0 : 0;
          return Column(
            children: [
              Text('سبد خرید', style: TextStyle(fontFamily: 'Estedad', color: Colors.black)),
              Text('$count آیتم', style: TextStyle(fontSize: 10, color: Colors.black.withOpacity(0.7))),
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
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => OrderSuccessPage()));
                },
                child: Text('انتخاب آدرس',
                style: TextStyle(
                    color: Colors.white70
                ),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  padding: EdgeInsets.symmetric(vertical: 18),
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