import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/urls.dart';
import 'package:marketky/views/widgets/main_app_bar_widget.dart';
import 'package:marketky/views/widgets/menu_tile_widget.dart';

import '../../bloc/login/login_bloc.dart';
import 'login_page.dart';
import 'package:marketky/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:marketky/bloc/otp/verify_otp_bloc.dart';

class UserService {
  static const String endpoint = '/v1/user/';

  static Future<Map<String, dynamic>?> getUserProfile(BuildContext context) async {
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

  static Future<bool> updateUserProfile(BuildContext context, Map<String, dynamic> data) async {
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
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    throw Exception('ذخیره اطلاعات ناموفق بود');
  }
}

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

          // ==== BEGIN: Profile Completion Form ====
          Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: _ProfileCompletionForm(),
            ),
          ),
          // ==== END: Profile Completion Form ====
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

  bool _registeredWithEmail = true; // Will detect from fetched profile
  bool _loading = false;

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
        _birthDateController.text = profile['birth_date'] ?? '';
        _gender = profile['gender'];
        _registeredWithEmail = (profile['email']?.toString().isNotEmpty ?? false);
        final isEmailVerified = profile['is_email_verified'] == true;
        final isMobileVerified = profile['is_mobile_verified'] == true;
        if ((!isEmailVerified && _registeredWithEmail) || (!isMobileVerified && !_registeredWithEmail)) {
          _showOtpVerificationDialog(
            destination: _registeredWithEmail ? profile['email'] : profile['mobile_number'],
            isEmail: _registeredWithEmail,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در دریافت اطلاعات پروفایل'), backgroundColor: Colors.red),
      );
    }
    setState(() => _loading = false);
  }

  void _showOtpVerificationDialog({required String destination, required bool isEmail}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final TextEditingController _otpController = TextEditingController();
        return BlocProvider(
          create: (_) => VerifyOtpBloc(),
          child: AlertDialog(
            title: Text(isEmail ? 'تأیید ایمیل' : 'تأیید شماره موبایل', style: TextStyle(fontFamily: 'Estedad')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('لطفاً کد ارسال شده به ${isEmail ? 'ایمیل' : 'شماره'} زیر را وارد کنید:', style: TextStyle(fontFamily: 'Estedad')), 
                SizedBox(height: 8),
                Text(destination, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                TextFormField(
                  controller: _otpController,
                  maxLength: 5,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "کد تایید ۵ رقمی"),
                ),
                SizedBox(height: 8),
                BlocConsumer<VerifyOtpBloc, VerifyOtpState>(
                  listener: (context, state) async {
                    if (state is VerifyOtpSuccess) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تأیید با موفقیت انجام شد'), backgroundColor: Colors.green),
                      );
                      await Future.delayed(Duration(milliseconds: 300));
                      _fetchProfile(); // Refresh profile after verification
                    } else if (state is VerifyOtpFailure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is VerifyOtpLoading) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_otpController.text.length != 5) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('کد باید ۵ رقمی باشد'), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          BlocProvider.of<VerifyOtpBloc>(context).add(
                            OtpSubmitted(
                              code: _otpController.text,
                              email: isEmail ? destination : null,
                              mobileNumber: !isEmail ? destination : null,
                            ),
                          );
                        },
                        child: Text('تایید'),
                      ),
                    );
                  },
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('انصراف'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 3650)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: Locale('fa'),
    );
    if (picked != null) {
      _birthDateController.text = "${picked.year}/${picked.month}/${picked.day}";
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    Map<String, dynamic> data = {
      "first_name": _firstNameController.text,
      "last_name": _lastNameController.text,
      "email": _registeredWithEmail ? _emailController.text : null,
      "mobile_number": !_registeredWithEmail ? _mobileController.text : null,
      "birth_date": _birthDateController.text.isNotEmpty ? _birthDateController.text : null,
      "gender": _gender,
    };
    data.removeWhere((k, v) => v == null || (v is String && v.isEmpty));
    try {
      await UserService.updateUserProfile(context, data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('اطلاعات با موفقیت ذخیره شد'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ذخیره اطلاعات'), backgroundColor: Colors.red),
      );
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("تکمیل اطلاعات کاربری", style: TextStyle(fontFamily: 'Estedad', fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: InputDecoration(labelText: 'نام'),
                        validator: (val) => val == null || val.isEmpty ? 'نام را وارد کنید' : null,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(labelText: 'نام خانوادگی'),
                        validator: (val) => val == null || val.isEmpty ? 'نام خانوادگی را وارد کنید' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                if (_registeredWithEmail)
                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: 'شماره موبایل'),
                    validator: (val) => val == null || val.isEmpty ? 'شماره موبایل را وارد کنید' : null,
                  )
                else
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: 'ایمیل'),
                    validator: (val) => val == null || val.isEmpty ? 'ایمیل را وارد کنید' : null,
                  ),
                // SizedBox(height: 12),
                // TextFormField(
                //   controller: _birthDateController,
                //   readOnly: true,
                //   decoration: InputDecoration(
                //     labelText: 'تاریخ تولد (اختیاری)',
                //     suffixIcon: Icon(Icons.calendar_today),
                //   ),
                //   onTap: () => _selectBirthDate(context),
                // ),
                // SizedBox(height: 12),
                // DropdownButtonFormField<String>(
                //   value: _gender,
                //   decoration: InputDecoration(labelText: 'جنسیت (اختیاری)'),
                //   items: [
                //     DropdownMenuItem(value: 'male', child: Text('مرد')),
                //     DropdownMenuItem(value: 'female', child: Text('زن')),
                //   ],
                //   onChanged: (val) => setState(() => _gender = val),
                // ),
                SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('ثبت اطلاعات', style: TextStyle(fontFamily: 'Estedad', fontSize: 16,color: Colors.white)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
