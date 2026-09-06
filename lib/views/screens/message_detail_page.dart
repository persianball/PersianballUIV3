// lib/views/screens/message_detail_page.dart
//
// متن کاملِ یک پیام از /v1/user/message/.
//
// نسخه‌ی قبلی یک صفحه‌ی چتِ دوطرفه با حباب‌های ساختگی و فیلد «ارسال پیام»
// بود؛ بک‌اند چنین چیزی ندارد و صندوق فقط خواندنی است، پس دکمه‌ای که کاری
// نمی‌کند حذف شد.
import 'package:flutter/material.dart';

import 'package:marketky/constant/app_breakpoints.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/services/user_message_service.dart';
import 'package:marketky/utils/jalali_date.dart';

class MessageDetailPage extends StatelessWidget {
  const MessageDetailPage({super.key, required this.data});

  final UserMessage data;

  @override
  Widget build(BuildContext context) {
    final date = data.createdAtDate;
    return Scaffold(
      backgroundColor: AppColor.obsidianBg,
      appBar: AppBar(
        backgroundColor: AppColor.obsidianBg,
        foregroundColor: AppColor.onSurface,
        elevation: 0,
        title: const Text('پیام',
            style: TextStyle(
                fontFamily: 'Estedad',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColor.onSurface)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: AppBreakpoints.isDesktop(context) ? 800 : 10000),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              physics: const BouncingScrollPhysics(),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: ShapeDecoration(
                    color: AppColor.surfaceContainer,
                    shape: AppShapes.border(AppShapes.rLg),
                    shadows: AppColor.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.displayTitle,
                          style: const TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              height: 1.7,
                              color: AppColor.onSurface)),
                      if (date != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded,
                                size: 14, color: AppColor.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(formatOrderDate(date),
                                style: const TextStyle(
                                    fontFamily: 'Estedad',
                                    fontSize: 12,
                                    color: AppColor.onSurfaceVariant)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppColor.line),
                      const SizedBox(height: 14),
                      SelectableText(
                        data.body.isEmpty ? 'این پیام متنی ندارد.' : data.body,
                        style: TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 14,
                            height: 1.9,
                            color: data.body.isEmpty
                                ? AppColor.onSurfaceVariant
                                : AppColor.onSurface),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
