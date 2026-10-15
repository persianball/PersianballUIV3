<div dir="rtl">

# پرشین بال

<img src="assets/icons/pers_icon.png" width="96" alt="پرشین بال">

**Persian Ball**: a football shop and academy app (Flutter, Persian/RTL). It runs on Android, iOS and the web, and the web build installs as a PWA.

اپِ فروشگاه و آکادمی فوتبال «پرشین بال». کاربر از آن تجهیزات می‌خرد، در دوره‌های آموزشی ثبت‌نام می‌کند و ویدیوهای دوره را می‌بیند. اپ با Flutter نوشته شده و تمامِ رابطش فارسی و راست‌به‌چپ است.

نسخه‌ی وب: <https://persianball.github.io/PersianballUIV3/>

## امکانات

**فروشگاه**
- خانه با اسلایدر، دسته‌بندی‌ها و پیشنهادها
- فروشگاه با دسته‌بندی‌هایی که با یک «قرص» متحرک عوض می‌شوند
- جستجو، صفحه‌ی محصول، انتخابِ رنگ و سایز با نمایشِ موجودی
- نظرها و امتیازدهی، و «خبرم کن» برای کالاهای ناموجود

**دوره‌ها**
- جزئیاتِ دوره با تب‌های «برنامه‌ی هفتگی» و «زمان و مکانِ برگزاری»
- انتخابِ گونه‌های دوره، مثلاً سانس‌ها یا شعبه‌های مختلف
- **دوره‌ی مجموعه‌ای:** دوره‌ای که از چند زیردوره ساخته شده و هر زیردوره برنامه‌ی هفتگیِ خودش را دارد
- ویدیوهای قفل پشتِ یک پرده‌ی تار نمایش داده می‌شوند و کارتِ «تهیه‌ی دوره» رویشان است
- «دوره‌های من» با پخش‌کننده‌ی ویدیو و ذخیره‌ی پیشرفت

**خرید و حساب**
- سبد خرید با انیمیشنِ افتادنِ کالا در سبد
- انتخابِ آدرس، خلاصه‌ی سفارش و پرداخت درون‌اپ
- فهرست و جزئیاتِ سفارش‌ها با تاریخِ شمسی
- ورود با رمز یا کدِ یک‌بارمصرف، ثبت‌نام، فراموشیِ رمز و امنیتِ حساب
- پیام‌ها و اعلان‌ها، و اعلانِ push با Firebase Cloud Messaging (فعلاً فقط اندروید)

**پلتفرم**
- لینکِ عمیق با اسکیمِ `persianball://product/12` و لینک‌های وبِ دامنه‌های اپ
- نسخه‌ی وب قابلِ نصب (PWA) است و پوسته‌ی اپ بدونِ اینترنت هم باز می‌شود
- چیدمانِ واکنش‌گرا برای موبایل و دسکتاپ

## فناوری‌ها

| بخش | ابزار |
|---|---|
| فریم‌ورک | Flutter 3.35.1 (Dart 3) |
| مدیریتِ وضعیت | `flutter_bloc`, `equatable` |
| شبکه | `http`, `cached_network_image` |
| ویدیو | `video_player`, `chewie` |
| محتوای HTML | `flutter_html_all` |
| پرداخت | `webview_flutter` |
| لینکِ عمیق | `app_links` |
| اعلان | `firebase_core`, `firebase_messaging` |
| ذخیره‌ی محلی | `shared_preferences` |

بک‌اند: `https://pball.ah8ad3.ir` با احرازِ هویتِ token. نشانی در `lib/constant/urls.dart` است.

## ساختارِ پروژه

```
lib/
├── main.dart              نقطه‌ی شروع، تم، مسیرِ اولیه و لینکِ عمیق
├── core/                  app_router (همه‌ی مسیرها)، deep_link_resolver
├── bloc/                  cart، login، otp، address، product، ...
├── services/              تماس با API (هر حوزه یک فایل)
├── models/                مدل‌های داده و parse کردنِ JSON
├── constant/              رنگ، تایپوگرافی، شکل‌ها، URL ها
├── utils/                 تاریخِ شمسی، auth guard، ...
└── views/
    ├── screens/           صفحه‌ها
    └── widgets/           ویجت‌های مشترک
test/                      تست‌های واحد و ویجت
tool/                      patch_service_worker.py (برای PWA)
```

نامِ پکیجِ Dart **`persian_ball`** است. importها به این شکل نوشته می‌شوند: `import 'package:persian_ball/...';`

## اجرا

```bash
flutter pub get
```

```bash
flutter run
```

```bash
flutter test
```

```bash
flutter analyze --no-fatal-infos
```

برای build:

```bash
flutter build apk --release
```

```bash
flutter build web --release --no-tree-shake-icons --no-web-resources-cdn --base-href=/PersianballUIV3/
```

شناسه‌ی اپ در اندروید و iOS `com.persianball.football` است. تنظیماتِ Firebase و کارهای باقی‌مانده‌ی iOS و وب در [FIREBASE.md](FIREBASE.md) آمده است.

## انتشارِ نسخه‌ی وب (GitHub Pages)

سایت با هر push روی `main` از طریقِ `.github/workflows/deploy.yml` منتشر می‌شود. شاخه‌ی `dev` کارِ در جریان است و `main` همان چیزی است که روی سایت است. برای انتشار:

```bash
git push origin dev:main
```

ورک‌فلو پیش از انتشار `flutter analyze` و `flutter test` را اجرا می‌کند. اگر یکی از این دو شکست بخورد، نسخه منتشر نمی‌شود.

### چیزهایی که نباید عوض شوند

اگر هر کدام از این‌ها عوض شود، سایت سفید می‌شود یا کارِ آفلاین می‌شکند:

1. **`base href`**: در `web/index.html` باید مقدارِ `$FLUTTER_BASE_HREF` بماند، نه `"/"` ثابت. Pages اپ را زیرِ مسیرِ `/PersianballUIV3/` سرو می‌کند.
2. **مسیردهیِ hash** (`#/route`): GitHub Pages برای SPA فالبک ندارد. اگر `usePathUrlStrategy()` اضافه شود، رفرش روی هر صفحه‌ی داخلی ۴۰۴ می‌دهد.
3. **`--no-web-resources-cdn`**: موتورِ رندر را از خودِ سایت سرو می‌کند، نه از gstatic. service worker فقط فایل‌های هم‌مبدأ را کش می‌کند.
4. **`tool/patch_service_worker.py`** بعد از build اجرا می‌شود. service worker ـِ پیش‌فرضِ فلاتر زیرِ زیرمسیر هیچ فایلی را از کش سرو نمی‌کند.

## اعتبار

رابطِ اولیه از قالبِ متن‌باز [MarketKy](https://github.com/mrezkys/marketky) (مجوزِ MIT) شروع شده و از آن زمان تقریباً به‌طورِ کامل بازنویسی شده است. متنِ مجوز در [LICENSE](LICENSE) است.

</div>
