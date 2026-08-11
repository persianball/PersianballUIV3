// lib/views/screens/forgot_password_page.dart
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/services/account_service.dart';

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
        SnackBar(content: Text(m, style: const TextStyle(fontFamily: 'Estedad'))),
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
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          title: const Text('بازیابی رمز عبور',
              style: TextStyle(fontFamily: 'Estedad', fontSize: 16)),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                _codeSent
                    ? 'کد ارسال‌شده و رمز جدید خود را وارد کنید'
                    : 'ایمیل یا شماره موبایل حساب خود را وارد کنید تا کد بازیابی ارسال شود',
                style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 13,
                    height: 1.8,
                    color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _destCtrl,
                enabled: !_codeSent,
                style: const TextStyle(fontFamily: 'Estedad'),
                decoration: InputDecoration(
                  labelText: 'ایمیل یا شماره موبایل',
                  labelStyle:
                      const TextStyle(fontFamily: 'Estedad', fontSize: 13),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontFamily: 'Estedad'),
                  decoration: InputDecoration(
                    labelText: 'کد بازیابی',
                    labelStyle:
                        const TextStyle(fontFamily: 'Estedad', fontSize: 13),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  style: const TextStyle(fontFamily: 'Estedad'),
                  decoration: InputDecoration(
                    labelText: 'رمز جدید',
                    labelStyle:
                        const TextStyle(fontFamily: 'Estedad', fontSize: 13),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : (_codeSent ? _confirm : _sendCode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_codeSent ? 'ثبت رمز جدید' : 'ارسال کد بازیابی',
                      style: const TextStyle(
                          fontFamily: 'Estedad', color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
