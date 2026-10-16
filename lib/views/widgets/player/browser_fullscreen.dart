// lib/views/widgets/player/browser_fullscreen.dart
//
// تمام‌صفحه‌ی واقعیِ مرورگر (Fullscreen API) برای وب. روی بقیه‌ی پلتفرم‌ها
// همه‌چیز no-op است و تمام‌صفحه فقط یک مسیرِ فلاتری است.
//
// با conditional export پیاده شده تا بدونِ dart:html باشد و زیرِ wasm هم
// کامپایل شود.
export 'browser_fullscreen_stub.dart'
    if (dart.library.js_interop) 'browser_fullscreen_web.dart';
