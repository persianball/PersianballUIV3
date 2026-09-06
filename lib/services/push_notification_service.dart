// lib/services/push_notification_service.dart
//
// پوش‌نوتیفیکیشن با Firebase Cloud Messaging.
//
// چرخه‌ی کار:
//   ۱. Firebase راه‌اندازی می‌شود (فقط اگر پلتفرم پیکربندی داشته باشد).
//   ۲. از کاربر اجازه گرفته می‌شود (iOS و اندروید ۱۳+ لازم دارند).
//   ۳. توکن FCM گرفته و با DeviceRegistrationService به سرور فرستاده می‌شود.
//   ۴. تغییرِ بعدیِ توکن هم خودکار به سرور می‌رود.
//
// هیچ‌کدام از این مراحل نباید بالا آمدن اپ را متوقف کند: نبودِ شبکه،
// ردِ اجازه، یا پیکربندی‌نشده بودنِ پلتفرم فقط پوش را غیرفعال می‌کند.
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:marketky/firebase_options.dart';
import 'package:marketky/services/device_registration_service.dart';

/// هندلرِ پیام در حالتِ پس‌زمینه/بسته.
///
/// باید top-level و با @pragma('vm:entry-point') باشد، وگرنه در بیلدِ
/// release حذف می‌شود و پیام‌های پس‌زمینه بی‌صدا از دست می‌روند.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // این ایزولیت جداست و هیچ‌چیز از اپ در آن راه‌اندازی نشده.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // نمایشِ خودِ نوتیفیکیشن با سیستم‌عامل است؛ اینجا فقط جای کارِ
  // پس‌زمینه (مثلاً به‌روزرسانی شمارنده) است.
}

class PushNotificationService {
  PushNotificationService._();

  static bool _ready = false;
  static StreamSubscription<String>? _tokenSub;
  static StreamSubscription<RemoteMessage>? _foregroundSub;

  /// آخرین توکنِ گرفته‌شده؛ بعد از ورودِ کاربر لازم می‌شود.
  static String? _token;
  static String? get token => _token;

  /// پیامی که کاربر با ضربه روی نوتیفیکیشن باز کرده؛ برای مسیریابی.
  static final StreamController<RemoteMessage> _opened =
      StreamController<RemoteMessage>.broadcast();
  static Stream<RemoteMessage> get onMessageOpened => _opened.stream;

  /// پیامِ رسیده در حالی که اپ باز است.
  static final StreamController<RemoteMessage> _foreground =
      StreamController<RemoteMessage>.broadcast();
  static Stream<RemoteMessage> get onForegroundMessage => _foreground.stream;

  /// راه‌اندازی در شروع اپ. هرگز throw نمی‌کند.
  static Future<void> init() async {
    if (_ready) return;
    if (!DefaultFirebaseOptions.isConfigured) {
      // پلتفرم هنوز در Firebase ثبت نشده (iOS/وب): بی‌صدا رد شو.
      debugPrint('[push] پیکربندی Firebase برای این پلتفرم موجود نیست.');
      return;
    }
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final granted = settings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!granted) {
        debugPrint('[push] کاربر اجازه‌ی نوتیفیکیشن نداد.');
        _ready = true;
        return;
      }

      // در iOS تا وقتی توکن APNs نرسد، getToken null برمی‌گرداند.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _token = await messaging.getToken();
      debugPrint('[push] token: ${_token == null ? 'null' : 'دریافت شد'}');
      await _sendToken();

      // توکن FCM دائمی نیست (نصب مجدد، پاک کردن داده، چرخشِ دوره‌ای)
      _tokenSub?.cancel();
      _tokenSub = messaging.onTokenRefresh.listen((t) async {
        _token = t;
        await _sendToken();
      });

      _foregroundSub?.cancel();
      _foregroundSub = FirebaseMessaging.onMessage.listen((m) {
        if (!_foreground.isClosed) _foreground.add(m);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((m) {
        if (!_opened.isClosed) _opened.add(m);
      });

      // اپ کاملاً بسته بوده و با ضربه روی نوتیفیکیشن باز شده
      final initial = await messaging.getInitialMessage();
      if (initial != null && !_opened.isClosed) {
        _opened.add(initial);
      }

      _ready = true;
    } catch (e) {
      // نبودِ Google Play Services، شبکه‌ی قطع، یا پیکربندی ناقص
      debugPrint('[push] راه‌اندازی ناموفق: $e');
    }
  }

  /// بعد از ورود کاربر صدا زده می‌شود: دستگاه به حساب او وصل می‌شود.
  ///
  /// ثبت دستگاه توکنِ ورود می‌خواهد، پس قبل از login بی‌اثر است و باید
  /// دوباره فراخوانی شود.
  static Future<void> onLogin() async {
    await _sendToken(force: true);
  }

  /// بعد از خروج: ارتباط دستگاه با کاربر قبلی فراموش می‌شود تا پوشِ او
  /// به دستگاهی که دیگر دستش نیست نرود.
  static Future<void> onLogout() async {
    await DeviceRegistrationService.clear();
  }

  static Future<void> _sendToken({bool force = false}) async {
    if (_token == null || _token!.isEmpty) return;
    try {
      await DeviceRegistrationService.register(
          fcmToken: _token, force: force);
    } catch (e) {
      debugPrint('[push] ثبت دستگاه ناموفق: $e');
    }
  }
}
