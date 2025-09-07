// views/screens/otp_verification_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/views/screens/page_switcher.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../bloc/otp/verify_otp_bloc.dart';


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

  void _onResendCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('کد تأیید دوباره به ${_maskedDestination} ارسال شد', style: TextStyle(fontFamily: 'Estedad')),
        backgroundColor: AppColor.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('اعتبارسنجی', style: TextStyle(fontFamily: 'Estedad', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: SvgPicture.asset('assets/icons/Arrow-left.svg'),
        ),
      ),
      body: BlocProvider(
        create: (context) => VerifyOtpBloc(),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 24),
      physics: BouncingScrollPhysics(),
      children: [
        // Header
        Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            margin: EdgeInsets.only(top: 20, bottom: 8),
            child: Text(
              'کد تایید',
              style: TextStyle(
                fontFamily: 'Estedad',
                color: AppColor.secondary,
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
                  style: TextStyle(fontFamily: 'Estedad', fontSize: 14, color: AppColor.secondary.withOpacity(0.7)),
                  children: [
                    TextSpan(text: 'کد یکبار مصرف به '),
                    TextSpan(
                      text: _maskedDestination,
                      style: TextStyle(
                        color: AppColor.primary,
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
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 70,
                fieldWidth: 60,
                borderWidth: 1.5,
                activeColor: AppColor.primary,
                inactiveColor: AppColor.border,
                selectedColor: AppColor.primary.withOpacity(0.5),
                inactiveFillColor: AppColor.primarySoft,
                activeFillColor: Colors.white,
                selectedFillColor: AppColor.primarySoft,
              ),
              cursorColor: Colors.black,
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
                    color: Colors.red,
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
              return Center(child: CircularProgressIndicator());
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
                    email: widget.email, // از صفحه قبلی آمده (ممکن است null باشد)
                    mobileNumber: widget.mobileNumber, // اگر موبایل بوده، این پر است
                  ),
                );

              },
              child: Text(
                'تایید',
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
      ],
    );
  }
}