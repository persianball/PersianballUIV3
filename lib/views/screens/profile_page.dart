import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/views/widgets/main_app_bar_widget.dart';
import 'package:marketky/views/widgets/menu_tile_widget.dart';

import '../../bloc/login/login_bloc.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        cartValue: 2,
        chatValue: 2,
      ),
      body: ListView(
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        children: [
          // Section 1 - Profile Picture - Username - Name
          Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              children: [
                // Profile Picture
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: Colors.grey,
                    image: DecorationImage(
                      image: AssetImage('assets/images/avatar_for_comments.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Fullname
                // Container(
                //   margin: EdgeInsets.only(bottom: 4, top: 14),
                //   child: Text(
                //     'Nadsya Utari',
                //     style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                //   ),
                // ),
                // // Username
                // Text(
                //   'Username',
                //   style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                // ),
                BlocListener<LoginBloc, LoginState>(
                  listener: (context, state) {
                    if (state is LoginUnauthenticated) {
                      // هدایت به صفحه مناسب
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    }
                  },
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<LoginBloc>().add(LogoutRequested());
                    },
                    child: Text('خروج از حساب',
                      style: TextStyle(fontFamily: 'Estedad', color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )

              ],
            ),
          ),
          // Section 2 - Account Menu
          Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              width: MediaQuery.of(context).size.width,
              margin: EdgeInsets.only(top: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(right: 16),
                    child: Text(
                      'حساب کاربری',
                      style: TextStyle(color: AppColor.secondary.withOpacity(0.5), letterSpacing: 6 / 100, fontWeight: FontWeight.w600),
                    ),
                  ),


                  MenuTileWidget(
                    onTap: () {
                      Navigator.of(context).pushNamed('/orders');
                    },
                    icon: SvgPicture.asset(
                      'assets/icons/Bag.svg',
                      color: AppColor.secondary.withOpacity(0.5),
                    ),
                    title: 'سفارشات',
                    subtitle: 'سفارش‌های ثبت‌شده شما',
                  ),

                  MenuTileWidget(
                    onTap: () {
                      Navigator.of(context).pushNamed('/addresses');
                    },
                    icon: SvgPicture.asset(
                      'assets/icons/Location.svg',
                      color: AppColor.secondary.withOpacity(0.5),
                    ),
                    title: 'آدرس‌ها',
                    subtitle: 'آدرس‌های ثبت‌شده شما',
                  ),
                ],
              ),
            ),
          ),

          // // Section 3 - Settings
          // Container(
          //   width: MediaQuery.of(context).size.width,
          //   margin: EdgeInsets.only(top: 24),
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.start,
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Container(
          //         margin: EdgeInsets.only(left: 16),
          //         child: Text(
          //           'SETTINGS',
          //           style: TextStyle(color: AppColor.secondary.withOpacity(0.5), letterSpacing: 6 / 100, fontWeight: FontWeight.w600),
          //         ),
          //       ),
          //       MenuTileWidget(
          //         onTap: () {},
          //         margin: EdgeInsets.only(top: 10),
          //         icon: SvgPicture.asset(
          //           'assets/icons/Filter.svg',
          //           color: AppColor.secondary.withOpacity(0.5),
          //         ),
          //         title: 'Languages',
          //         subtitle: 'Lorem ipsum Dolor sit Amet',
          //       ),
          //       MenuTileWidget(
          //         onTap: () {},
          //         icon: SvgPicture.asset(
          //           'assets/icons/Log Out.svg',
          //           color: Colors.red,
          //         ),
          //         iconBackground: Colors.red[100]!,
          //         title: 'Log Out',
          //         titleColor: Colors.red,
          //       ),
          //     ],
          //   ),
          // )
        ],
      ),
    );
  }
}
