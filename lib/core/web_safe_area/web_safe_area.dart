// lib/core/web_safe_area/web_safe_area.dart
//
// فاصله‌ی امنِ مرورگر (env(safe-area-inset-*)) برای فلاتر وب.
//
// موتورِ وبِ فلاتر این مقدارها را نمی‌خواند و MediaQuery.padding همیشه صفر
// است. ولی صفحه با viewport-fit=cover تا لبه‌ی نمایشگر کشیده می‌شود: در
// کرومِ اندروید (لبه‌تالبه) زیرِ نوارِ ناوبریِ سیستم و در اپِ نصب‌شده‌ی iOS
// زیرِ خطِ خانه. اینجا همان مقدارها از CSS خوانده می‌شوند تا در builderِ
// ریشه به MediaQuery اضافه شوند و SafeArea مثلِ اپِ بومی کار کند.
export 'web_safe_area_stub.dart'
    if (dart.library.js_interop) 'web_safe_area_web.dart';
