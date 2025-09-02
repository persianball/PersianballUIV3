// views/screens/cart_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/CartModel.dart';
import 'package:marketky/views/screens/order_success_page.dart';
import 'package:marketky/views/widgets/cart_tile.dart';
import '../../bloc/cart/cart_bloc.dart';


class CartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: _buildCheckoutButton(context),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          print(state);
          if (state is CartLoaded && state.items.isNotEmpty) {
            final items = state.items;
            final total = items.fold(0, (sum, item) => sum + item.price * item.quantity);

            return ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildCartItems(items, context),
                _buildShippingInfo(),
                _buildShippingMethod(total),
              ],
            );
          } else if (state is CartLoaded && state.items.isEmpty) {
            return Center(
              child: Text(
                'سبد خرید شما خالی است',
                style: TextStyle(fontFamily: 'Estedad', fontSize: 16),
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      title: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          final count = state is CartLoaded ? state.items.length : 0;
          return Column(
            children: [
              Text(
                'سبد خرید',
                style: TextStyle(fontFamily: 'Estedad', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                '$count آیتم',
                style: TextStyle(fontSize: 10, color: Colors.black.withOpacity(0.7), fontFamily: 'Estedad'),
              ),
            ],
          );
        },
      ),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: SvgPicture.asset('assets/icons/Arrow-left.svg'),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Container(height: 1, color: AppColor.primarySoft),
      ),
    );
  }

  Widget _buildCartItems(List<CartModel> items, BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, i) => SizedBox(height: 16),
      itemBuilder: (_, index) => CartTile( data:items[index]),
    );
  }

  Widget _buildCheckoutButton(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state is CartLoaded) {
          final total = state.items.fold(0, (sum, item) => sum + item.price * item.quantity);
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColor.border, width: 1)),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => OrderSuccessPage()),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 6,
                    child: Text(
                      'تسویه حساب',
                      style: TextStyle(
                        fontFamily: 'Estedad',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Container(width: 2, height: 26, color: Colors.white.withOpacity(0.5)),
                  Flexible(
                    flex: 6,
                    child: Text(
                      '$total تومان',
                      style: TextStyle(
                        fontFamily: 'Estedad',
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                padding: EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          );
        }
        return Container();
      },
    );
  }

  Widget _buildShippingInfo() {
    return Container(
      margin: EdgeInsets.only(top: 24),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('اطلاعات ارسال', style: TextStyle(fontFamily: 'Estedad', fontSize: 14, fontWeight: FontWeight.w600)),
              ElevatedButton(
                onPressed: () {},
                child: SvgPicture.asset('assets/icons/Pencil.svg', width: 16, color: AppColor.secondary),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.border,
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(0),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          _buildRow(Icons.person, 'احمد رضا فلسفی'),
          _buildRow(Icons.home, 'تهران، خیابان ولیعصر'),
          _buildRow(Icons.phone, '0912-345-6789'),
        ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(margin: EdgeInsets.only(right: 12), child: Icon(icon, size: 18)),
          Expanded(child: Text(text, style: TextStyle(color: AppColor.secondary.withOpacity(0.7)))),
        ],
      ),
    );
  }

  Widget _buildShippingMethod(int total) {
    return Container(
      margin: EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.border, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColor.primarySoft,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('روش ارسال', style: TextStyle(fontSize: 10, fontFamily: 'Estedad')),
                    Text('ارسال رایگان', style: TextStyle(fontFamily: 'Estedad', fontWeight: FontWeight.w600)),
                  ],
                ),
                Text('رایگان', style: TextStyle(fontFamily: 'Estedad', color: AppColor.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow('ارسال', '۳-۵ روز', 'رایگان'),
                _buildDetailRow('مجموع', '${"state.items.length"} آیتم', '$total تومان'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String left, String center, String right) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(child: Text(left, style: TextStyle(fontFamily: 'Estedad', fontWeight: FontWeight.w600))),
          Expanded(child: Text(center, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Estedad'))),
          Expanded(child: Text(right, textAlign: TextAlign.end, style: TextStyle(fontFamily: 'Estedad', fontWeight: FontWeight.w600, color: AppColor.primary))),
        ],
      ),
    );
  }
}