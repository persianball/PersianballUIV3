// views/widgets/html_description_image.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/urls.dart';
import 'package:url_launcher/url_launcher.dart';

/// یک تصویر تکی داخل توضیحات محصول. تصاویر خروجی ادیتور بک‌اند معمولاً
/// روی هاست شخص ثالث هستند و اغلب هدر CORS ندارند؛ در وب، خواندن بایت
/// تصویر برای دیکد بدون CORS بلاک می‌شود. `WebHtmlElementStrategy.fallback`
/// در این حالت فلاتر را به یک `<img>` خام برمی‌گرداند که برای *نمایش*
/// (نه خواندن پیکسل) نیازی به CORS ندارد.
///
/// نکته‌ی مهم: این ویجت باید همیشه به‌صورت یک فرزند معمولی در درخت ویجت
/// قرار بگیرد، نه داخل `WidgetSpan`/`RichText` (مثلاً از طریق
/// `TagExtension` روی تگ `img` در flutter_html). تصویر «fallback» شده
/// (چه با Image.network، چه با HtmlElementView دستی) وقتی داخل WidgetSpan
/// تو در توی یک RichText اسکرول‌شونده باشد در این نسخه‌ی فلاتر کاملاً
/// نامرئی می‌ماند (تأیید شده تجربی) — به همین دلیل `HtmlDescriptionBody`
/// پایین‌تر تصاویر را از جریان HTML جدا و به‌صورت ویجت مستقل بین قطعات
/// متن رندر می‌کند.
class HtmlDescriptionImage extends StatefulWidget {
  final String src;
  final double? aspectRatio;

  /// اگر ادمین تصویر را در ادیتور به یک لینک متصل کرده باشد (تصویر داخل
  /// `<a href="...">`)، با تپ روی تصویر همان لینک باز می‌شود.
  final String? linkUrl;

  const HtmlDescriptionImage({
    super.key,
    required this.src,
    this.aspectRatio,
    this.linkUrl,
  });

  @override
  State<HtmlDescriptionImage> createState() => _HtmlDescriptionImageState();
}

class _HtmlDescriptionImageState extends State<HtmlDescriptionImage> {
  bool _failed = false;
  bool _loaded = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    // اگر بارگذاری تصویر (مثلاً به‌خاطر یک مشکل شبکه‌ی گذرا در دیکد/فچ
    // اولیه‌ی وب) هرگز به errorBuilder/frameBuilder نرسد و برای همیشه
    // معلق بماند، بعد از این مهلت placeholder نشان داده می‌شود تا فضای
    // خالی دائمی در صفحه نماند.
    _timeoutTimer = Timer(const Duration(seconds: 12), () {
      if (!_loaded) _reportError('timeout', null);
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _reportError(Object error, StackTrace? stackTrace) {
    if (kDebugMode) {
      debugPrint('[html-img] بارگذاری تصویر توضیحات ناموفق بود\n'
          '  src: ${widget.src}\n'
          '  error: $error');
    }
    if (_failed || !mounted) return;
    setState(() => _failed = true);
  }

  void _markLoaded() {
    _timeoutTimer?.cancel();
    if (_loaded || !mounted) return;
    setState(() => _loaded = true);
  }

  Widget _buildWeb() {
    return Image.network(
      widget.src,
      fit: BoxFit.contain,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _markLoaded());
        }
        return child;
      },
      errorBuilder: (_, error, stackTrace) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _reportError(error, stackTrace));
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMobile() {
    return Image.network(
      widget.src,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColor.goldEnd,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _markLoaded());
        }
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (_, error, stackTrace) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _reportError(error, stackTrace));
        return const SizedBox.shrink();
      },
    );
  }

void _openLink() {
    final url = widget.linkUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    // مستقیم (بدون await قبلی) صدا زده می‌شود؛ در وب، هر تأخیر بین کلیک
    // کاربر و window.open باعث می‌شود مرورگر آن را پاپ‌آپ مسدودشده در نظر
    // بگیرد. canLaunchUrl هم روی وب عملاً چیزی اضافه بررسی نمی‌کند.
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = _failed
        ? Image.asset('assets/images/placeholder.jpg', fit: BoxFit.contain)
        : ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: widget.aspectRatio ?? (16 / 10),
              child: kIsWeb ? _buildWeb() : _buildMobile(),
            ),
          );

    if (widget.linkUrl == null || widget.linkUrl!.isEmpty) return content;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: _openLink, child: content),
    );
  }
}

class _DescriptionSegment {
  final bool isImage;
  final String? html;
  final String? src;
  final double? aspectRatio;
  final String? linkUrl;

  _DescriptionSegment.html(this.html)
      : isImage = false,
        src = null,
        aspectRatio = null,
        linkUrl = null;

  _DescriptionSegment.image(this.src, this.aspectRatio, this.linkUrl)
      : isImage = true,
        html = null;
}

