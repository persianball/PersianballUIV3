// lib/firebase_options.dart
//
// پیکربندی Firebase به تفکیک پلتفرم.
//
// مقادیر اندروید از فایل واقعی google-services.json پروژه‌ی
// «persianball-sport» برداشته شده‌اند.
//
// وب از firebaseConfigِ اپِ وب. iOS هنوز در کنسول Firebase ثبت نشده است. هر پلتفرم در Firebase
// اپلیکیشنِ جدا با appId و apiKey مخصوصِ خودش دارد؛ این مقادیر از روی
// اندروید قابلِ ساختن نیستند و حدس زدنشان فقط باعث می‌شود اپ موقع اجرا
// خطای مبهم بدهد. پس عمداً خالی مانده و با پیام روشن خطا می‌دهد.
//
// برای پر کردنشان کافی است یک بار این را اجرا کنید (توضیح در FIREBASE.md):
//   flutterfire configure --project=persianball-sport
import 'package:firebase_core/firebase_core.dart'
    show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      if (!_webReady) {
        throw UnsupportedError(
          'پیکربندی Firebase برای وب کامل نیست: apiKey و appId اپِ وب را '
          'از Project settings → General → Your apps → Web در [web] بگذارید.',
        );
      }
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'پیکربندی Firebase برای iOS هنوز ساخته نشده است.\n'
          'اپ iOS را در کنسول Firebase با bundle id «com.persianball.football» '
          'بسازید و GoogleService-Info.plist را در ios/Runner/ بگذارید، '
          'یا «flutterfire configure --project=persianball-sport» را اجرا کنید.',
        );
      default:
        throw UnsupportedError(
          'Firebase روی ${defaultTargetPlatform.name} پیکربندی نشده است.',
        );
    }
  }

  /// از android/app/google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAFxOFbfoMgDjObF2GufPoEwM-y6OmuEXc',
    appId: '1:1099509125025:android:ec8ec4b2d7e7bdcc6a45e0',
    messagingSenderId: '1099509125025',
    projectId: 'persianball-sport',
    storageBucket: 'persianball-sport.appspot.com',
  );

  /// firebaseConfigِ اپِ وب در کنسول Firebase (این مقادیر عمومی‌اند و در
  /// خودِ اپِ وب منتشر می‌شوند).
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDtPSqNo7n8_h-it1eOrSzl68QRLbmvktg',
    appId: '1:1099509125025:web:eace8f949e67c1436a45e0',
    messagingSenderId: '1099509125025',
    projectId: 'persianball-sport',
    authDomain: 'persianball-sport.firebaseapp.com',
    storageBucket: 'persianball-sport.firebasestorage.app',
    measurementId: 'G-YL1Q4YCTMW',
  );

  /// Web Push certificate (کلیدِ عمومیِ VAPID) از Cloud Messaging.
  static const String webVapidKey =
      'BJD4d5itQdQq7Re9lxHW1gbKrDrwHXamfRRN3-ItXdffgdGCoZ9ws9dpchrX_MJnFB2ndPWQFGJb7_ZmteeNEYo';

  static bool get _webReady => web.apiKey.isNotEmpty && web.appId.isNotEmpty;

  /// آیا پلتفرم جاری پیکربندی دارد؟ برای اینکه اپ روی پلتفرم‌های
  /// پیکربندی‌نشده به‌جای کرش، فقط بی‌صدا از پوش صرف‌نظر کند.
  static bool get isConfigured {
    if (kIsWeb) return _webReady;
    return defaultTargetPlatform == TargetPlatform.android;
  }
}
