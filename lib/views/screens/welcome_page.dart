import 'package:flutter/material.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/bloc/login/login_bloc.dart';
import 'package:marketky/constant/app_breakpoints.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/views/widgets/page_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketky/views/widgets/motion.dart';

class WelcomePage extends StatefulWidget {
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();

    context.read<LoginBloc>().add(CheckAuthStatus());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.obsidianBg,
      body: SafeArea(
        child: BlocConsumer<LoginBloc, LoginState>(listener: (context, state) {
          if (state is LoginAuthenticated) {
            SharedPreferences.getInstance().then((p) async {
              await p.setBool('has_seen_welcome', true);
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/home');
              }
            });
          }
        }, builder: (context, state) {
          if (state is LoginUnauthenticated) {
            return LayoutBuilder(
              builder: (context, constraints) {
                // دسکتاپ: چیدمان دونیمه‌ی تمام‌قد
                if (AppBreakpoints.isDesktop(context)) {
                  return _buildDesktop(context, constraints);
                }
                // موبایل/تبلت: همان چیدمان ستونی قبلی
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: PageContainer(
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Section 1 - Illustration
                            _buildIllustration(margin: EdgeInsets.only(top: 32)),
                            // Section 2 - Marketky with Caption
                            _buildTitleBlock(),
                            // Section 3 - Get Started Button
                            Container(
                              width: double.infinity,
                              constraints: BoxConstraints(maxWidth: 480),
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              margin: EdgeInsets.only(top: 24, bottom: 16),
                              child: _buildCta(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return Container();
          }
        }),
      ),
    );
  }

  /// تصویرسازی صفحه‌ی خوش‌آمد (به همراه انیمیشن ورود)
  Widget _buildIllustration({
    EdgeInsets margin = EdgeInsets.zero,
    double maxWidth = 480,
  }) {
    return FadeSlideIn(
      duration: const Duration(milliseconds: 550),
      child: Container(
        margin: margin,
        width: double.infinity,
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SvgPicture.asset('assets/icons/welcome_page.svg'),
      ),
    );
  }

  /// عنوان و شعار برند (به همراه انیمیشن ورود)
  Widget _buildTitleBlock({
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextAlign textAlign = TextAlign.center,
  }) {
    return FadeSlideIn(
      delay: const Duration(milliseconds: 150),
      duration: const Duration(milliseconds: 550),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 12),
            child: Text(
              'پرشین شاپ',
              textAlign: textAlign,
              style: TextStyle(
                color: AppColor.goldEnd,
                fontWeight: FontWeight.w700,
                fontSize: 32,
                fontFamily: 'Estedad',
              ),
            ),
          ),
          Text(
            'رو به سوی پیشرفت',
            style: TextStyle(
                fontFamily: 'Estedad',
                color: AppColor.onSurfaceVariant,
                fontSize: 16),
            textAlign: textAlign,
          ),
        ],
      ),
    );
  }

  /// دکمه‌ی «شروع» — منطق ناوبری بدون تغییر
  Widget _buildCta(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_seen_welcome', true);
        if (!mounted) return;
        // Go to home (PageSwitcher). Login can be triggered when needed elsewhere.
        Navigator.of(context).pushReplacementNamed('/home');
      },
      child: Text(
        'شروع',
        style: TextStyle(
            fontFamily: 'Estedad',
            color: AppColor.onGold,
            fontWeight: FontWeight.w600,
            fontSize: 18),
      ),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 36, vertical: 18),
        backgroundColor: AppColor.goldEnd,
        shape: AppShapes.pill,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    );
  }

  /// چیدمان دسکتاپ: نیمی تصویرسازی و نیمی متن + دکمه، هر دو عمودی وسط‌چین
  Widget _buildDesktop(BuildContext context, BoxConstraints constraints) {
    final gutter = AppBreakpoints.gutter(context);
    return SizedBox(
      height: constraints.maxHeight,
      width: double.infinity,
      child: Row(
        children: [
          // نیمه‌ی تصویرسازی
          Expanded(
            child: Container(
              height: double.infinity,
              color: AppColor.cardMuted,
              padding: EdgeInsets.symmetric(horizontal: gutter * 2, vertical: 40),
              alignment: Alignment.center,
              child: _buildIllustration(maxWidth: 520),
            ),
          ),
          // نیمه‌ی متن و فراخوان اقدام
          Expanded(
            child: Container(
              height: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: gutter * 2, vertical: 40),
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleBlock(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 40),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: SizedBox(
                        width: double.infinity,
                        child: _buildCta(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
