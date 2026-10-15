// views/login_page.dart
import 'package:flutter/material.dart';
import 'package:persian_ball/constant/app_breakpoints.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:persian_ball/views/widgets/app_buttons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/views/screens/page_switcher.dart';
import 'package:persian_ball/views/screens/register_page.dart';
import 'package:persian_ball/views/widgets/page_container.dart';

import '../../bloc/login/login_bloc.dart';
import 'package:persian_ball/views/widgets/motion.dart';
import 'package:persian_ball/views/widgets/auth_background.dart';

class LoginPage extends StatefulWidget {
  final bool popOnSuccess; // if true, pop with result after successful login
  LoginPage({Key? key, this.popOnSuccess = false}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  var _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AuthBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('ورود',
            style: TextStyle(
                fontFamily: 'Estedad',
                color: AppColor.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
            //navigate to home page
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => PageSwitcher()),
                ModalRoute.withName("/"));
          },
          icon: Icon(Icons.arrow_back, color: AppColor.onSurface),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColor.card,
            border: Border(top: BorderSide(color: AppColor.line, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'حساب کاربری ندارید؟',
                style: TextStyle(
                  fontFamily: 'Estedad',
                  color: AppColor.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => RegisterPage()));
                },
                style: TextButton.styleFrom(
                  minimumSize: Size(88, 44),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  foregroundColor: AppColor.pitchGreen,
                  backgroundColor: AppColor.pitchGreenSoft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppColor.pitchGreen, width: 1),
                  ),
                ),
                child: Text(
                  'ثبت نام',
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    color: AppColor.pitchGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Builder(builder: (context) {
        return _buildBody(context);
      }),
      ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    // دسکتاپ: فرم به شکل کارت برجسته‌ی وسط‌چین
    if (AppBreakpoints.isDesktop(context)) {
      return _buildDesktopCard(context);
    }
    return PageContainer(
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24),
        physics: BouncingScrollPhysics(),
        children: _formChildren(context),
      ),
    );
  }

  /// کارت فرم در دسکتاپ: عرض حداکثر ۴۸۰، فاصله‌ی بالای حدود ۹٪ ارتفاع نما
  Widget _buildDesktopCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final topSpace = constraints.maxHeight * 0.09;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, topSpace, 24, 48),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: ShapeDecoration(
                  color: AppColor.card,
                  shape: AppShapes.border(AppShapes.rXl),
                  shadows: AppColor.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: _formChildren(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _formChildren(BuildContext context) {
    return [
          // Header
          FadeSlideIn(
          child: Container(
            margin: EdgeInsets.only(top: 20, bottom: 12),
            child: Text(
              'خوش آمدید',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColor.onSurface,
                fontWeight: FontWeight.w700,
                fontFamily: 'Estedad',
                fontSize: 20,
              ),
            ),
          ),
          ),
          FadeSlideIn(
          delay: const Duration(milliseconds: 90),
          child: Container(
            margin: EdgeInsets.only(bottom: 32),
            child: Text(
              ' به کمک نام کاربری خود وارد شوید.',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Estedad',
                color: AppColor.onSurfaceVariant,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          ),

          // Form
          FadeSlideIn(
          delay: const Duration(milliseconds: 160),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Email/Phone
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface),
                    decoration: InputDecoration(
                      hintText: 'نام کاربری',
                      hintStyle: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurfaceVariant),
                      prefixIcon: Container(
                        padding: EdgeInsets.all(12),
                        child: SvgPicture.asset('assets/icons/Message.svg',
                            color: AppColor.goldEnd),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColor.outlineVariantDark, width: 1),
                        borderRadius: AppShapes.radius(AppShapes.rMd),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColor.goldEnd, width: 2),
                        borderRadius: AppShapes.radius(AppShapes.rMd),
                      ),
                      fillColor: AppColor.surfaceContainer,
                      filled: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'ایمیل یا شماره تلفن را وارد کنید';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 16),

                // Password
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface),
                    decoration: InputDecoration(
                      hintText: 'رمز عبور',
                      hintStyle: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurfaceVariant),
                      prefixIcon: Container(
                        padding: EdgeInsets.all(12),
                        child: SvgPicture.asset('assets/icons/Lock.svg',
                            color: AppColor.goldEnd),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          // Based on passwordVisible state choose the icon
                          !_passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppColor.onSurfaceVariant,
                        ),
                        onPressed: () {
                          // Update the state i.e. toogle the state of passwordVisible variable
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColor.outlineVariantDark, width: 1),
                        borderRadius: AppShapes.radius(AppShapes.rMd),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColor.goldEnd, width: 2),
                        borderRadius: AppShapes.radius(AppShapes.rMd),
                      ),
                      fillColor: AppColor.surfaceContainer,
                      filled: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'رمز عبور را وارد کنید';
                      }
                      return null;
                    },
                  ),
                ),

                // فراموشی رمز عبور
                Container(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/forgot-password');
                    },
                    child: Text(
                      'فراموشی رمز عبور',
                      style: TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 12,
                        color: AppColor.goldEnd,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // Error Message (با BlocConsumer)
                BlocConsumer<LoginBloc, LoginState>(
                  listener: (context, state) {
                    if (state is LoginAuthenticated) {
                      // هر جا که کاربر از آن به صفحه‌ی ورود آمده، بعد از
                      // موفقیت باید همان‌جا برگردد (نه همیشه صفحه‌ی خانه)؛
                      // popOnSuccess فقط برای انتقال نتیجه (true) لازم است.
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop(true); // signal success
                      } else {
                        Navigator.of(context).pushReplacementNamed('/home');
                      }
                    }
                  },
                  builder: (context, state) {
                    if (state is LoginUnauthenticated) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        child: Text(
                          state.message ?? "",
                          style: TextStyle(
                            color: AppColor.errorDark,
                            fontFamily: 'Estedad',
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
                SizedBox(height: 16),
                // Loading یا دکمه ورود
                BlocBuilder<LoginBloc, LoginState>(
                  builder: (context, state) {
                    if (state is LoginLoading) {
                      return const Center(
                          child: CircularProgressIndicator(color: AppColor.pitchGreen));
                    }
                    return GradientButton(
                      label: 'ورود',
                      icon: const Icon(Icons.login_rounded),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<LoginBloc>().add(
                                LoginRequested(
                                  _emailController.text.trim(),
                                  _passwordController.text,
                                ),
                              );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          ),
    ];
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
