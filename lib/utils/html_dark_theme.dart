// utils/html_dark_theme.dart
import 'dart:math' as math;

/// پس‌زمینه‌ی واقعی صفحات اپ #0A0A0A است (روشنایی نسبی ≈ ۰.۰۰۳۳).
/// اگر روشنایی نسبی رنگ متن از این کمتر باشد، کنتراست روی آن پس‌زمینه
/// کمتر از ۴.۵:۱ می‌شود و عملاً خوانا نیست.
const double _minLuminance = 0.19;

/// هدف روشنایی بعد از اصلاح (کنتراست ~۵.۳:۱).
const double _targetLuminance = 0.25;

/// رنگ جایگزین برای رنگ‌های بی‌رنگ (سیاه/خاکستری تیره).
const String _neutralLight = '#E2E2E2';

/// رنگ‌های نام‌دار CSS که روی پس‌زمینه‌ی تیره تاریک محسوب می‌شوند.
const Map<String, List<int>> _namedDarkColors = {
  'black': [0, 0, 0],
  'navy': [0, 0, 128],
  'darkblue': [0, 0, 139],
  'mediumblue': [0, 0, 205],
  'blue': [0, 0, 255],
  'darkgreen': [0, 100, 0],
  'green': [0, 128, 0],
  'darkslategray': [47, 79, 79],
  'darkslategrey': [47, 79, 79],
  'maroon': [128, 0, 0],
  'darkred': [139, 0, 0],
  'brown': [165, 42, 42],
  'firebrick': [178, 34, 34],
  'purple': [128, 0, 128],
  'darkmagenta': [139, 0, 139],
  'indigo': [75, 0, 130],
  'darkviolet': [148, 0, 211],
  'teal': [0, 128, 128],
  'darkcyan': [0, 139, 139],
  'darkolivegreen': [85, 107, 47],
  'olive': [128, 128, 0],
  'saddlebrown': [139, 69, 19],
  'sienna': [160, 82, 45],
  'dimgray': [105, 105, 105],
  'dimgrey': [105, 105, 105],
  'gray': [128, 128, 128],
  'grey': [128, 128, 128],
  'slategray': [112, 128, 144],
  'slategrey': [112, 128, 144],
  'darkslateblue': [72, 61, 139],
  'midnightblue': [25, 25, 112],
  'crimson': [220, 20, 60],
  'darkgoldenrod': [184, 134, 11],
  'forestgreen': [34, 139, 34],
  'seagreen': [46, 139, 87],
  'steelblue': [70, 130, 180],
  'royalblue': [65, 105, 225],
  'mediumvioletred': [199, 21, 133],
};

class _Rgb {
  final int r, g, b;
  const _Rgb(this.r, this.g, this.b);
}

