import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/views/screens/page_switcher.dart';
import 'package:marketky/views/screens/register_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('ورود', style: TextStyle(fontFamily: 'Estedad',color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: SvgPicture.asset('assets/icons/Arrow-left.svg'),
        ), systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      bottomNavigationBar: Container(
        width: MediaQuery.of(context).size.width,
        height: 48,
        alignment: Alignment.center,
        child: TextButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => RegisterPage()));
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColor.secondary.withOpacity(0.1),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'اکانت ندارم🥲!',
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    color: AppColor.secondary.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'ثبت نام',
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    color: AppColor.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(horizontal: 24),
        physics: BouncingScrollPhysics(),
        children: [
          // Section 1 - Header
          Container(
            margin: EdgeInsets.only(top: 20, bottom: 12),
            child: Text(
              'خوش آمدید',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColor.secondary,
                fontWeight: FontWeight.w700,
                fontFamily: 'Estedad',
                fontSize: 20,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 32),
            child: Text(
              ' به کمک شماره تلفن یا ایمیل خود وارد شوید.',
              textAlign: TextAlign.right,
              style: TextStyle(fontFamily: 'Estedad',color: AppColor.secondary.withOpacity(0.7), fontSize: 12, height: 150 / 100),
            ),
          ),
          // Section 2 - Form
          // Email
          Directionality(
            textDirection: TextDirection.rtl,
            child: TextField(
              autofocus: false,
              style: TextStyle(
                fontFamily: 'Estedad',
              ),
              decoration: InputDecoration(
                hintText: 'شماره تلفن یا ایمیل',
                hintStyle: TextStyle(
                  fontFamily: 'Estedad',
                ),
                prefixIcon: Container(
                  padding: EdgeInsets.all(12),
                  child: SvgPicture.asset('assets/icons/Message.svg', color: AppColor.primary),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColor.border, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColor.primary, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                fillColor: AppColor.primarySoft,
                filled: true,
              ),
            ),
          ),
          SizedBox(height: 16),
          // Password
          Directionality(
            textDirection: TextDirection.rtl,
            child: TextField(
              autofocus: false,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '**********',

                prefixIcon: Container(
                  padding: EdgeInsets.all(12),
                  child: SvgPicture.asset('assets/icons/Lock.svg', color: AppColor.primary),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColor.border, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColor.primary, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                fillColor: AppColor.primarySoft,
                filled: true,
                //
                suffixIcon: IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset('assets/icons/Hide.svg', color: AppColor.primary),
                ),
              ),
            ),
          ),
          // Forgot Passowrd
          Container(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'فراموشی رمز عبور',
                style: TextStyle(fontFamily: 'Estedad',fontSize: 12, color: AppColor.secondary.withOpacity(0.5), fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColor.primary.withOpacity(0.1),
              ),
            ),
          ),
          // Sign In button
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => PageSwitcher()));
            },
            child: Text(
              'ورود',
              style: TextStyle(fontFamily: 'Estedad',color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 36, vertical: 18), backgroundColor: AppColor.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
