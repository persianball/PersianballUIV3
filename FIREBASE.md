# پوش‌نوتیفیکیشن (Firebase Cloud Messaging)

## وضعیت فعلی

| پلتفرم | وضعیت |
|---|---|
| اندروید | ✅ کامل — `google-services.json` سر جایش، بیلد گرفته می‌شود |
| iOS | ⛔ منتظر `GoogleService-Info.plist` |
| وب | ✅ کامل — firebaseConfig و کلید VAPID در `lib/firebase_options.dart`، سرویس‌ورکر در `web/fcm/` |

شناسه‌ی اپ در هر سه پلتفرم روی **`com.persianball.football`** تنظیم شد
(قبلاً `com.example.marketky` بود که گوگل‌پلی رد می‌کند و با
`google-services.json` هم نمی‌خواند).

## چرا iOS و وب کامل نشدند

`flutterfire configure` می‌توانست هر سه را یکجا بسازد، ولی Firebase CLI روی
این سیستم با حساب **omidrazzaghi2000@gmail.com** وارد شده و پروژه‌ی
`persianball-sport` در آن حساب نیست (۱۶ پروژه دارد، این یکی بینشان نیست).
پس `google-services.json` از یک حساب گوگلِ دیگر آمده است.

مقادیر iOS و وب از روی فایل اندروید **قابل ساختن نیستند**: هر پلتفرم در
Firebase یک اپلیکیشن جدا با `appId` و `apiKey` مخصوص خودش است. حدس زدنشان
فقط باعث می‌شود اپ موقع اجرا خطای مبهم بدهد، پس در
[`lib/firebase_options.dart`](lib/firebase_options.dart) عمداً خالی مانده و
با پیام روشن خطا می‌دهد.

## راه اول (ساده‌ترین): ورود با حساب درست

```bash
firebase login
```

