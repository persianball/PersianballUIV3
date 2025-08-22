// views/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/views/screens/page_switcher.dart';
import 'package:marketky/views/screens/register_page.dart';

import '../../bloc/login/login_bloc.dart';


class LoginPage extends StatelessWidget {
  LoginPage({Key? key}) : super(key: key);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('ورود', style: TextStyle(fontFamily: 'Estedad', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: SvgPicture.asset('assets/icons/Arrow-left.svg'),
        ),
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
      body: BlocProvider(
        create: (context) => LoginBloc(),
        child: Builder(builder: (context) {
          return _buildBody(context);
        }),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 24),
      physics: BouncingScrollPhysics(),
      children: [
        // Header
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
            style: TextStyle(
              fontFamily: 'Estedad',
              color: AppColor.secondary.withOpacity(0.7),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),

        // Form
        Form(
          key: _formKey,
          child: Column(
            children: [
              // Email/Phone
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontFamily: 'Estedad'),
                  decoration: InputDecoration(
                    hintText: 'شماره تلفن یا ایمیل',
                    hintStyle: TextStyle(fontFamily: 'Estedad'),
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
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontFamily: 'Estedad'),
                  decoration: InputDecoration(
                    hintText: 'رمز عبور',
                    prefixIcon: Container(
                      padding: EdgeInsets.all(12),
                      child: SvgPicture.asset('assets/icons/Lock.svg', color: AppColor.primary),
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        // toggle visibility
                      },
                      icon: SvgPicture.asset('assets/icons/Hide.svg', color: AppColor.primary),
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'رمز عبور را وارد کنید';
                    }
                    return null;
                  },
                ),
              ),

              // Forgot Password
              Container(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // forgot password page
                  },
                  child: Text(
                    'فراموشی رمز عبور',
                    style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 12,
                      color: AppColor.secondary.withOpacity(0.5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColor.primary.withOpacity(0.1),
                  ),
                ),
              ),

              // Error Message (با BlocConsumer)
              BlocConsumer<LoginBloc, LoginState>(
                listener: (context, state) {
                  if (state is LoginSuccess) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => PageSwitcher()),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is LoginFailure) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Text(
                        state.message,
                        style: TextStyle(
                          color: Colors.red,
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

              // Loading یا دکمه ورود
              BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  if (state is LoginLoading) {
                    return Center(child: CircularProgressIndicator());
                  }
                  return ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        context.read<LoginBloc>().add(
                          LoginSubmitted(
                            username: _emailController.text.trim(),
                            password: _passwordController.text,
                          ),
                        );
                      }
                    },
                    child: Text(
                      'ورود',
                      style: TextStyle(
                        fontFamily: 'Estedad',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                      backgroundColor: AppColor.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
  }
}