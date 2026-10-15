import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_ball/constant/app_color.dart';

class MainAppBar extends StatefulWidget implements PreferredSizeWidget {
  final int cartValue;
  final int chatValue;
  final bool dark;

  MainAppBar({
    required this.cartValue,
    required this.chatValue,
    this.dark = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  _MainAppBarState createState() => _MainAppBarState();
}

class _MainAppBarState extends State<MainAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      backgroundColor: AppColor.milk,
      elevation: 0,
      title: Row(
        children: [
          // DummySearchWidget2(
          //   onTap: () {
          //     Navigator.of(context).push(
          //       MaterialPageRoute(
          //         builder: (context) => SearchPage(),
          //       ),
          //     );
          //   },
          // ),
          // CustomIconButtonWidget(
          //   onTap: () {
          //     Navigator.of(context).push(MaterialPageRoute(builder: (context) => CartPage()));
          //   },
          //   value: widget.cartValue,
          //   margin: EdgeInsets.only(left: 16),
          //   icon: SvgPicture.asset(
          //     'assets/icons/Bag.svg',
          //     color: Colors.white,
          //   ),
          // ),
          // CustomIconButtonWidget(
          //   onTap: () {
          //     Navigator.of(context).push(MaterialPageRoute(builder: (context) => MessagePage()));
          //   },
          //   value: widget.chatValue,
          //   margin: EdgeInsets.only(left: 16),
          //   icon: SvgPicture.asset(
          //     'assets/icons/Chat.svg',
          //     color: Colors.white,
          //   ),
          // ),
        ],
      ), systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }
}
