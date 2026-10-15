// lib/views/screens/forgot_password_page.dart
import 'package:flutter/material.dart';
import 'package:persian_ball/constant/app_breakpoints.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/services/account_service.dart';
import 'package:persian_ball/views/widgets/page_container.dart';
import 'package:persian_ball/views/widgets/auth_background.dart';

/// بازیابی رمز عبور در دو مرحله: ارسال کد و ثبت رمز جدید
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _destCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _destCtrl.dispose();
    _codeCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(m, style: const TextStyle(fontFamily: 'Estedad'))),
      );

  Future<void> _sendCode() async {
    setState(() => _busy = true);
    final r = await AccountService.requestPasswordReset(_destCtrl.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (r.success) _codeSent = true;
    });
    _snack(r.message);
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    final r = await AccountService.confirmPasswordReset(
      destination: _destCtrl.text,
      code: _codeCtrl.text,
      newPassword: _passCtrl.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(r.message);
    if (r.success) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AuthBackground(
        child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColor.onSurface,
          elevation: 0,
          title: const Text('بازیابی رمز عبور',
              style: TextStyle(fontFamily: 'Estedad', fontSize: 16, color: AppColor.onSurface)),
        ),
        body: _buildBody(context),
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
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: _formChildren(context),
        ),
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
                Text(
                  _codeSent
                      ? 'کد ارسال‌شده و رمز جدید خود را وارد کنید'
                      : 'ایمیل یا شماره موبایل حساب خود را وارد کنید تا کد بازیابی ارسال شود',
                  style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 13,
                      height: 1.8,
                      color: AppColor.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _destCtrl,
                  enabled: !_codeSent,
                  style: const TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface),
                  decoration: InputDecoration(
                    labelText: 'ایمیل یا شماره موبایل',
                    labelStyle: const TextStyle(
                        fontFamily: 'Estedad', fontSize: 13, color: AppColor.onSurfaceVariant),
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
                  ),
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface),
                    decoration: InputDecoration(
                      labelText: 'کد بازیابی',
                      labelStyle: const TextStyle(
                          fontFamily: 'Estedad', fontSize: 13, color: AppColor.onSurfaceVariant),
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
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    style: const TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface),
                    decoration: InputDecoration(
                      labelText: 'رمز جدید',
                      labelStyle: const TextStyle(
                          fontFamily: 'Estedad', fontSize: 13, color: AppColor.onSurfaceVariant),
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
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _busy ? null : (_codeSent ? _confirm : _sendCode),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.goldEnd,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: AppShapes.pill,
                    ),
                    child: Text(_codeSent ? 'ثبت رمز جدید' : 'ارسال کد بازیابی',
                        style: const TextStyle(
                            fontFamily: 'Estedad', color: AppColor.onGold)),
                  ),
                ),
    ];
  }
}
