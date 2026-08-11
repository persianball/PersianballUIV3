// lib/services/account_service.dart
//
// مدیریت حساب: تغییر رمز، بازیابی رمز و حذف حساب.
//
// وضعیت بک‌اند (بررسی‌شده با curl):
//   POST /v1/user/password/reset/   → 404 (وجود ندارد)
//   POST /v1/user/password/change/  → 404 (وجود ندارد)
//   POST /v1/user/delete/           → 401 (وجود دارد، نیازمند توکن)
//
// پیشنهاد برای بک‌اند:
//   POST /v1/user/password/reset/          {email|mobile_number}
//        → کد یک‌بارمصرف ارسال می‌کند
//   POST /v1/user/password/reset/confirm/  {email|mobile_number, code, new_password}
//   POST /v1/user/password/change/         {old_password, new_password}
//   DELETE /v1/user/delete/                {password?}  ← الزام استور‌ها برای حذف حساب
//
// تا آماده شدن endpointها، متدهای زیر شبیه‌سازی می‌کنند و isMock=true دارند تا
// UI به کاربر شفاف بگوید عملیات واقعی نیست. حذف حساب چون endpoint دارد،
// واقعاً صدا زده می‌شود.
import 'package:http/http.dart' as http;
import 'package:marketky/constant/urls.dart';
import 'package:marketky/services/auth_service.dart';

class AccountActionResult {
  final bool success;
  final String message;

  /// یعنی این عملیات واقعاً به سرور نرفته
  final bool isMock;

  const AccountActionResult({
    required this.success,
    required this.message,
    this.isMock = false,
  });
}

class AccountService {
  /// درخواست کد بازیابی رمز
  static Future<AccountActionResult> requestPasswordReset(
      String destination) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (destination.trim().isEmpty) {
      return const AccountActionResult(
          success: false, message: 'ایمیل یا شماره موبایل را وارد کنید');
    }
    return const AccountActionResult(
      success: true,
      message: 'کد بازیابی ارسال شد (شبیه‌سازی — نیازمند endpoint بک‌اند)',
      isMock: true,
    );
  }

  /// ثبت رمز جدید با کد بازیابی
  static Future<AccountActionResult> confirmPasswordReset({
    required String destination,
    required String code,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (code.trim().length < 4) {
      return const AccountActionResult(
          success: false, message: 'کد واردشده معتبر نیست');
    }
    if (newPassword.length < 6) {
      return const AccountActionResult(
          success: false, message: 'رمز عبور باید حداقل ۶ کاراکتر باشد');
    }
    return const AccountActionResult(
      success: true,
      message: 'رمز عبور تغییر کرد (شبیه‌سازی — نیازمند endpoint بک‌اند)',
      isMock: true,
    );
  }

  /// تغییر رمز کاربر واردشده
  static Future<AccountActionResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (oldPassword.isEmpty) {
      return const AccountActionResult(
          success: false, message: 'رمز فعلی را وارد کنید');
    }
    if (newPassword.length < 6) {
      return const AccountActionResult(
          success: false, message: 'رمز جدید باید حداقل ۶ کاراکتر باشد');
    }
    if (oldPassword == newPassword) {
      return const AccountActionResult(
          success: false, message: 'رمز جدید باید با رمز فعلی متفاوت باشد');
    }
    return const AccountActionResult(
      success: true,
      message: 'رمز عبور تغییر کرد (شبیه‌سازی — نیازمند endpoint بک‌اند)',
      isMock: true,
    );
  }

  /// حذف حساب کاربری — endpoint واقعاً وجود دارد
  static Future<AccountActionResult> deleteAccount() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return const AccountActionResult(
          success: false, message: 'ابتدا وارد حساب خود شوید');
    }
    try {
      final res = await http.post(
        Uri.parse('${URLs.baseUrl}/v1/user/delete/'),
        headers: {
          'Authorization': 'token $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        await AuthService.logout();
        return const AccountActionResult(
            success: true, message: 'حساب کاربری شما حذف شد');
      }
      return AccountActionResult(
          success: false, message: 'حذف حساب ناموفق بود (${res.statusCode})');
    } catch (e) {
      return const AccountActionResult(
          success: false, message: 'خطا در ارتباط با سرور');
    }
  }
}
