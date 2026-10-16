// lib/views/widgets/player/browser_fullscreen_stub.dart
//
// غیرِ وب: مرورگری در کار نیست.
class BrowserFullscreen {
  BrowserFullscreen._();

  static bool get supported => false;
  static bool get isActive => false;
  static Future<void> enter() async {}
  static Future<void> exit() async {}

  /// شنونده‌ی تغییرِ وضعیت؛ خروجی تابعِ لغو است.
  static void Function() listen(void Function() onChange) => () {};
}