با همان حسابی وارد شوید که پروژه‌ی `persianball-sport` را ساخته، بعد:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=persianball-sport --platforms=android,ios,web --android-package-name=com.persianball.football --ios-bundle-id=com.persianball.football
```

این کار خودش اپ‌های iOS و وب را در پروژه می‌سازد، `GoogleService-Info.plist`
را در `ios/Runner/` می‌گذارد و `lib/firebase_options.dart` را کامل بازنویسی
می‌کند.

## راه دوم: دستی از کنسول

۱. در <https://console.firebase.google.com> پروژه‌ی `persianball-sport` →
   Project settings → Your apps
۲. **iOS app** بسازید با bundle ID `com.persianball.football`، فایل
   `GoogleService-Info.plist` را دانلود و در `ios/Runner/` بگذارید
   (در Xcode هم به تارگت Runner اضافه شود)
۳. **Web app** بسازید و مقادیر `firebaseConfig` را بدهید
۴. مقادیر را در `lib/firebase_options.dart` جای بخش‌های iOS/web بگذارید

## چیزهایی که هنوز از شما لازم است

### برای iOS (بدون این‌ها پوش روی آیفون اصلاً کار نمی‌کند)

- **APNs Auth Key** — در <https://developer.apple.com> → Certificates,
  Identifiers & Profiles → Keys → یک کلید با دسترسی APNs بسازید. فایل `.p8`
  فقط **یک بار** قابل دانلود است.
- آن را در Firebase → Project settings → Cloud Messaging → Apple app
  configuration آپلود کنید، همراه با **Key ID** و **Team ID**.
- به حساب Apple Developer پولی نیاز دارد.
- در Xcode برای تارگت Runner قابلیت‌های **Push Notifications** و
  **Background Modes → Remote notifications** را روشن کنید.

### برای وب

- **Web Push certificate (کلید VAPID)** از Firebase → Cloud Messaging
- فایل `web/firebase-messaging-sw.js` که باید با همان `firebaseConfig` وب
  ساخته شود (هنوز ساخته نشده چون پیکربندی وب را نداریم)

### برای بک‌اند

- **Service account JSON** از Firebase → Project settings → Service accounts.
  سرور برای *فرستادن* پوش به آن نیاز دارد.
- این فایل کلید محرمانه است: مستقیم به توسعه‌دهنده‌ی سرور بدهید، در گیت
  کامیت نشود.

## چطور کار می‌کند

- `PushNotificationService.init()` در `main()` صدا زده می‌شود و هرگز خطا
  پرتاب نمی‌کند؛ ردِ اجازه یا نبودِ پیکربندی فقط پوش را غیرفعال می‌کند.
- توکن FCM بعد از دریافت با `DeviceRegistrationService` به
  `POST /v1/user/devices/` می‌رود و دفعات بعد با
  `PATCH /v1/user/devices/<id>/` به‌روز می‌شود.
- ثبت دستگاه **توکنِ ورود لازم دارد**، پس بعد از هر ورود موفق دوباره
  فرستاده می‌شود (`PushNotificationService.onLogin()` در `LoginBloc`).
- بعد از خروج، ارتباط دستگاه با کاربر قبلی پاک می‌شود
  (`onLogout()`)، وگرنه پوشِ او به دستگاهی می‌رفت که دیگر دستش نیست.
- `onTokenRefresh` هم گوش داده می‌شود: توکن FCM دائمی نیست.

### پوشِ وب

- سرویس‌ورکرِ پوش در `web/fcm/firebase-messaging-sw.js` است، نه در ریشه:
  سرویس‌ورکرِ فلاتر scopeِ `/PersianballUIV3/` را دارد و دو سرویس‌ورکر با یک
  scope جای هم را می‌گیرند. پیکربندی در query stringِ ثبتِ همین فایل می‌رود.
- اجازه‌ی اعلان با دکمه‌ی «روشن کردن» در صفحه‌ی اعلان‌ها گرفته می‌شود؛ اگر
  کاربر قبلاً اجازه داده باشد، توکن موقعِ باز شدنِ سایت گرفته می‌شود.
- لمسِ اعلان در مرورگر: `webpush.fcm_options.link` اگر بود، وگرنه همان
  `route` / `order_id` / … (جدول پایین). نمونه برای توکن‌های وب:
  `"webpush": {"fcm_options": {"link": "https://persianball.github.io/PersianballUIV3/#/order/2097"}}`
- آیفون: فقط وقتی سایت با Add to Home Screen نصب شده باشد (iOS ۱۶.۴+).

### دیتای پوش (قرارداد با بک‌اند)

ضربه روی پوش صفحه‌ی مقصد را باز می‌کند و پوشی که وقتِ باز بودنِ اپ برسد
به‌صورت اسنک‌بار با دکمه‌ی «مشاهده» دیده می‌شود
([`lib/core/push_navigation.dart`](lib/core/push_navigation.dart)).
سرور مقصد را در بخشِ `data` می‌فرستد؛ همه‌ی کلیدها اختیاری‌اند و به این
ترتیب بررسی می‌شوند:

| کلید | مثال | صفحه |
|---|---|---|
| `route` | `/order/2097` | همان مسیر |
| `link` یا `url` | `https://pball.ah8ad3.ir/product/9` | همان صفحه، فقط هاست‌های خودمان |
| `order_id` | `2097` | `/order/2097` |
| `product_id` | `9` | `/product/9` |
| `course_id` | `22` | `/course/22` |

بدونِ هیچ‌کدام، صندوقِ اعلان‌ها (`/notifications`) باز می‌شود. عنوان و متن از
بخشِ `notification` خوانده می‌شود و در پوش‌های data-only از `data.title` و
`data.body`. نمونه‌ی پیام FCM HTTP v1:

```json
{
  "message": {
    "token": "<fcm_token دستگاه>",
    "notification": {"title": "سفارش شما ارسال شد", "body": "کد رهگیری: 123"},
    "data": {"route": "/order/2097"}
  }
}
```

مقدارهای `data` در FCM باید رشته باشند (`"2097"` نه `2097`).

### دو محدودیت سمت سرور

از `OPTIONS /v1/user/devices/` اندازه‌گیری شد:

- `device_id` حداکثر **۲۰** کاراکتر — ولی `identifierForVendor` در iOS یک
  UUID **۳۶ کاراکتری** است. فعلاً شناسه‌ی خودمان را می‌سازیم و پایدار ذخیره
  می‌کنیم. بهتر است سرور این را به ۶۴ برساند.
- `fcm_token` حداکثر **۲۰۰** کاراکتر — توکن‌های وب گاهی به این سقف نزدیک
  می‌شوند. پیشنهاد: ۵۱۲.
- `display` حداکثر **۱۵** کاراکتر که برای نام دستگاه‌های اندروید تنگ است.

### یک رکورد برای پاک کردن

هنگام کشفِ رفتار API یک رکورد دستگاه واقعی ساخته شد و `DELETE` روی این مسیر
مجاز نیست (۴۰۵). لطفاً از پنل ادمین حذفش کنید:

**`id: 469`** با `device_id: claude-probe-0001` و
`fcm_token: PROBE_ROTATED_TOKEN`.
