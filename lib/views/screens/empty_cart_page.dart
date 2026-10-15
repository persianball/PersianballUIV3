import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:persian_ball/constant/app_breakpoints.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:persian_ball/views/screens/page_switcher.dart';
import 'package:persian_ball/views/widgets/page_container.dart';

class EmptyCartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool isDesktop = AppBreakpoints.isDesktop(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            Text('Your Cart',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            Text('Empty',
                style: TextStyle(
                    fontSize: 10, color: Colors.black.withOpacity(0.7))),
          ],
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: isDesktop
          // دسکتاپ: کارت پیام وسط صفحه با حداکثر عرض ~۵۶۰ پیکسل
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 56),
                    decoration: ShapeDecoration(
                      color: AppColor.card,
                      shape: AppShapes.border(AppShapes.rXl),
                      shadows: AppColor.cardShadow,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: _buildEmptyContent(context),
                    ),
                  ),
                ),
              ),
            )
          : PageContainer(
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _buildEmptyContent(context),
                ),
              ),
            ),
    );
  }

  /// محتوای مشترک حالت خالی (تصویر، متن‌ها و دکمه) در موبایل و دسکتاپ.
  List<Widget> _buildEmptyContent(BuildContext context) {
    return [
      Container(
        width: 164,
        height: 164,
        margin: EdgeInsets.only(bottom: 32),
        child: SvgPicture.asset('assets/icons/Paper Bag.svg'),
      ),
      Text(
        'Empty Cart  ☹️',
        style: TextStyle(
          color: AppColor.secondary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          fontFamily: 'poppins',
        ),
      ),
      Container(
        margin: EdgeInsets.only(bottom: 48, top: 12),
        child: Text(
          'Go to home and explore our interesting \nproducts and add to cart',
          style: TextStyle(color: AppColor.secondary.withOpacity(0.8)),
          textAlign: TextAlign.center,
        ),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => PageSwitcher()));
        },
        child: Text(
          'Start Shopping',
          style: TextStyle(
              fontWeight: FontWeight.w600, color: AppColor.secondary),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColor.primary,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          backgroundColor: AppColor.border,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: Colors.transparent,
        ),
      ),
    ];
  }
}
