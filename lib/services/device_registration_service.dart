// lib/services/device_registration_service.dart
//
// ثبت دستگاه کاربر برای پوش‌نوتیفیکیشن.
//
//   POST  /v1/user/devices/       → ساخت رکورد دستگاه (۲۰۱ با id)
//   PATCH /v1/user/devices/<id>/  → به‌روزرسانی (مثلاً وقتی fcm_token عوض شد)
//
// نکته‌های اندازه‌گیری‌شده از OPTIONS و پاسخ‌های واقعی سرور:
//   • device_type فقط `web` یا `mobile` را می‌پذیرد (اندروید و iOS هر دو
//     mobile هستند). مقدار دیگر خطای ۴۰۰ می‌دهد.
//   • محدودیت طول: display ۱۵، device_id ۲۰، fcm_token ۲۰۰،
//     sdk_release/manufacturer/model/version_* هرکدام ۵۰.
//     مقادیر بلندتر با ۴۰۰ رد می‌شوند، پس اینجا کوتاه می‌شوند.
//   • GET و DELETE روی این مسیر ۴۰۵ می‌دهند؛ فقط POST و PATCH هست. برای
//     همین id دستگاه باید سمت کلاینت نگه داشته شود.
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:marketky/constant/urls.dart';
import 'package:marketky/services/auth_service.dart';

/// اطلاعاتی که سرور برای یک دستگاه می‌خواهد.
class DeviceProfile {
  final int sdkVersion;
  final String sdkRelease;
  final String display;
  final String manufacturer;
  final String model;
  final String versionName;
  final String versionCode;
  final String deviceId;

  /// `web` یا `mobile`
  final String deviceType;

  const DeviceProfile({
    required this.sdkVersion,
    required this.sdkRelease,
    required this.display,
    required this.manufacturer,
    required this.model,
    required this.versionName,
    required this.versionCode,
    required this.deviceId,
    required this.deviceType,
  });

  Map<String, dynamic> toJson({String? fcmToken}) => {
        'sdk_version': sdkVersion.clamp(0, 32767),
        'sdk_release': _cap(sdkRelease, 50),
        'display': _cap(display, 15),
        'manufacturer': _cap(manufacturer, 50),
        'model': _cap(model, 50),
        'version_name': _cap(versionName, 50),
        'version_code': _cap(versionCode, 50),
        'device_id': _cap(deviceId, 20),
        if (fcmToken != null && fcmToken.isNotEmpty)
          'fcm_token': _cap(fcmToken, 200),
        'device_type': deviceType,
      };

  static String _cap(String v, int max) =>
      v.length <= max ? v : v.substring(0, max);
}

class DeviceRegistrationService {
  DeviceRegistrationService._();

  static const String _endpoint = 'v1/user/devices/';

  /// شناسه‌ی رکوردِ ساخته‌شده روی سرور؛ چون GET نداریم باید محلی بماند.
  static const String _kServerId = 'device_server_id';

  /// شناسه‌ی پایدارِ خودِ دستگاه (حداکثر ۲۰ کاراکتر، محدودیت سرور).
  static const String _kDeviceId = 'device_local_id';

  /// آخرین توکنی که موفق فرستاده‌ایم؛ برای جلوگیری از PATCH بی‌مورد.
  static const String _kSentToken = 'device_sent_fcm_token';

  static String get _base => URLs.baseUrl.endsWith('/')
      ? URLs.baseUrl.substring(0, URLs.baseUrl.length - 1)
      : URLs.baseUrl;

