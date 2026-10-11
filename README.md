# MarketKy.

## Introduction

MarketKy is a Free Flutter E-Commerce App Starter Template that can help you develop an E-Commerce or Market application much faster. You just need to add some adjustment to the frontend and you can create your own backend.

## App Screenshot
<img src="https://github.com/mrezkys/marketky/blob/main/demo/banner.jpg" width="auto" height="auto" >
<img src="https://github.com/mrezkys/marketky/blob/main/demo/shot.jpg" width="auto" height="auto" >
<img src="https://github.com/mrezkys/marketky/blob/main/demo/details.jpg" width="auto" height="auto" >

## Whats inside
- Welcome Page
- Login Page
- Register Page
- OTP Verification Page
- Home Page
- Profile Page
- Feeds Page
- Notification Page
- Cart Page Empty
- Cart Page
- Search Page
- Search Result Page
- Product Detail Page
- Review Page
- Order Success Page
- Message Page
- Message Detail Page
- Image Viewer
- Page Switcher
--------
- Add to Cart Modal
--------
- Cart Tile Widget
- Category Card Widget
- Custom App Bar Widget
- Custom Icon Button Widget
- Dummy Search Widget 1
- Dummy Search Widget 2
- Explore Card Widget
- Item Card Widget
- Main App Bar Widget
- Menu Tile Widget
- Message Tile Widget
- Notification Tile Widget
- Popular Search Card Widget
- Ratig Tag Widget
- Review Tile Widget
- Search History Tile Widget
- Selectable Circle Color Widget
- Selectable Circle Size Widget
- Update Widget


## Installation

**Step 1:**

Download or clone this repo by using the link below:

```
https://github.com/mrezkys/marketky.git
```

**Step 2:**

Go to project root and execute the following command in console to get the required dependencies: 

```
flutter pub get 
```

**Step 3:**

You can run this project by using this command

```
flutter run
```


## About the Author

MarketKy is Developed by [mrezkys](https://www.facebook.com/mrezkys12)
The User Interface are designed by [mrezkys](https://dribbble.com/mrezkys)

## Thanks To
Iconly, icons that i used on this project, created by [Piqo Design](https://www.figma.com/@piqodesign) also images from adidas, nike, zara and pexels.

## License
MarketKy is under MIT License.

## Donate
You can support me at [trakteer](https://trakteer.id/mrezkys) <br>
<a href="https://trakteer.id/mrezkys" target="_blank"><img id="wse-buttons-preview" src="https://cdn.trakteer.id/images/embed/trbtn-red-5.png" height="45" style="border: 0px; height: 45px;" alt="Trakteer Saya"></a>

## Announcement

Now MarketKy already relased v1.0.0

---

## انتشار نسخه‌ی وب (GitHub Pages)

سایت با هر push روی `dev` از طریق `.github/workflows/deploy.yml` منتشر می‌شود:

```
https://persianball.github.io/PersianballUIV3/
```

ورک‌فلو قبل از انتشار `flutter analyze` و `flutter test` را اجرا می‌کند، پس
نسخه‌ی خراب روی سایت نمی‌رود.

### دو نکته‌ای که اگر فراموش شوند صفحه سفید می‌شود

**۱. `base href`** — در `web/index.html` باید `$FLUTTER_BASE_HREF` بماند، نه
`"/"` ثابت. Pages اپ را زیرمسیرِ `/PersianballUIV3/` سرو می‌کند و ورک‌فلو
همان را با `--base-href` پاس می‌دهد. اگر مقدار ثابت شود، خودِ build خطا
می‌دهد و در عمل همه‌ی asset ها ۴۰۴ می‌شوند.

**۲. مسیردهی hash** — اپ از `#/route` استفاده می‌کند. این لازم است، چون
GitHub Pages برای SPA فالبک ندارد و مسیرهای معمولی ۴۰۴ می‌دهند. اگر روزی
`usePathUrlStrategy()` اضافه شد، رفرش روی هر صفحه‌ی داخلی می‌شکند.

### محدودیت شناخته‌شده: اسلایدرها روی وبِ میزبانی‌شده بارگذاری نمی‌شوند

سرور گالری روی `http://2.144.27.195:8000` است و HTTPS ندارد. GitHub Pages
فقط HTTPS سرو می‌کند و مرورگر درخواست‌های HTTP از صفحه‌ی HTTPS را بلاک
می‌کند (mixed content). روی `localhost` دیده نمی‌شود چون آنجا هم HTTP است.

راه‌حل سمت سرور است: گالری پشت `pball.ah8ad3.ir` بیاید که هم HTTPS دارد و
هم فایل‌های تصویرِ اسلایدها همان‌جا سرو می‌شوند.
