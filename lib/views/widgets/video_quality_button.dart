// lib/views/widgets/video_quality_button.dart
//
// دکمه‌ی «کیفیت» برای پخش‌کننده‌های دوره. برچسبِ کیفیتِ فعلی را نشان
// می‌دهد و با ضربه فهرستِ کیفیت‌های فایلِ m3u8 باز می‌شود.
import 'package:flutter/material.dart';

import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/services/hls_quality.dart';

class VideoQualityButton extends StatelessWidget {
  const VideoQualityButton({
    super.key,
    required this.variants,
    required this.selected,
    required this.onSelected,
    this.busy = false,
  });

  /// از کم به زیاد
  final List<HlsVariant> variants;

  /// null یعنی «خودکار» (master.m3u8، پخش‌کننده خودش انتخاب می‌کند)
  final HlsVariant? selected;
  final ValueChanged<HlsVariant?> onSelected;

  /// در حالِ عوض کردنِ کیفیت
  final bool busy;

  static const int _auto = -1;

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) return const SizedBox.shrink();
    final String current = selected?.label ?? 'خودکار';

    return PopupMenuButton<int>(
      tooltip: 'کیفیت ویدیو',
      enabled: !busy,
      color: const Color(0xFF1C1F1D),
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 210, maxWidth: 280),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      initialValue: selected?.height ?? _auto,
      onSelected: (h) => onSelected(
        h == _auto ? null : variants.firstWhere((v) => v.height == h),
      ),
      itemBuilder: (_) => [
        // بالاترین کیفیت بالای فهرست، «خودکار» در انتها
        for (final v in variants.reversed)
          _item(v.height, v.label, _hint(v.height),
              selected?.height == v.height),
        const PopupMenuDivider(height: 8),
        _item(_auto, 'خودکار', 'بر اساسِ سرعتِ اینترنت', selected == null),
      ],
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: ShapeDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: const StadiumBorder(side: BorderSide(color: Colors.white24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.6, color: Colors.white),
                  )
                : const Icon(Icons.tune_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              current,
              style: const TextStyle(
                fontFamily: 'Estedad',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _hint(int height) {
    if (height >= 1080) return 'Full HD';
    if (height >= 720) return 'HD';
    if (height <= 240) return 'کم‌حجم';
    return null;
  }

  PopupMenuItem<int> _item(int value, String label, String? hint, bool on) {
    return PopupMenuItem<int>(
      value: value,
      height: 42,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: on
                ? const Icon(Icons.check_rounded,
                    size: 18, color: AppColor.pitchGreenLight)
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Estedad',
              fontSize: 13,
              fontWeight: on ? FontWeight.w800 : FontWeight.w500,
              color: Colors.white,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: 'Estedad', fontSize: 11, color: Colors.white54),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
