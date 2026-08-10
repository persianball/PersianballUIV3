import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:marketky/views/screens/search_page.dart';

import '../../bloc/cart/cart_bloc.dart';
import '../screens/cart_page.dart';
import 'custom_icon_button_widget.dart';
import 'dummy_search_widget_1.dart';
import '../screens/message_page.dart';

Widget buildCarouselItem(BuildContext context,String imageUrl) {
  context.read<CartBloc>().add(LoadCart(context));
  return Container(
    width: MediaQuery.of(context).size.width,
    padding: EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage(imageUrl),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Colors.black.withOpacity(0.3), // فیلتر تیره برای خوانایی متن
          BlendMode.darken,
        ),
      ),
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
              Expanded(
                child: Text(
                  'بهترین ست‌های پوشاک\nرا برای خود پیدا کنید.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                textDirection: TextDirection.ltr,
                children: [
                  BlocBuilder<CartBloc,CartState>(
                    builder: (context,state) {
                      return CustomIconButtonWidget(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => CartPage()));
                        },
                        value: state is CartLoaded ? state.cart.results.length > 0?
                            state.cart.results[0].items.length
                            : 0 : 0,
                        icon: SvgPicture.asset(
                          'assets/icons/Bag.svg',
                          color: Colors.white,
                        ),
                      );
                    }
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
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
  );
}