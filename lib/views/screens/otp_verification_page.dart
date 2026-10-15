// views/screens/otp_verification_page.dart
import 'package:flutter/material.dart';
import 'package:persian_ball/constant/app_breakpoints.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/views/screens/page_switcher.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:persian_ball/views/widgets/page_container.dart';

import '../../bloc/otp/verify_otp_bloc.dart';
import 'package:persian_ball/views/widgets/auth_background.dart';

class OTPVerificationPage extends StatefulWidget {
  final String destination;
  final bool isEmail;
  final String? email;
  final String? mobileNumber;

  const OTPVerificationPage({
    Key? key,
    required this.destination,
    required this.isEmail,
    this.email,
    this.mobileNumber,
  }) : super(key: key);
  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  late String _maskedDestination;
  final TextEditingController _otpController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _maskedDestination = widget.isEmail
        ? _maskEmail(widget.destination)
        : _maskMobile(widget.destination);
  }

  String _maskEmail(String email) {
    final split = email.split('@');
    if (split.length != 2) return email;
    final local = split[0];
    final domain = split[1];
    final visible = local.length > 2 ? '${local.substring(0, 2)}***' : local;
    return '$visible@$domain';
  }

  String _maskMobile(String mobile) {
    if (mobile.length < 4) return mobile;
    return '${mobile.substring(0, 4)}****${mobile.substring(mobile.length - 2)}';
  }

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
        title: Text('اعتبارسنجی',
            style: TextStyle(
                fontFamily: 'Estedad',
                color: AppColor.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back, color: AppColor.onSurface),
        ),
      ),
      body: BlocProvider(
        create: (context) => VerifyOtpBloc(),
        child: _buildBody(context),
      ),
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
          Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              margin: EdgeInsets.only(top: 20, bottom: 8),
              child: Text(
                'کد تایید',
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
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 14,
                        color: AppColor.onSurfaceVariant),
                    children: [
                      TextSpan(text: 'کد یکبار مصرف به '),
                      TextSpan(
                        text: _maskedDestination,
                        style: TextStyle(
                          color: AppColor.goldEnd,
                          fontWeight: FontWeight.w700,
                          fontFamily: "Estedad",
                        ),
                      ),
                      TextSpan(text: ' ارسال شده است.'),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // OTP Field
          BlocBuilder<VerifyOtpBloc, VerifyOtpState>(
            builder: (context, state) {
              return PinCodeTextField(
                appContext: context,
                length: 5,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: AppShapes.radius(AppShapes.rMd),
                  fieldHeight: 70,
                  fieldWidth: 60,
                  borderWidth: 1.5,
                  activeColor: AppColor.goldEnd,
                  inactiveColor: AppColor.outlineVariantDark,
                  selectedColor: AppColor.goldEnd,
                  inactiveFillColor: AppColor.surfaceContainer,
                  activeFillColor: AppColor.surfaceContainer,
                  selectedFillColor: AppColor.surfaceContainer,
                ),
                cursorColor: AppColor.goldEnd,
                animationDuration: Duration(milliseconds: 300),
                enableActiveFill: true,
                onChanged: (value) {
                  // optional
                },
                onCompleted: (code) {
                  context.read<VerifyOtpBloc>().add(
                        OtpSubmitted(
                          code: code,
                          email: widget.email,
                          mobileNumber: widget.mobileNumber,
                        ),
                      );
                },
              );
            },
          ),

          // Error Message
          BlocConsumer<VerifyOtpBloc, VerifyOtpState>(
            listener: (context, state) {
              if (state is VerifyOtpSuccess) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => PageSwitcher()),
                );
              }
            },
            builder: (context, state) {
              if (state is VerifyOtpFailure) {
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 12),
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

          // Verify Button
          BlocBuilder<VerifyOtpBloc, VerifyOtpState>(
            builder: (context, state) {
              if (state is VerifyOtpLoading) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColor.goldEnd));
              }

              return ElevatedButton(
                onPressed: () {
                  final code = _otpController.text.trim();

                  // اگر کد 5 رقم نباشد، اخطار بده
                  if (code.length != 5) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "لطفاً 5 رقم کد را وارد کنید",
                          style: TextStyle(fontFamily: 'Estedad'),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // اگر در حال لودینگ باشد، دکمه غیرفعال است (اختیاری)
                  if (context.read<VerifyOtpBloc>().state is VerifyOtpLoading) {
                    return;
                  }

                  // ارسال رویداد به BLoC با کد و اطلاعات تماس
                  context.read<VerifyOtpBloc>().add(
                        OtpSubmitted(
                          code: code,
                          email: widget
                              .email, // از صفحه قبلی آمده (ممکن است null باشد)
                          mobileNumber: widget
                              .mobileNumber, // اگر موبایل بوده، این پر است
                        ),
                      );
                },
                child: Text(
                  'تایید',
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    color: AppColor.onGold,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  backgroundColor: AppColor.goldEnd,
                  shape: AppShapes.pill,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
              );
            },
          ),

          SizedBox(height: 16),

          // Resend Code
          // ElevatedButton(
          //   onPressed: _onResendCode,
          //   child: Text(
          //     'ارسال دوباره‌ی کد',
          //     style: TextStyle(
          //       fontFamily: 'Estedad',
          //       color: AppColor.secondary,
          //       fontWeight: FontWeight.w600,
          //     ),
          //   ),
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: AppColor.primarySoft,
          //     foregroundColor: AppColor.primary,
          //     padding: EdgeInsets.symmetric(horizontal: 36, vertical: 18),
          //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          //     elevation: 0,
          //     shadowColor: Colors.transparent,
          //   ),
          // ),
    ];
  }
}
