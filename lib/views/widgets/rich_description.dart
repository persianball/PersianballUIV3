// lib/views/widgets/rich_description.dart
//
// متنِ توضیحاتی که از پنلِ ادمین می‌آید همیشه متنِ خام نیست: گاهی HTML
// (ویرایشگرِ متنی) و گاهی مارک‌داونِ ساده («**مهم**»، «# عنوان»، «- مورد»).
// پیش‌تر همان‌طور خام نشان داده می‌شد و ستاره‌ها وسطِ جمله می‌ماندند.
//
// اینجا: اگر تگِ HTML دارد → رندرِ HTMLِ موجود؛ وگرنه مارک‌داونِ سبک:
//   **پررنگ**  __پررنگ__  *کج*  _کج_  ***پررنگِ کج***
//   # عنوان / ## زیرعنوان   - مورد / * مورد / ۱. مورد
//   خطِ خالی = پاراگرافِ جدید
import 'package:flutter/material.dart';

import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/views/widgets/html_description_image.dart';

class RichDescription extends StatelessWidget {
  const RichDescription({
    super.key,
    required this.text,
    this.style,
    this.strongColor,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle? style;

  /// رنگِ متنِ پررنگ و عنوان‌ها (پیش‌فرض تیره‌تر از متنِ عادی)
  final Color? strongColor;
  final TextAlign textAlign;

  static final RegExp _htmlTag =
      RegExp(r'<\s*(p|br|b|strong|i|em|ul|ol|li|h[1-6]|div|span|a|img|table)\b',
          caseSensitive: false);

  static bool looksLikeHtml(String s) => _htmlTag.hasMatch(s);

  @override
  Widget build(BuildContext context) {
    final String src = text.trim();
    if (src.isEmpty) return const SizedBox.shrink();
    if (looksLikeHtml(src)) return HtmlDescriptionBody(html: src);

    final TextStyle base = const TextStyle(
      fontFamily: 'Estedad',
      fontSize: 13,
      height: 1.9,
      color: AppColor.inkMuted,
    ).merge(style);
    final Color strong = strongColor ?? AppColor.ink;

    final blocks = parseMarkdownBlocks(src);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < blocks.length; i++) ...[
          if (i > 0) SizedBox(height: blocks[i].isListItem ? 2 : 10),
          _block(blocks[i], base, strong),
        ],
      ],
    );
  }

  Widget _block(MdBlock b, TextStyle base, Color strong) {
    final TextStyle bodyStyle = b.heading > 0
        ? base.copyWith(
            fontWeight: FontWeight.w800,
            color: strong,
            fontSize: (base.fontSize ?? 13) + (b.heading == 1 ? 3 : 1.5),
            height: 1.6,
          )
        : base;
    final span = TextSpan(
      style: bodyStyle,
      children: [
        for (final s in b.spans)
          TextSpan(
            text: s.text,
            style: TextStyle(
              fontWeight: s.bold ? FontWeight.w800 : null,
              color: s.bold ? strong : null,
              fontStyle: s.italic ? FontStyle.italic : null,
            ),
          ),
      ],
    );
    final rich = Text.rich(span, textAlign: textAlign);
    if (!b.isListItem) return rich;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8, top: 2),
            child: b.marker == null
                ? Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                        color: AppColor.pitchGreen, shape: BoxShape.circle),
                  )
                : Text(b.marker!,
                    style: base.copyWith(
                        fontWeight: FontWeight.w800, color: strong)),
          ),
          Expanded(child: rich),
        ],
      ),
    );
  }
}

class MdSpan {
  const MdSpan(this.text, {this.bold = false, this.italic = false});
  final String text;
  final bool bold, italic;

  @override
  bool operator ==(Object o) =>
      o is MdSpan && o.text == text && o.bold == bold && o.italic == italic;
  @override
  int get hashCode => Object.hash(text, bold, italic);
  @override
  String toString() =>
      '${bold ? "B" : ""}${italic ? "I" : ""}"$text"';
}

class MdBlock {
  const MdBlock(this.spans, {this.heading = 0, this.marker, this.isListItem = false});
  final List<MdSpan> spans;

