// lib/views/widgets/player/browser_fullscreen_web.dart
//
// وب: کلِ سند را تمام‌صفحه می‌کند (نه فقط ویدیو)، تا کنترل‌های شیشه‌ایِ
// خودمان روی ویدیو بمانند. Esc ـِ مرورگر هم با `fullscreenchange` به
// مسیرِ فلاتری خبر می‌دهد تا آن هم بسته شود.
import 'dart:js_interop';

import 'package:web/web.dart' as web;

class BrowserFullscreen {
  BrowserFullscreen._();

  static bool get supported => true;

  static bool get isActive => web.document.fullscreenElement != null;

  static Future<void> enter() async {
    final el = web.document.documentElement;
    if (el == null || isActive) return;
    try {
      await el.requestFullscreen().toDart;
    } catch (_) {
      // سافاریِ iOS تمام‌صفحه‌ی سند را ندارد؛ مسیرِ فلاتری کافی است.
    }
  }

  static Future<void> exit() async {
    if (!isActive) return;
    try {
      await web.document.exitFullscreen().toDart;
    } catch (_) {}
  }

  static void Function() listen(void Function() onChange) {
    final JSFunction listener = ((web.Event _) => onChange()).toJS;
    web.document.addEventListener('fullscreenchange', listener);
    return () => web.document.removeEventListener('fullscreenchange', listener);
  }
}
