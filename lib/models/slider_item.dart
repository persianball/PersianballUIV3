import 'package:flutter/material.dart';

/// نوعِ اسلاید (`slider_type`) — تعیین می‌کند اسلاید چطور رندر شود و ضربه
/// روی آن کجا برود:
///   • video   → ویدیوی فیلدِ `video` پخش می‌شود
///   • picture → فقط تصویر
///   • product / course → تصویر، و ضربه به صفحه‌ی همان آیتم می‌رود
///     (شناسه از `click_url` خوانده می‌شود؛ مثل .../course/21)
enum SliderKind { product, course, video, picture, other }

SliderKind _kindFrom(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'product':
      return SliderKind.product;
    case 'course':
      return SliderKind.course;
    case 'video':
      return SliderKind.video;
    case 'picture':
    case 'image':
      return SliderKind.picture;
    default:
      return SliderKind.other;
  }
}

/// صفحه‌ای که اسلایدر در آن دیده می‌شود. بک‌اند برای هر صفحه یک «دسته»
/// جدا دارد و نسخه‌ی موبایل (`app_…`) و دسکتاپ (`site_…`) از هم جدا هستند.
enum SliderPage { home, academy }

/// نگاشتِ صفحه + اندازه‌ی نمایشگر به شماره‌ی دسته‌ی بک‌اند.
/// این عدد به‌صورت `?category=<num>` به اندپوینت اسلایدر داده می‌شود.
class SliderCategory {
  SliderCategory._();

  static const int appHomePage = 1; // app_home_page      — موبایل، خانه
  static const int appAcademyPage = 2; // app_academy_page   — موبایل، دوره‌ها
  static const int siteAcademyPage = 4; // site_academy_page  — دسکتاپ، دوره‌ها
  static const int siteMainHomePage = 5; // site_main_home_page — دسکتاپ، خانه

  /// [desktop] یعنی نمایشگر بزرگ (تبلت به بالا) که نسخه‌ی `site_…` می‌گیرد.
  static int of(SliderPage page, {required bool desktop}) {
    switch (page) {
      case SliderPage.home:
        return desktop ? siteMainHomePage : appHomePage;
      case SliderPage.academy:
        return desktop ? siteAcademyPage : appAcademyPage;
    }
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

  /// دسته‌ی بک‌اند (`category`) — همان عددی که در کوئری فیلتر می‌شود.
  final int? category;
  final int sortingOrder;
  final Color? headerColor;
  final Color? buttonColor;
  final Color? textColor;

  const SliderItem({
    required this.imageUrl,
    required this.kind,
    required this.sortingOrder,
    this.category,
    this.videoUrl,
    this.clickUrl,
    this.text,
    this.headerText,
    this.buttonText,
    this.headerColor,
    this.buttonColor,
    this.textColor,
  });

  /// اسلاید ویدیویی: نوعش video است و لینک ویدیو هم دارد.
  bool get isVideo =>
      kind == SliderKind.video && (videoUrl?.isNotEmpty ?? false);

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
      // baseUrl ته‌اسلش دارد و مسیرها هم با / شروع می‌شوند؛ بدون این، آدرس
      // اسلش دوتایی می‌گیرد.
      final base = mediaBase.endsWith('/')
          ? mediaBase.substring(0, mediaBase.length - 1)
          : mediaBase;
      return '$base${r.startsWith('/') ? '' : '/'}$r';
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
      category: (j['category'] as num?)?.toInt(),
      sortingOrder: (j['sorting_order'] as num?)?.toInt() ?? 0,
      headerColor: parseRgb(j['header_rgb']),
      buttonColor: parseRgb(j['button_rgb']),
      textColor: parseRgb(j['text_rgb']),
    );
  }
}
