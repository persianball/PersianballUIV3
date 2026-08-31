import 'package:flutter/material.dart';

/// نوعِ اسلاید — تعیین می‌کند در کدام صفحه نمایش داده شود.
enum SliderKind { product, course, other }

SliderKind _kindFrom(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'product':
      return SliderKind.product;
    case 'course':
      return SliderKind.course;
    default:
      return SliderKind.other;
  }
}

/// «r,g,b» یا «#RRGGBB» یا «RRGGBB» را به Color تبدیل می‌کند؛ در غیر این
/// صورت null.
Color? parseRgb(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  if (s.contains(',')) {
    final parts = s.split(',').map((e) => int.tryParse(e.trim())).toList();
    if (parts.length >= 3 && parts.take(3).every((e) => e != null)) {
      return Color.fromARGB(255, parts[0]!, parts[1]!, parts[2]!);
    }
    return null;
  }
  var hex = s.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  final v = int.tryParse(hex, radix: 16);
  return v == null ? null : Color(v);
}

/// یک اسلایدِ گالری از اندپوینت `/v1/gallery/slider/`.
class SliderItem {
  final String imageUrl;
  final String? videoUrl;
  final String? clickUrl;
  final String? text;
  final String? headerText;
  final String? buttonText;
  final SliderKind kind;
  final int sortingOrder;
  final Color? headerColor;
  final Color? buttonColor;
  final Color? textColor;

  const SliderItem({
    required this.imageUrl,
    required this.kind,
    required this.sortingOrder,
    this.videoUrl,
    this.clickUrl,
    this.text,
    this.headerText,
    this.buttonText,
    this.headerColor,
    this.buttonColor,
    this.textColor,
  });

  bool get hasCaption =>
      (headerText != null && headerText!.trim().isNotEmpty) ||
      (text != null && text!.trim().isNotEmpty) ||
      (buttonText != null && buttonText!.trim().isNotEmpty);

  /// [mediaBase] هاستِ سرورِ گالری برای مطلق‌کردن مسیرهای `/media/...`.
  factory SliderItem.fromJson(Map<String, dynamic> j, String mediaBase) {
    String abs(String? rel) {
      final r = (rel ?? '').trim();
      if (r.isEmpty) return '';
      if (r.startsWith('http')) return r;
      return '$mediaBase${r.startsWith('/') ? '' : '/'}$r';
    }

    final rawText = (j['text'] as String?)?.trim();
    final rawVideo = (j['video'] as String?)?.trim();
    return SliderItem(
      imageUrl: abs(j['image'] as String?),
      videoUrl: (rawVideo == null || rawVideo.isEmpty) ? null : abs(rawVideo),
      clickUrl: (j['click_url'] as String?)?.trim().isEmpty ?? true
          ? null
          : (j['click_url'] as String).trim(),
      text: (rawText == null || rawText.isEmpty) ? null : rawText,
      headerText: (j['header_text'] as String?)?.trim().isEmpty ?? true
          ? null
          : (j['header_text'] as String).trim(),
      buttonText: (j['button_text'] as String?)?.trim().isEmpty ?? true
          ? null
          : (j['button_text'] as String).trim(),
      kind: _kindFrom(j['slider_type'] as String?),
      sortingOrder: (j['sorting_order'] as num?)?.toInt() ?? 0,
      headerColor: parseRgb(j['header_rgb']),
      buttonColor: parseRgb(j['button_rgb']),
      textColor: parseRgb(j['text_rgb']),
    );
  }
}
