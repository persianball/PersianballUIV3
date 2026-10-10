// lib/views/screens/account_security_page.dart
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_breakpoints.dart';
import 'package:marketky/constant/app_shapes.dart';
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

  /// نمایش/پنهان‌کردن هر فیلد رمز به‌صورت مستقل
  bool _showOld = false;
  bool _showNew = false;
  bool _showRepeat = false;

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
          backgroundColor: AppColor.surfaceContainerOpaque,
          shape: AppShapes.border(AppShapes.rLg),
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
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
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
          // دسکتاپ: فرم در کارتی وسط‌چین با حداکثر عرض ۵۶۰؛
          // موبایل/تبلت: همان لیست تمام‌عرض قبلی
          child: AppBreakpoints.isDesktop(context)
              ? SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      vertical: 32, horizontal: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: ShapeDecoration(
                          color: AppColor.surfaceContainer,
                          shape: AppShapes.border(AppShapes.rLg),
                          shadows: AppColor.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _formChildren(),
                        ),
                      ),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _formChildren(),
                ),
        ),
      ),
    );
  }

  /// محتوای مشترک فرم (تغییر رمز + حذف حساب) برای هر دو چیدمان
  List<Widget> _formChildren() => [
              const Text('تغییر رمز عبور',
                  style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColor.onSurface)),
              const SizedBox(height: 12),
              _field(_oldCtrl, 'رمز فعلی',
                  visible: _showOld,
                  onToggle: () => setState(() => _showOld = !_showOld)),
              const SizedBox(height: 10),
              _field(_newCtrl, 'رمز جدید',
                  visible: _showNew,
                  onToggle: () => setState(() => _showNew = !_showNew)),
              const SizedBox(height: 10),
              _field(_repeatCtrl, 'تکرار رمز جدید',
                  visible: _showRepeat,
                  onToggle: () => setState(() => _showRepeat = !_showRepeat)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.goldEnd,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: AppShapes.pill,
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
                    shape: AppShapes.pill,
                  ),
                  child: const Text('حذف حساب کاربری',
                      style: TextStyle(fontFamily: 'Estedad')),
                ),
              ),
            ];

  Widget _field(
    TextEditingController c,
    String label, {
    required bool visible,
    required VoidCallback onToggle,
  }) =>
      TextField(
        controller: c,
        obscureText: !visible,
        style: const TextStyle(fontFamily: 'Estedad', color: AppColor.ink),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              fontFamily: 'Estedad', fontSize: 13, color: AppColor.inkMuted),
          filled: true,
          fillColor: AppColor.card,
          prefixIcon: const Icon(Icons.lock_outline_rounded,
              size: 20, color: AppColor.inkMuted),
          // دکمه‌ی نمایش/پنهان رمز، هم‌اندازه‌ی بقیه‌ی آیکن‌های فیلد
          suffixIcon: IconButton(
            onPressed: onToggle,
            tooltip: visible ? 'پنهان کردن رمز' : 'نمایش رمز',
            splashRadius: 20,
            icon: Icon(
              visible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: visible ? AppColor.pitchGreen : AppColor.inkMuted,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: AppShapes.radius(AppShapes.rMd),
            borderSide: const BorderSide(color: AppColor.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppShapes.radius(AppShapes.rMd),
            borderSide: const BorderSide(color: AppColor.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppShapes.radius(AppShapes.rMd),
            borderSide: const BorderSide(color: AppColor.pitchGreen, width: 2),
          ),
        ),
      );
}
