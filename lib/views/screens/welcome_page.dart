import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/views/screens/login_page.dart';

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Section 1 - Illustration
            Container(
              margin: EdgeInsets.only(top: 32),
              width: MediaQuery.of(context).size.width,
              child: SvgPicture.asset('assets/icons/welcome_page.svg'),
            ),
            // Section 2 - Marketky with Caption
            Column(
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Persian Shop',
                    style: TextStyle(
                      color: AppColor.secondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                      fontFamily: 'poppins',
                    ),
                  ),
                ),
                Text(
                  'فوتبال در جیب شما ،رو به سوی پیشرفت',
                  style: TextStyle(fontFamily: 'Estedad',color: AppColor.secondary.withOpacity(0.7), fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            // Section 3 - Get Started Button
            Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.symmetric(horizontal: 16),
              margin: EdgeInsets.only(bottom: 16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => LoginPage()));
                },
                child: Text(
                  'شروع',
                  style: TextStyle(fontFamily: 'Estedad',color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 36, vertical: 18), backgroundColor: AppColor.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
