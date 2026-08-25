import 'package:flutter/material.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/views/widgets/menu_tile_widget.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/urls.dart';
import 'package:marketky/views/widgets/main_app_bar_widget.dart';

import '../../bloc/login/login_bloc.dart';
import 'login_page.dart';
import 'otp_verification_page.dart';
import 'package:marketky/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserService {
  static const String endpoint = '/v1/user/';

  static Future<Map<String, dynamic>?> getUserProfile(
      BuildContext context) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      await AuthService.requireToken(context);
      throw Exception('نیاز به ورود');
    }
    final response = await http.get(
      Uri.parse('${URLs.baseUrl}$endpoint'),
      headers: {
        'Authorization': 'token $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('خطا در دریافت اطلاعات پروفایل');
  }

  /// پیام خطای سرور را به فارسی برمی‌گرداند.
  ///
  /// بک‌اند خطا را به شکل {"code": "...", "message": "..."} می‌دهد؛ نمایش
  /// پیام واقعی خیلی مفیدتر از «خطا در ذخیره اطلاعات» عمومی است.
  static String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map) {
        switch (body['code']) {
          case 'email_exists':
            return 'این ایمیل قبلاً برای حساب دیگری ثبت شده است';
          case 'mobile_exists':
          case 'mobile_number_exists':
            return 'این شماره موبایل قبلاً برای حساب دیگری ثبت شده است';
        }
        final message = body['message'];
        if (message is String && message.isNotEmpty) return message;
        // خطاهای اعتبارسنجی DRF به شکل {"field": ["..."]} می‌آیند
        final first = body.values.first;
        if (first is List && first.isNotEmpty) return '${first.first}';
        if (first is String && first.isNotEmpty) return first;
      }
    } catch (_) {
      // بدنه‌ی غیر JSON: پیام پیش‌فرض
    }
    return 'ذخیره اطلاعات ناموفق بود (${response.statusCode})';
  }

  static Future<bool> updateUserProfile(
      BuildContext context, Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      await AuthService.requireToken(context);
      throw Exception('نیاز به ورود');
    }
    final response = await http.post(
      Uri.parse('${URLs.baseUrl}$endpoint'),
      headers: {
        'Authorization': 'token $token',
        'Content-Type': 'application/json',
      },
      body: utf8.encode(jsonEncode(data)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    throw Exception(_errorMessage(response));
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  /// null یعنی هنوز بررسی نشده
  bool? _loggedIn;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;
    setState(() => _loggedIn = loggedIn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.obsidianBg,
      appBar: MainAppBar(
        cartValue: 2,
        chatValue: 2,
        dark: true,
      ),
      // تا وقتی وضعیت ورود مشخص نشده چیزی از پروفایل نمایش داده نمی‌شود
      body: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginAuthenticated) {
            setState(() => _loggedIn = true);
          } else if (state is LoginUnauthenticated) {
            setState(() => _loggedIn = false);
          }
        },
        child: _loggedIn == null
            ? const Center(child: CircularProgressIndicator(color: AppColor.goldEnd))
            : (_loggedIn! ? _buildProfile(context) : _buildGuestView(context)),
      ),
    );
  }

  /// حالت مهمان: فقط دعوت به ورود
  Widget _buildGuestView(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.surfaceContainer,
                  border: Border.all(color: AppColor.outlineVariantDark),
                ),
                child: Icon(Icons.person_outline,
                    size: 46, color: AppColor.goldEnd),
              ),
              SizedBox(height: 20),
              Text(
                'وارد حساب کاربری نشده‌اید',
                style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColor.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'برای مشاهده پروفایل، سفارش‌ها و آدرس‌ها ابتدا وارد شوید',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 13,
                  height: 1.7,
                  color: AppColor.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LoginPage(popOnSuccess: true),
                      ),
                    );
                    await _checkAuth();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.goldEnd,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: AppShapes.pill,
                    elevation: 0,
                  ),
                  child: Text(
                    'ورود به حساب کاربری',
                    style: TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 15,
                        color: AppColor.onGold),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                // به صفحه‌ی خانه برمی‌گردد (تب خانه‌ی نوار پایین)، نه یک
                // صفحه‌ی جدید روی پشته
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil('/home', (route) => false),
                child: Text(
                  'فعلاً فقط محصولات را ببینم',
                  style: TextStyle(
                      fontFamily: 'Estedad', fontSize: 13, color: AppColor.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context) {
    return ListView(
          shrinkWrap: true,
          physics: BouncingScrollPhysics(),
          children: [
            // Section 1 - Profile Picture - Username - Name
            Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: ShapeDecoration(
                color: AppColor.card,
                shape: AppShapes.border(AppShapes.rLg),
                shadows: AppColor.cardShadow,
              ),
              child: Column(
                children: [
                  // Profile Picture
                  Container(
                    width: 96,
                    height: 96,
                    decoration: ShapeDecoration(
                      shape: CircleBorder(
                        side: BorderSide(color: AppColor.line),
                      ),
                      shadows: AppColor.cardShadow,
                      image: DecorationImage(
                        image:
                            AssetImage('assets/images/avatar_for_comments.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // بعد از خروج، همین صفحه به حالت مهمان می‌رود
                  // (listener بالای صفحه _loggedIn را false می‌کند)
                  Builder(
                    builder: (context) => ElevatedButton(
                      onPressed: () {
                        context.read<LoginBloc>().add(LogoutRequested());
                      },
                      child: Text(
                        'خروج از حساب',
                        style: TextStyle(
                            fontFamily: 'Estedad',
                            color: Colors.white,
                            fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: AppShapes.pill,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==== فرم تکمیل اطلاعات کاربری ====
            Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: _ProfileCompletionForm(),
              ),
            ),

            // ==== منوی حساب کاربری ====
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
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          color: AppColor.onSurfaceVariant,
                          letterSpacing: 6 / 100,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    MenuTileWidget(
                      onTap: () {
                        Navigator.of(context).pushNamed('/orders');
                      },
                      icon: SvgPicture.asset(
                        'assets/icons/Bag.svg',
                        color: AppColor.goldEnd,
                      ),
                      title: 'سفارشات',
                      subtitle: 'سفارش‌های ثبت‌شده شما',
                    ),
                    MenuTileWidget(
                      onTap: () {
                        Navigator.of(context).pushNamed('/wishlist');
                      },
                      icon: Icon(Icons.favorite_border,
                          color: AppColor.goldEnd),
                      title: 'علاقه‌مندی‌ها',
                      subtitle: 'کالاهای ذخیره‌شده شما',
                    ),
                    MenuTileWidget(
                      onTap: () {
                        Navigator.of(context).pushNamed('/addresses');
                      },
                      icon: SvgPicture.asset(
                        'assets/icons/Location.svg',
                        color: AppColor.goldEnd,
                      ),
                      title: 'آدرس‌ها',
                      subtitle: 'آدرس‌های ثبت‌شده شما',
                    ),
                    MenuTileWidget(
                      onTap: () {
                        Navigator.of(context).pushNamed('/account-security');
                      },
                      icon: Icon(Icons.lock_outline,
                          color: AppColor.goldEnd),
                      title: 'امنیت حساب',
                      subtitle: 'تغییر رمز عبور و حذف حساب',
                    ),

                    // ==== پشتیبانی و قوانین ====
                    Container(
                      margin: EdgeInsets.only(right: 16, top: 16),
                      child: Text(
                        'پشتیبانی و قوانین',
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          color: AppColor.onSurfaceVariant,
                          letterSpacing: 6 / 100,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    MenuTileWidget(
                      onTap: () => Navigator.of(context).pushNamed('/support'),
                      icon: Icon(Icons.headset_mic_outlined,
                          color: AppColor.goldEnd),
                      title: 'تماس با پشتیبانی',
                      subtitle: 'تلفن، ایمیل و پیام‌رسان',
                    ),
                    MenuTileWidget(
                      onTap: () => Navigator.of(context).pushNamed('/terms'),
                      icon: Icon(Icons.description_outlined,
                          color: AppColor.goldEnd),
                      title: 'قوانین و مقررات',
                      subtitle: 'شرایط خرید و مرجوعی',
                    ),
                    MenuTileWidget(
                      onTap: () => Navigator.of(context).pushNamed('/privacy'),
                      icon: Icon(Icons.privacy_tip_outlined,
                          color: AppColor.goldEnd),
                      title: 'حریم خصوصی',
                      subtitle: 'نحوه استفاده از اطلاعات شما',
                    ),
                    MenuTileWidget(
                      onTap: () => Navigator.of(context).pushNamed('/about'),
                      icon: Icon(Icons.info_outline,
                          color: AppColor.goldEnd),
                      title: 'درباره ما',
                      subtitle: 'معرفی فروشگاه',
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
  }
}

// ==== PROFILE COMPLETION FORM WIDGET ====
class _ProfileCompletionForm extends StatefulWidget {
  @override
  State<_ProfileCompletionForm> createState() => _ProfileCompletionFormState();
}

class _ProfileCompletionFormState extends State<_ProfileCompletionForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _birthDateController = TextEditingController();
  String? _gender;

  bool _loading = false;
  bool _isEmailVerified = false;
  bool _isMobileVerified = false;

  /// مقادیری که سرور برگردانده است.
  ///
  /// مهم: اندپوینت POST /v1/user اگر همان ایمیل فعلی کاربر را دوباره
  /// دریافت کند، با خطای «email_exists» رد می‌کند (یکتایی را نسبت به خود
  /// کاربر هم چک می‌کند). پس ایمیل/موبایل فقط وقتی فرستاده می‌شوند که
  /// واقعاً عوض شده باشند.
  String _serverEmail = '';
  String _serverMobile = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await UserService.getUserProfile(context);
      if (profile != null) {
        _firstNameController.text = profile['first_name'] ?? '';
        _lastNameController.text = profile['last_name'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _mobileController.text = profile['mobile_number'] ?? '';
        _serverEmail = _emailController.text;
        _serverMobile = _mobileController.text;
        _birthDateController.text = profile['birth_date'] ?? '';
        _gender = profile['gender'];
        _isEmailVerified = profile['is_email_verified'] == true;
        _isMobileVerified = profile['is_mobile_verified'] == true;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('خطا در دریافت اطلاعات پروفایل'),
            backgroundColor: Colors.red),
      );
    }
    setState(() => _loading = false);
  }

  void _navigateToOtpVerification(
      {required String destination, required bool isEmail}) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => OTPVerificationPage(
          destination: destination,
          isEmail: isEmail,
          email: isEmail ? destination : null,
          mobileNumber: !isEmail ? destination : null,
        ),
      ),
    )
        .then((_) {
      // Refresh profile after returning from OTP verification
      _fetchProfile();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();
    final emailChanged = email != _serverEmail;
    final mobileChanged = mobile != _serverMobile;

    final Map<String, dynamic> data = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      // فقط در صورت تغییر ارسال می‌شوند، وگرنه سرور خطای «تکراری» می‌دهد
      if (emailChanged) 'email': email,
      if (mobileChanged) 'mobile_number': mobile,
      if (_birthDateController.text.trim().isNotEmpty)
        'birth_date': _birthDateController.text.trim(),
      if (_gender != null) 'gender': _gender,
    };
    data.removeWhere((k, v) => v == null || (v is String && v.isEmpty));

    try {
      await UserService.updateUserProfile(context, data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اطلاعات با موفقیت ذخیره شد',
              style: TextStyle(fontFamily: 'Estedad')),
          backgroundColor: AppColor.success,
        ),
      );
      await _fetchProfile();
      if (!mounted) return;
      // ایمیل/موبایل تازه باید تأیید شوند؛ کاربر مستقیم به صفحه‌ی کد می‌رود
      if (emailChanged && email.isNotEmpty && !_isEmailVerified) {
        _navigateToOtpVerification(destination: email, isEmail: true);
      } else if (mobileChanged && mobile.isNotEmpty && !_isMobileVerified) {
        _navigateToOtpVerification(destination: mobile, isEmail: false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: const TextStyle(fontFamily: 'Estedad'),
          ),
          backgroundColor: AppColor.danger,
        ),
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  InputDecoration _dec(String label, {Widget? suffixIcon}) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Estedad', color: AppColor.onSurfaceVariant),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColor.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: AppShapes.radius(AppShapes.rMd),
          borderSide: BorderSide(color: AppColor.outlineVariantDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShapes.radius(AppShapes.rMd),
          borderSide: BorderSide(color: AppColor.outlineVariantDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShapes.radius(AppShapes.rMd),
          borderSide: BorderSide(color: AppColor.goldEnd, width: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return _loading
        ? Center(child: CircularProgressIndicator(color: AppColor.goldEnd))
        : Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("تکمیل اطلاعات کاربری",
                    style: TextStyle(
                        fontFamily: 'Estedad',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColor.onSurface)),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        style: const TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface),
                        decoration: _dec('نام'),
                        validator: (val) => val == null || val.isEmpty
                            ? 'نام را وارد کنید'
                            : null,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        style: const TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface),
                        decoration: _dec('نام خانوادگی'),
                        validator: (val) => val == null || val.isEmpty
                            ? 'نام خانوادگی را وارد کنید'
                            : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Email Field with Verification Status
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface),
                  decoration: _dec(
                    'ایمیل',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isEmailVerified ? Icons.check_circle : Icons.cancel,
                          color: _isEmailVerified ? AppColor.successDark : Colors.red,
                          size: 20,
                        ),
                        if (!_isEmailVerified &&
                            _emailController.text.isNotEmpty)
                          TextButton(
                            onPressed: () => _navigateToOtpVerification(
                              destination: _emailController.text,
                              isEmail: true,
                            ),
                            child: Text('تأیید',
                                style: TextStyle(fontFamily: 'Estedad', fontSize: 12, color: AppColor.goldEnd)),
                          ),
                      ],
                    ),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'ایمیل را وارد کنید' : null,
                ),
                SizedBox(height: 12),
                // Phone Field with Verification Status
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface),
                  decoration: _dec(
                    'شماره موبایل',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isMobileVerified ? Icons.check_circle : Icons.cancel,
                          color: _isMobileVerified ? AppColor.successDark : Colors.red,
                          size: 20,
                        ),
                        if (!_isMobileVerified &&
                            _mobileController.text.isNotEmpty)
                          TextButton(
                            onPressed: () => _navigateToOtpVerification(
                              destination: _mobileController.text,
                              isEmail: false,
                            ),
                            child: Text('تأیید',
                                style: TextStyle(fontFamily: 'Estedad', fontSize: 12, color: AppColor.goldEnd)),
                          ),
                      ],
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty
                      ? 'شماره موبایل را وارد کنید'
                      : null,
                ),
                SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('ثبت اطلاعات',
                          style: TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 16,
                              color: AppColor.onGold)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.goldEnd,
                      shape: AppShapes.pill,
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
