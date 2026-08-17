// lib/views/screens/account_security_page.dart
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/services/account_service.dart';

/// تغییر رمز عبور و حذف حساب کاربری
class AccountSecurityPage extends StatefulWidget {
  const AccountSecurityPage({super.key});

  @override
  State<AccountSecurityPage> createState() => _AccountSecurityPageState();
}

class _AccountSecurityPageState extends State<AccountSecurityPage> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _repeatCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _repeatCtrl.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(message, style: const TextStyle(fontFamily: 'Estedad'))),
    );
  }

  Future<void> _changePassword() async {
    if (_newCtrl.text != _repeatCtrl.text) {
      _snack('تکرار رمز جدید مطابقت ندارد');
      return;
    }
    setState(() => _busy = true);
    final result = await AccountService.changePassword(
      oldPassword: _oldCtrl.text,
      newPassword: _newCtrl.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(result.message);
    if (result.success) {
      _oldCtrl.clear();
      _newCtrl.clear();
      _repeatCtrl.clear();
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColor.surfaceContainer,
          shape: const RoundedRectangleBorder(),
          title: const Text('حذف حساب کاربری',
              style: TextStyle(fontFamily: 'Estedad', fontSize: 16, color: AppColor.onSurface)),
          content: const Text(
            'با حذف حساب، سفارش‌ها، آدرس‌ها و اطلاعات شما پاک می‌شود و این کار برگشت‌پذیر نیست. مطمئن هستید؟',
            style: TextStyle(
                fontFamily: 'Estedad', fontSize: 13, height: 1.7, color: AppColor.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('انصراف',
                  style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurfaceVariant)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('حذف حساب',
                  style: TextStyle(fontFamily: 'Estedad', color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    setState(() => _busy = true);
    final result = await AccountService.deleteAccount();
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(result.message);
    if (result.success) {
      Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.obsidianBg,
        appBar: AppBar(
          backgroundColor: AppColor.obsidianBg,
          foregroundColor: AppColor.onSurface,
          elevation: 0,
          title: const Text('امنیت حساب',
              style: TextStyle(fontFamily: 'Estedad', fontSize: 16, color: AppColor.onSurface)),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('تغییر رمز عبور',
                  style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColor.onSurface)),
              const SizedBox(height: 12),
              _field(_oldCtrl, 'رمز فعلی'),
              const SizedBox(height: 10),
              _field(_newCtrl, 'رمز جدید'),
              const SizedBox(height: 10),
              _field(_repeatCtrl, 'تکرار رمز جدید'),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.goldEnd,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: const Text('ثبت رمز جدید',
                      style: TextStyle(
                          fontFamily: 'Estedad', color: AppColor.onGold)),
                ),
              ),
              Divider(height: 40, color: AppColor.outlineVariantDark),
              const Text('حذف حساب کاربری',
                  style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColor.onSurface)),
              const SizedBox(height: 8),
              Text(
                'با حذف حساب همه اطلاعات شما پاک می‌شود. این عملیات قابل بازگشت نیست.',
                style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 12,
                    height: 1.7,
                    color: AppColor.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _busy ? null : _deleteAccount,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: const Text('حذف حساب کاربری',
                      style: TextStyle(fontFamily: 'Estedad')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label) => TextField(
        controller: c,
        obscureText: true,
        style: const TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              fontFamily: 'Estedad', fontSize: 13, color: AppColor.onSurfaceVariant),
          filled: true,
          fillColor: AppColor.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColor.outlineVariantDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColor.outlineVariantDark),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColor.goldEnd, width: 2),
          ),
        ),
      );
}