/// تبدیل یک مقدار رنگ CSS به RGB. اگر قابل تشخیص نبود null برمی‌گرداند
/// تا مقدار اصلی دست‌نخورده بماند.
_Rgb? _parseColor(String raw) {
  final value = raw.trim().toLowerCase();
  if (value.isEmpty) return null;

  final named = _namedDarkColors[value];
  if (named != null) return _Rgb(named[0], named[1], named[2]);

  if (value.startsWith('#')) {
    final hex = value.substring(1);
    if (hex.length == 3 || hex.length == 4) {
      final r = int.tryParse(hex[0] * 2, radix: 16);
      final g = int.tryParse(hex[1] * 2, radix: 16);
      final b = int.tryParse(hex[2] * 2, radix: 16);
      if (r == null || g == null || b == null) return null;
      return _Rgb(r, g, b);
    }
    if (hex.length == 6 || hex.length == 8) {
      final r = int.tryParse(hex.substring(0, 2), radix: 16);
      final g = int.tryParse(hex.substring(2, 4), radix: 16);
      final b = int.tryParse(hex.substring(4, 6), radix: 16);
      if (r == null || g == null || b == null) return null;
      return _Rgb(r, g, b);
    }
    return null;
  }

  final rgbMatch =
      RegExp(r'^rgba?\(([^)]*)\)$').firstMatch(value);
  if (rgbMatch != null) {
    final parts = rgbMatch
        .group(1)!
        .split(RegExp(r'[,\s/]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length < 3) return null;
    final channels = <int>[];
    for (var i = 0; i < 3; i++) {
      final p = parts[i];
      final n = p.endsWith('%')
          ? (double.tryParse(p.substring(0, p.length - 1)) ?? -1) * 255 / 100
          : double.tryParse(p) ?? -1;
      if (n < 0) return null;
      channels.add(n.round().clamp(0, 255));
    }
    return _Rgb(channels[0], channels[1], channels[2]);
  }

  final hslMatch = RegExp(r'^hsla?\(([^)]*)\)$').firstMatch(value);
  if (hslMatch != null) {
    final parts = hslMatch
        .group(1)!
        .split(RegExp(r'[,\s/]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length < 3) return null;
    final h = double.tryParse(parts[0].replaceAll(RegExp(r'deg$'), ''));
    final s = double.tryParse(parts[1].replaceAll('%', ''));
    final l = double.tryParse(parts[2].replaceAll('%', ''));
    if (h == null || s == null || l == null) return null;
    return _hslToRgb(h / 360, s / 100, l / 100);
  }

  return null;
}

double _srgbToLinear(int channel) {
  final c = channel / 255.0;
  return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4) as double;
}

/// روشنایی نسبی طبق WCAG.
double _luminance(_Rgb c) =>
    0.2126 * _srgbToLinear(c.r) +
    0.7152 * _srgbToLinear(c.g) +
    0.0722 * _srgbToLinear(c.b);

List<double> _rgbToHsl(_Rgb c) {
  final r = c.r / 255.0, g = c.g / 255.0, b = c.b / 255.0;
  final max = math.max(r, math.max(g, b));
  final min = math.min(r, math.min(g, b));
  final l = (max + min) / 2;
  if (max == min) return [0, 0, l];
  final d = max - min;
  final s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
  double h;
  if (max == r) {
    h = (g - b) / d + (g < b ? 6 : 0);
  } else if (max == g) {
    h = (b - r) / d + 2;
  } else {
    h = (r - g) / d + 4;
  }
  return [h / 6, s, l];
}

double _hueToRgb(double p, double q, double t) {
  var tt = t;
  if (tt < 0) tt += 1;
  if (tt > 1) tt -= 1;
  if (tt < 1 / 6) return p + (q - p) * 6 * tt;
  if (tt < 1 / 2) return q;
  if (tt < 2 / 3) return p + (q - p) * (2 / 3 - tt) * 6;
  return p;
}

_Rgb _hslToRgb(double h, double s, double l) {
  if (s == 0) {
    final v = (l * 255).round().clamp(0, 255);
    return _Rgb(v, v, v);
  }
  final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  final p = 2 * l - q;
  return _Rgb(
    (_hueToRgb(p, q, h + 1 / 3) * 255).round().clamp(0, 255),
    (_hueToRgb(p, q, h) * 255).round().clamp(0, 255),
    (_hueToRgb(p, q, h - 1 / 3) * 255).round().clamp(0, 255),
  );
}

String _toHex(_Rgb c) =>
    '#${c.r.toRadixString(16).padLeft(2, '0')}'
            '${c.g.toRadixString(16).padLeft(2, '0')}'
            '${c.b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();

/// اگر رنگ روی پس‌زمینه‌ی تیره خوانا نباشد، نسخه‌ی روشن‌شده‌اش را
/// برمی‌گرداند؛ در غیر این صورت null (یعنی دست نزن).
String? lightenIfTooDark(String rawColor) {
  final rgb = _parseColor(rawColor);
  if (rgb == null) return null;
  if (_luminance(rgb) >= _minLuminance) return null;

  final hsl = _rgbToHsl(rgb);
  // رنگ‌های بی‌رنگ (سیاه/خاکستری) به خاکستری روشن ثابت تبدیل می‌شوند.
  if (hsl[1] < 0.12) return _neutralLight;

  // بقیه: فام و اشباع حفظ می‌شود، فقط روشنایی تا حد خوانا بالا می‌رود.
  var l = hsl[2];
  _Rgb out = rgb;
  while (l < 0.92) {
    l = math.min(0.92, l + 0.02);
    out = _hslToRgb(hsl[0], hsl[1], l);
    if (_luminance(out) >= _targetLuminance) break;
  }
  return _toHex(out);
}

/// رنگ متنِ HTMLِ آمده از ادیتور بک‌اند را برای پس‌زمینه‌ی تیره‌ی اپ
/// اصلاح می‌کند: هر رنگی که روی پس‌زمینه‌ی #0A0A0A کنتراست کافی ندارد
/// (سیاه، خاکستری تیره، سرمه‌ای، قهوه‌ای و…) روشن می‌شود و فام اصلی‌اش
/// حفظ می‌ماند. رنگ‌های به‌اندازه‌ی کافی روشن دقیقاً دست‌نخورده می‌مانند،
/// و `background-color` هم اصلاً دست نمی‌خورد.
String sanitizeHtmlForDarkBg(String html) {
  if (html.isEmpty) return html;

  // ۱) اعلان CSS: `color: X` (نه `background-color`).
  var out = html.replaceAllMapped(
    RegExp(r'''(^|[^-\w])(color\s*:\s*)([^;"'}<]+)''', caseSensitive: false),
    (m) {
      final replacement = lightenIfTooDark(m.group(3)!);
      if (replacement == null) return m.group(0)!;
      return '${m.group(1)}${m.group(2)}$replacement';
    },
  );

  // ۲) اتریبیوت قدیمی `<font color="X">`.
  out = out.replaceAllMapped(
    RegExp(r'''(^|[^-\w])(color\s*=\s*)(["'])([^"']*)\3''',
        caseSensitive: false),
    (m) {
      final replacement = lightenIfTooDark(m.group(4)!);
      if (replacement == null) return m.group(0)!;
      return '${m.group(1)}${m.group(2)}${m.group(3)}$replacement${m.group(3)}';
    },
  );

  return out;
}
