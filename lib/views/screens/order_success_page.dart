import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:persian_ball/constant/app_breakpoints.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:persian_ball/views/screens/page_switcher.dart';
import 'package:persian_ball/views/widgets/page_container.dart';

class OrderSuccessPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool isDesktop = AppBreakpoints.isDesktop(context);
    return Scaffold(
      // در دسکتاپ دکمه‌ها داخل کارت مرکزی قرار می‌گیرند.
      bottomNavigationBar: isDesktop
          ? null
          : SafeArea(
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 184,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                color: Colors.white,
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      width: MediaQuery.of(context).size.width,
                      child: _buildOrdersButton(),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: _buildContinueButton(context),
                    ),
                  ],
                ),
              ),
            ),
      extendBody: true,
      body: isDesktop
          // دسکتاپ: کارت پیام موفقیت وسط صفحه با حداکثر عرض ~۵۶۰ پیکسل
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ..._buildSuccessContent(),
                        const SizedBox(height: 40),
                        _buildContinueButton(context),
                        const SizedBox(height: 12),
                        _buildOrdersButton(),
                      ],
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
                  children: _buildSuccessContent(),
                ),
              ),
            ),
    );
  }

  /// محتوای مشترک پیام موفقیت (تصویر و متن‌ها) در موبایل و دسکتاپ.
  List<Widget> _buildSuccessContent() {
    return [
      Center(
        child: Container(
          width: 124,
          height: 124,
          margin: EdgeInsets.only(bottom: 32),
          child: SvgPicture.asset('assets/icons/Success.svg'),
        ),
      ),
      Text(
        'Order Success! 😆',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColor.secondary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          fontFamily: 'poppins',
        ),
      ),
      Container(
        margin: EdgeInsets.only(top: 8),
        child: Text(
          'We have received your order',
          style: TextStyle(color: AppColor.secondary.withOpacity(0.8)),
          textAlign: TextAlign.center,
        ),
      ),
    ];
  }

  Widget _buildOrdersButton() {
    return ElevatedButton(
      onPressed: () {},
      child: Text(
        'Your Orders',
        style:
            TextStyle(color: AppColor.secondary, fontWeight: FontWeight.w500),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColor.primary,
        padding: EdgeInsets.symmetric(vertical: 18),
        backgroundColor: AppColor.border,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => PageSwitcher()));
      },
      child: Text(
        'Continue Shopping',
        style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            fontFamily: 'poppins'),
      ),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 18),
        backgroundColor: AppColor.primary,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    );
  }
}
