import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// فاصله‌ی امنِ فعلیِ مرورگر به پیکسلِ منطقی.
final ValueNotifier<EdgeInsets> webSafeArea =
    ValueNotifier<EdgeInsets>(EdgeInsets.zero);

web.HTMLElement? _probe;

/// یک عنصرِ نامرئی با paddingِ برابرِ env(safe-area-inset-*) می‌سازد و با هر
/// تغییرِ اندازه یا چرخش دوباره می‌خواندش. هیچ‌وقت throw نمی‌کند.
void initWebSafeArea() {
  if (_probe != null) return;
  try {
    final el = web.document.createElement('div') as web.HTMLElement;
    el.style.cssText = 'position:fixed;top:0;left:0;width:0;height:0;'
        'visibility:hidden;pointer-events:none;'
        'padding:env(safe-area-inset-top,0px) env(safe-area-inset-right,0px) '
        'env(safe-area-inset-bottom,0px) env(safe-area-inset-left,0px);';
    web.document.documentElement?.appendChild(el);
    _probe = el;
    _read();
    final listener = ((web.Event _) => _read()).toJS;
    web.window.addEventListener('resize', listener);
    web.window.addEventListener('orientationchange', listener);
    web.window.visualViewport?.addEventListener('resize', listener);
    // کروم مقدار را کمی بعد از اولین چیدمان نهایی می‌کند.
    Future<void>.delayed(const Duration(milliseconds: 600), _read);
  } catch (_) {
    // بدونِ فاصله‌ی امن هم اپ باید بالا بیاید
  }
}

double _px(String v) => double.tryParse(v.replaceAll('px', '').trim()) ?? 0;

void _read() {
  final el = _probe;
  if (el == null) return;
  try {
    final s = web.window.getComputedStyle(el);
    final next = EdgeInsets.fromLTRB(
      _px(s.paddingLeft),
      _px(s.paddingTop),
      _px(s.paddingRight),
      _px(s.paddingBottom),
    );
    if (next != webSafeArea.value) webSafeArea.value = next;
  } catch (_) {}
}