/// خروجی ادیتور بک‌اند تصاویر مستقل را داخل `<figure class="image ...">`
/// قرار می‌دهد (نه اینکه وسط یک جمله باشند) و گاهی خودِ تصویر با
/// `<a href="...">` به یک لینک متصل شده (تصویر قابل‌کلیک). به همین دلیل
/// قبل از رندر، HTML دور هر `<figure>[<a>]<img>[</a>]</figure>` بریده
/// می‌شود تا هر تصویر به‌جای اینکه به‌عنوان WidgetSpan داخل RichText بیاید
/// (که در وب نامرئی می‌ماند، توضیح کامل در `HtmlDescriptionImage`)، به‌صورت
/// یک ویجت مستقل بین دو تکه متن HTML قرار بگیرد.
final RegExp _figureImageRegExp = RegExp(
  r'<figure[^>]*class="[^"]*\bimage\b[^"]*"[^>]*>\s*'
  r'(?:<a\b[^>]*\bhref\s*=\s*["\x27]([^"\x27]*)["\x27][^>]*>\s*)?'
  r'<img\b([^>]*)>\s*'
  r'(?:</a>\s*)?</figure>',
  caseSensitive: false,
  dotAll: true,
);

List<_DescriptionSegment> _splitDescriptionHtml(String html) {
  final segments = <_DescriptionSegment>[];
  var last = 0;
  for (final match in _figureImageRegExp.allMatches(html)) {
    if (match.start > last) {
      segments.add(_DescriptionSegment.html(html.substring(last, match.start)));
    }
    final linkUrl = match.group(1);
    final attrs = match.group(2) ?? '';
    final rawSrc =
        RegExp(r'''src\s*=\s*["']([^"']*)["']''').firstMatch(attrs)?.group(1) ??
            '';
    if (rawSrc.isNotEmpty) {
      final src =
          rawSrc.startsWith('http') ? rawSrc : '${URLs.baseUrl}$rawSrc';
      final w = double.tryParse(
          RegExp(r'''width\s*=\s*["']?(\d+)''').firstMatch(attrs)?.group(1) ??
              '');
      final h = double.tryParse(
          RegExp(r'''height\s*=\s*["']?(\d+)''').firstMatch(attrs)?.group(1) ??
              '');
      final aspectRatio = (w != null && h != null && h > 0) ? w / h : null;
      segments.add(_DescriptionSegment.image(
        src,
        aspectRatio,
        (linkUrl != null && linkUrl.isNotEmpty) ? linkUrl : null,
      ));
    }
    last = match.end;
  }
  if (last < html.length) {
    segments.add(_DescriptionSegment.html(html.substring(last)));
  }
  return segments;
}

/// رندر کامل توضیحات محصول: تکه‌های متنی/جدولی از HTML واقعی از طریق
/// `flutter_html` و تصاویر مستقل (`<figure><img></figure>`) به‌صورت
/// ویجت‌های مستقل بین آن‌ها. دلیل جداسازی در داک `HtmlDescriptionImage`
/// توضیح داده شده.
class HtmlDescriptionBody extends StatelessWidget {
  final String html;
  final void Function(String? url, Map<String, String> attributes, dynamic element)?
      onLinkTap;

  const HtmlDescriptionBody({super.key, required this.html, this.onLinkTap});

  static final Map<String, Style> _style = {
    "body": Style(
        color: AppColor.onSurfaceVariant,
        fontFamily: 'Estedad',
        margin: Margins.zero),
    "a": Style(
        color: AppColor.goldEnd,
        fontSize: FontSize(14),
        textDecoration: TextDecoration.underline),
    // عرض جدول باید auto باشد؛ با عرض کامل، فضای باقی‌مانده داخل کادر
    // جدول مثل یک ستون خالی اضافه دیده می‌شد.
    "table": Style(
        border: Border.all(color: AppColor.outlineVariantDark),
        width: Width.auto(),
        margin: Margins.symmetric(vertical: 8)),
    "th": Style(
        border: Border.all(color: AppColor.outlineVariantDark),
        backgroundColor: AppColor.surfaceContainerHigh,
        padding: HtmlPaddings.all(6),
        fontWeight: FontWeight.w700),
    "td": Style(
        border: Border.all(color: AppColor.outlineVariantDark),
        padding: HtmlPaddings.all(6)),
  };

  @override
  Widget build(BuildContext context) {
    final segments = _splitDescriptionHtml(html);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final segment in segments)
          if (segment.isImage)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: HtmlDescriptionImage(
                key: ValueKey(segment.src),
                src: segment.src!,
                aspectRatio: segment.aspectRatio,
                linkUrl: segment.linkUrl,
              ),
            )
          else if (segment.html!.trim().isNotEmpty)
            Html(
              data: segment.html!,
              onLinkTap: onLinkTap,
              style: _style,
              extensions: const [TableHtmlExtension()],
            ),
      ],
    );
  }
}
