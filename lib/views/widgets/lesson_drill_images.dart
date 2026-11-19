// lib/views/widgets/lesson_drill_images.dart
//
// دو تصویرِ هر ویدیوی دوره: چیدمانِ تمرین (layout_image) و میزانِ انجامِ
// تمرین (volume_image). هرکدام که آپلود نشده (null) نشان داده نمی‌شود؛ اگر
// هیچ‌کدام نبود، خودِ بلوک هم نیست. ضربه → تمام‌صفحه با امکانِ بزرگ‌نمایی.
import 'package:flutter/material.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:persian_ball/constant/urls.dart';
import 'package:persian_ball/views/widgets/app_network_image.dart';

/// سرور گاهی مسیرِ نسبی (/media/...) می‌دهد.
String drillImageUrl(String raw) {
  final v = raw.trim();
  if (v.startsWith('http')) return v;
  return '${URLs.origin}${v.startsWith('/') ? v : '/$v'}';
}

class LessonDrillImages extends StatelessWidget {
  const LessonDrillImages({
    super.key,
    required this.layoutImage,
    required this.volumeImage,
  });

  final String? layoutImage;
  final String? volumeImage;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      if (layoutImage != null) ('چیدمان تمرین', drillImageUrl(layoutImage!)),
      if (volumeImage != null) ('میزان انجام تمرین', drillImageUrl(volumeImage!)),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _tile(context, items, i)),
        ],
      ],
    );
  }

  Widget _tile(BuildContext context, List<(String, String)> items, int i) {
    final (label, url) = items[i];
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColor.cardMuted,
        shape: AppShapes.border(AppShapes.rMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => _DrillImageViewer(items: items, initial: i),
          )),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: AppNetworkImage(url: url, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: Row(
                  children: [
                    const Icon(Icons.zoom_in_rounded,
                        size: 15, color: AppColor.pitchGreen),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColor.ink)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// نمایشِ تمام‌صفحه با زوم؛ بینِ دو تصویر ورق می‌خورد.
class _DrillImageViewer extends StatefulWidget {
  const _DrillImageViewer({required this.items, required this.initial});
  final List<(String, String)> items;
  final int initial;

  @override
  State<_DrillImageViewer> createState() => _DrillImageViewerState();
}

class _DrillImageViewerState extends State<_DrillImageViewer> {
  late final PageController _pages = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(widget.items[_index].$1,
              style: const TextStyle(fontFamily: 'Estedad', fontSize: 15)),
        ),
        body: PageView.builder(
          controller: _pages,
          itemCount: widget.items.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Center(
              child: AppNetworkImage(
                  url: widget.items[i].$2, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
