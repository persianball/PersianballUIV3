// lib/views/widgets/message_tile_widget.dart
//
// یک ردیف از صندوق پیام‌ها (/v1/user/message/).
import 'package:flutter/material.dart';

import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/services/user_message_service.dart';
import 'package:marketky/utils/jalali_date.dart';
import 'package:marketky/views/screens/message_detail_page.dart';
import 'package:marketky/views/widgets/motion.dart';

class MessageTileWidget extends StatelessWidget {
  const MessageTileWidget({super.key, required this.data});

  final UserMessage data;

  @override
  Widget build(BuildContext context) {
    final bool unread = !data.isRead;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: PressableScale(
        hoverScale: 1.01,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MessageDetailPage(data: data)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: ShapeDecoration(
            color: AppColor.surfaceContainer,
            // پیام خوانده‌نشده با یک قابِ سبزِ نازک از بقیه جدا می‌شود؛
            // رنگ کردنِ کلِ کارت روی پس‌زمینه‌ی شیری بیش از حد داد می‌زند.
            shape: AppShapes.border(
              AppShapes.rLg,
              side: unread
                  ? const BorderSide(color: AppColor.pitchGreen, width: 1.2)
                  : BorderSide.none,
            ),
            shadows: AppColor.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: unread
                      ? AppColor.pitchGreenSoft
                      : AppColor.cardMuted,
                  shape: AppShapes.pill,
                ),
                child: Icon(
                  unread
                      ? Icons.mark_email_unread_outlined
                      : Icons.mail_outline_rounded,
                  size: 19,
                  color:
                      unread ? AppColor.pitchGreen : AppColor.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 14,
                              fontWeight:
                                  unread ? FontWeight.w800 : FontWeight.w600,
                              color: AppColor.onSurface,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8, left: 4),
                            decoration: const ShapeDecoration(
                              color: AppColor.pitchGreen,
                              shape: CircleBorder(),
                            ),
                          ),
                      ],
                    ),
                    if (data.body.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        data.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 12,
                          height: 1.7,
                          color: AppColor.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (data.createdAtDate != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        formatOrderDate(data.createdAtDate),
                        style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 11,
                          color: AppColor.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded,
                  size: 20, color: AppColor.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