  /// شناسه‌ی دستگاه: یک‌بار ساخته و برای همیشه نگه داشته می‌شود.
  ///
  /// از شناسه‌ی سیستمی استفاده نمی‌کنیم چون سقفِ سرور ۲۰ کاراکتر است و
  /// مثلاً identifierForVendor در iOS یک UUID ۳۶ کاراکتری است.
  static Future<String> _localDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_kDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random.secure();
    final id = List.generate(20, (_) => chars[rnd.nextInt(chars.length)]).join();
    await prefs.setString(_kDeviceId, id);
    return id;
  }

  /// جمع‌آوری مشخصات دستگاه برای پلتفرم جاری.
  static Future<DeviceProfile> currentProfile() async {
    final deviceId = await _localDeviceId();
    String versionName = '';
    String versionCode = '';
    try {
      final pkg = await PackageInfo.fromPlatform();
      versionName = pkg.version;
      versionCode = pkg.buildNumber;
    } catch (_) {
      // در تست‌ها یا محیط بدون پلاگین
    }

    final info = DeviceInfoPlugin();

    if (kIsWeb) {
      String browser = 'web';
      try {
        final web = await info.webBrowserInfo;
        browser = web.browserName.name;
      } catch (_) {}
      return DeviceProfile(
        sdkVersion: 0,
        sdkRelease: browser,
        display: 'web',
        manufacturer: 'browser',
        model: browser,
        versionName: versionName,
        versionCode: versionCode,
        deviceId: deviceId,
        deviceType: 'web',
      );
    }

    try {
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        return DeviceProfile(
          sdkVersion: a.version.sdkInt,
          sdkRelease: a.version.release,
          display: a.display,
          manufacturer: a.manufacturer,
          model: a.model,
          versionName: versionName,
          versionCode: versionCode,
          deviceId: deviceId,
          deviceType: 'mobile',
        );
      }
      if (Platform.isIOS) {
        final i = await info.iosInfo;
        return DeviceProfile(
          // iOS نسخه‌ی SDK عددی ندارد؛ عددِ major نسخه فرستاده می‌شود
          sdkVersion: int.tryParse(i.systemVersion.split('.').first) ?? 0,
          sdkRelease: i.systemVersion,
          display: i.name,
          manufacturer: 'Apple',
          model: i.utsname.machine,
          versionName: versionName,
          versionCode: versionCode,
          deviceId: deviceId,
          deviceType: 'mobile',
        );
      }
    } catch (_) {
      // اگر پلاگین در دسترس نبود، حداقلِ لازم فرستاده می‌شود
    }

    return DeviceProfile(
      sdkVersion: 0,
      sdkRelease: 'unknown',
      display: 'unknown',
      manufacturer: 'unknown',
      model: 'unknown',
      versionName: versionName,
      versionCode: versionCode,
      deviceId: deviceId,
      deviceType: kIsWeb ? 'web' : 'mobile',
    );
  }

  /// ثبت یا به‌روزرسانی دستگاه.
  ///
  /// بار اول POST و دفعات بعد PATCH می‌زند. اگر توکن عوض نشده باشد و رکورد
  /// از قبل ساخته شده باشد، هیچ درخواستی نمی‌رود.
  /// خروجی: true یعنی سرور دستگاه را دارد و به‌روز است.
  static Future<bool> register({String? fcmToken, bool force = false}) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final serverId = prefs.getInt(_kServerId);
    final sentToken = prefs.getString(_kSentToken);

    if (!force &&
        serverId != null &&
        fcmToken != null &&
        fcmToken == sentToken) {
      return true; // چیزی عوض نشده
    }

    final profile = await currentProfile();
    final body = jsonEncode(profile.toJson(fcmToken: fcmToken));
    final headers = {
      'Authorization': 'token $token',
      'Content-Type': 'application/json',
    };

    try {
      if (serverId == null) {
        final res = await http
            .post(Uri.parse('$_base/$_endpoint'),
                headers: headers, body: utf8.encode(body))
            .timeout(const Duration(seconds: 15));
        if (res.statusCode == 200 || res.statusCode == 201) {
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          if (data is Map && data['id'] is int) {
            await prefs.setInt(_kServerId, data['id'] as int);
          }
          if (fcmToken != null) await prefs.setString(_kSentToken, fcmToken);
          return true;
        }
        return false;
      }

      final res = await http
          .patch(Uri.parse('$_base/$_endpoint$serverId/'),
              headers: headers, body: utf8.encode(body))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (fcmToken != null) await prefs.setString(_kSentToken, fcmToken);
        return true;
      }
      // رکورد سمت سرور نیست (پاک شده): دفعه‌ی بعد دوباره POST شود
      if (res.statusCode == 404) {
        await prefs.remove(_kServerId);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// بعد از خروج از حساب، ارتباط دستگاه با کاربر قبلی باید فراموش شود.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kServerId);
    await prefs.remove(_kSentToken);
  }
}
