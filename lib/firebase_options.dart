// lib/firebase_options.dart
//
// پیکربندی Firebase به تفکیک پلتفرم.
//
// مقادیر اندروید از فایل واقعی google-services.json پروژه‌ی
// «persianball-sport» برداشته شده‌اند.
//
// iOS و وب هنوز در کنسول Firebase ثبت نشده‌اند. هر پلتفرم در Firebase
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
      throw UnsupportedError(
        'پیکربندی Firebase برای وب هنوز ساخته نشده است.\n'
        'یک بار «flutterfire configure --project=persianball-sport» را اجرا کنید.',
      );
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

  /// آیا پلتفرم جاری پیکربندی دارد؟ برای اینکه اپ روی پلتفرم‌های
  /// پیکربندی‌نشده به‌جای کرش، فقط بی‌صدا از پوش صرف‌نظر کند.
  static bool get isConfigured {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }
}
