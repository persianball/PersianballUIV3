// views/screens/register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/views/screens/otp_verification_page.dart';
import 'package:marketky/views/widgets/page_container.dart';
import '../../bloc/register/register_bloc.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _inviteKeyController = TextEditingController();

  int _selectedTab = 1;

  bool _passwordVisible = false;

  bool _passwordConfirmVisible = false;

  void _switchTab(int index) {
    if (index == _selectedTab) return;
    setState(() {
      _selectedTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
      backgroundColor: AppColor.obsidianBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: AppColor.obsidianBg,
        elevation: 0,
        title: Text('ثبت نام',
            style: TextStyle(
                fontFamily: 'Estedad',
                color: AppColor.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_forward, color: AppColor.onSurface),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: 48,
          alignment: Alignment.center,
          child: TextButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/login');
            },
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'حساب کاربری دارید؟',
                    style: TextStyle(
                      fontFamily: 'Estedad',
                      color: AppColor.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    ' ورود',
                    style: TextStyle(
                      fontFamily: 'Estedad',
                      color: AppColor.goldEnd,
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
        create: (context) => RegisterBloc(),
        child: _buildBody(context),
      ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return PageContainer(
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24),
        physics: BouncingScrollPhysics(),
        children: [
          // Header
          Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              margin: EdgeInsets.only(top: 20, bottom: 12),
              child: Text(
                'به پرشین شاپ خوش آمدید  👋',
                style: TextStyle(
                  fontFamily: 'Estedad',
                  color: AppColor.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              margin: EdgeInsets.only(bottom: 32),
              child: Text(
                'لطفاً برای ثبت نام اطلاعات زیر را وارد نمایید.',
                style: TextStyle(
                  fontFamily: 'Estedad',
                  color: AppColor.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _switchTab(0),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: _selectedTab == 0
                          ? AppColor.goldEnd.withOpacity(0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: _selectedTab == 0
                            ? AppColor.goldEnd
                            : AppColor.outlineVariantDark,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        "ایمیل",
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 14,
                          fontWeight: _selectedTab == 0
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _selectedTab == 0
                              ? AppColor.goldEnd
                              : AppColor.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _switchTab(1),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: _selectedTab == 1
                          ? AppColor.goldEnd.withOpacity(0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: _selectedTab == 1
                            ? AppColor.goldEnd
                            : AppColor.outlineVariantDark,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        "موبایل",
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 14,
                          fontWeight: _selectedTab == 1
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _selectedTab == 1
                              ? AppColor.goldEnd
                              : AppColor.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Form
          Form(
            key: _formKey,
            child: Column(
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextFormField(
                    controller: _usernameController,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface),
                    decoration: InputDecoration(
                      hintText: 'نام کاربری',
                      prefixIcon: Container(
                        padding: EdgeInsets.all(12),
                        child: Text('@',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AppColor.goldEnd)),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColor.outlineVariantDark, width: 1),
                        borderRadius: BorderRadius.zero,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColor.goldEnd, width: 2),
                        borderRadius: BorderRadius.zero,
                      ),
                      fillColor: AppColor.surfaceContainer,
                      filled: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'نام کاربری الزامی است';
                      if (value.length < 3)
                        return 'نام کاربری باید حداقل ۳ کاراکتر باشد';
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 16),

                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(_selectedTab == 0 ? 1 : -1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: _selectedTab == 0
                      ? Directionality(
                          textDirection: TextDirection.ltr,
                          key: ValueKey('email-field'),
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface),
                            decoration: InputDecoration(
                              hintText: 'ایمیل',
                              prefixIcon: Container(
                                padding: EdgeInsets.all(12),
                                child: SvgPicture.asset(
                                    'assets/icons/Message.svg',
                                    color: AppColor.goldEnd),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 14),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColor.outlineVariantDark, width: 1),
                                borderRadius: BorderRadius.zero,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColor.goldEnd, width: 2),
                                borderRadius: BorderRadius.zero,
                              ),
                              fillColor: AppColor.surfaceContainer,
                              filled: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'ایمیل الزامی است';
                              if (!value.contains('@'))
                                return 'ایمیل معتبر نیست';
                              return null;
                            },
                          ),
                        )
                      : Directionality(
                          textDirection: TextDirection.ltr,
                          key: ValueKey('mobile-field'),
                          child: TextFormField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface),
                            decoration: InputDecoration(
                              hintText: 'شماره موبایل',
                              prefixIcon: Container(
                                padding: EdgeInsets.all(12),
                                child: SvgPicture.asset(
                                    'assets/icons/Phone.svg',
                                    color: AppColor.goldEnd),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 14),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColor.outlineVariantDark, width: 1),
                                borderRadius: BorderRadius.zero,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColor.goldEnd, width: 2),
                                borderRadius: BorderRadius.zero,
                              ),
                              fillColor: AppColor.surfaceContainer,
                              filled: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'شماره موبایل الزامی است';
                              if (!value.startsWith('09') || value.length != 11)
                                return 'شماره موبایل نامعتبر است';
                              return null;
                            },
                          ),
                        ),
                ),
                SizedBox(height: 16),

                // Password
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface),
                    decoration: InputDecoration(
                      hintText: 'رمز عبور',
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
                        borderRadius: BorderRadius.zero,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColor.goldEnd, width: 2),
                        borderRadius: BorderRadius.zero,
                      ),
                      fillColor: AppColor.surfaceContainer,
                      filled: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'رمز عبور الزامی است';
                      if (value.length < 6)
                        return 'رمز عبور باید حداقل ۶ کاراکتر باشد';
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 16),

                // Confirm Password
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_passwordConfirmVisible,
                    style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface),
                    decoration: InputDecoration(
                      hintText: 'تکرار رمز عبور',
                      prefixIcon: Container(
                        padding: EdgeInsets.all(12),
                        child: SvgPicture.asset('assets/icons/Lock.svg',
                            color: AppColor.goldEnd),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          // Based on passwordVisible state choose the icon
                          !_passwordConfirmVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppColor.onSurfaceVariant,
                        ),
                        onPressed: () {
                          // Update the state i.e. toogle the state of passwordVisible variable
                          setState(() {
                            _passwordConfirmVisible = !_passwordConfirmVisible;
                          });
                        },
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColor.outlineVariantDark, width: 1),
                        borderRadius: BorderRadius.zero,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColor.goldEnd, width: 2),
                        borderRadius: BorderRadius.zero,
                      ),
                      fillColor: AppColor.surfaceContainer,
                      filled: true,
                    ),
                    validator: (value) {
                      if (value != _passwordController.text)
                        return 'رمزهای عبور یکسان نیستند';
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 16),

                // Invite Key (اختیاری)
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextFormField(
                    controller: _inviteKeyController,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface),
                    decoration: InputDecoration(
                      hintText: 'کد دعوت (اختیاری)',
                      prefixIcon: Container(
                        padding: EdgeInsets.all(12),
                        child: SvgPicture.asset('assets/icons/Star.svg',
                            color: AppColor.goldEnd),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColor.outlineVariantDark, width: 1),
                        borderRadius: BorderRadius.zero,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColor.goldEnd, width: 2),
                        borderRadius: BorderRadius.zero,
                      ),
                      fillColor: AppColor.surfaceContainer,
                      filled: true,
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Error Message
                BlocConsumer<RegisterBloc, RegisterState>(
                  listener: (context, state) {
                    if (state is RegisterSuccess) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => OTPVerificationPage(
                            destination: _selectedTab == 0
                                ? _emailController.text
                                : _mobileController.text,
                            isEmail: _selectedTab == 0,
                            email: _selectedTab == 0
                                ? _emailController.text
                                : null,
                            mobileNumber: _selectedTab == 1
                                ? _mobileController.text
                                : null,
                          ),
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is RegisterFailure) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        child: Text(
                          state.message,
                          style: TextStyle(
                            fontFamily: 'Estedad',
                            color: AppColor.errorDark,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),

                // Submit Button
                BlocBuilder<RegisterBloc, RegisterState>(
                  builder: (context, state) {
                    if (state is RegisterLoading) {
                      return const Center(
                          child: CircularProgressIndicator(color: AppColor.goldEnd));
                    }
                    return ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (_selectedTab == 0) {
                            context.read<RegisterBloc>().add(
                                  RegisterWithEmail(
                                    email: _emailController.text.trim(),
                                    username: _usernameController.text.trim(),
                                    password: _passwordController.text,
                                    confirmPassword:
                                        _confirmPasswordController.text,
                                    inviteKey: _inviteKeyController.text
                                            .trim()
                                            .isNotEmpty
                                        ? _inviteKeyController.text.trim()
                                        : null,
                                  ),
                                );
                          } else {
                            context.read<RegisterBloc>().add(
                                  RegisterWithMobile(
                                    mobileNumber: _mobileController.text.trim(),
                                    username: _usernameController.text.trim(),
                                    password: _passwordController.text,
                                    confirmPassword:
                                        _confirmPasswordController.text,
                                    inviteKey: _inviteKeyController.text
                                            .trim()
                                            .isNotEmpty
                                        ? _inviteKeyController.text.trim()
                                        : null,
                                  ),
                                );
                          }
                        }
                      },
                      child: Text(
                        'ثبت نام',
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          color: AppColor.onGold,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                        backgroundColor: AppColor.goldEnd,
                        shape: const RoundedRectangleBorder(),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                    );
                  },
                ),

                // Social Login (اختیاری)
                // Container(
                //   alignment: Alignment.center,
                //   margin: EdgeInsets.symmetric(vertical: 16),
                //   child: Text(
                //     'یا با این روش‌ها ادامه دهید',
                //     style: TextStyle(
                //       fontFamily: 'Estedad',
                //       fontSize: 12,
                //       color: Colors.grey[600],
                //     ),
                //   ),
                // ),
                // ElevatedButton(
                //   onPressed: () {},
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: [
                //       SvgPicture.asset('assets/icons/Google.svg'),
                //       SizedBox(width: 16),
                //       Text(
                //         'ادامه با گوگل',
                //         style: TextStyle(
                //           fontFamily: 'Estedad',
                //           color: AppColor.secondary,
                //           fontWeight: FontWeight.w600,
                //         ),
                //       )
                //     ],
                //   ),
                //   style: ElevatedButton.styleFrom(
                //     foregroundColor: AppColor.primary,
                //     backgroundColor: AppColor.primarySoft,
                //     padding: EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                //     elevation: 0,
                //     shadowColor: Colors.transparent,
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _inviteKeyController.dispose();
    super.dispose();
  }
}