  /// ۰ = پاراگراف، ۱ = «#»، ۲ = «##» و بیشتر
  final int heading;

  /// شماره‌ی موردِ فهرست («۱.»)؛ null برای بولت
  final String? marker;
  final bool isListItem;

  String get plain => spans.map((s) => s.text).join();
}

final RegExp _orderedItem = RegExp(r'^\s*([0-9۰-۹]+)[.)]\s+(.*)$');
final RegExp _bulletItem = RegExp(r'^\s*[-•*]\s+(.*)$');
final RegExp _heading = RegExp(r'^\s*(#{1,6})\s+(.*)$');

/// خط‌ها → بلوک‌ها. خط‌های پشتِ‌سرِ‌همِ غیرِ‌فهرست یک پاراگراف می‌شوند (مثلِ
/// مارک‌داون)، خطِ خالی پاراگراف را می‌بندد.
List<MdBlock> parseMarkdownBlocks(String src) {
  final lines = src.replaceAll('\r\n', '\n').split('\n');
  final blocks = <MdBlock>[];
  final para = <String>[];

  void flush() {
    if (para.isEmpty) return;
    blocks.add(MdBlock(parseInlineMarkdown(para.join(' '))));
    para.clear();
  }

  for (final raw in lines) {
    final line = raw.trimRight();
    if (line.trim().isEmpty) {
      flush();
      continue;
    }
    final h = _heading.firstMatch(line);
    if (h != null) {
      flush();
      blocks.add(MdBlock(parseInlineMarkdown(h.group(2)!),
          heading: h.group(1)!.length));
      continue;
    }
    final o = _orderedItem.firstMatch(line);
    if (o != null) {
      flush();
      blocks.add(MdBlock(parseInlineMarkdown(o.group(2)!),
          marker: '${o.group(1)}.', isListItem: true));
      continue;
    }
    final bl = _bulletItem.firstMatch(line);
    if (bl != null) {
      flush();
      blocks.add(MdBlock(parseInlineMarkdown(bl.group(1)!), isListItem: true));
      continue;
    }
    para.add(line.trim());
  }
  flush();
  return blocks;
}

/// تجزیه‌ی داخلِ خط: ***x*** / **x** / __x__ / *x* / _x_.
/// نشانه‌هایی که جفت ندارند همان‌طور متن می‌مانند (ستاره‌ی تنها از بین نمی‌رود).
List<MdSpan> parseInlineMarkdown(String s) {
  final out = <MdSpan>[];
  final buf = StringBuffer();
  bool bold = false, italic = false;

  void emit() {
    if (buf.isEmpty) return;
    out.add(MdSpan(buf.toString(), bold: bold, italic: italic));
    buf.clear();
  }

  bool hasClosing(String token, int from) => s.indexOf(token, from) != -1;

  int i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == '*' || c == '_') {
      // طولِ دنباله‌ی نشانه
      int n = 1;
      while (i + n < s.length && s[i + n] == c) {
        n++;
      }
      final token = c * (n >= 3 ? 3 : n);
      final bool closing =
          (n >= 3 && (bold || italic)) || (n == 2 && bold) || (n == 1 && italic);
      if (closing || hasClosing(token, i + token.length)) {
        emit();
        if (n >= 3) {
          final on = !(bold && italic);
          bold = on;
          italic = on;
        } else if (n == 2) {
          bold = !bold;
        } else {
          italic = !italic;
        }
        i += token.length;
        // ستاره‌های اضافه (بیش از ۳) متن‌اند
        if (n > 3) buf.write(c * (n - 3));
        continue;
      }
      buf.write(c * n);
      i += n;
      continue;
    }
    buf.write(c);
    i++;
  }
  emit();
  // ادغامِ تکه‌های هم‌سبکِ پشتِ‌سرِ‌هم
  final merged = <MdSpan>[];
  for (final sp in out) {
    if (merged.isNotEmpty &&
        merged.last.bold == sp.bold &&
        merged.last.italic == sp.italic) {
      merged[merged.length - 1] =
          MdSpan(merged.last.text + sp.text, bold: sp.bold, italic: sp.italic);
    } else {
      merged.add(sp);
    }
  }
  return merged;
}
