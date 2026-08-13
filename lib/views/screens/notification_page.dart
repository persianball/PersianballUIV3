// lib/views/screens/notification_page.dart
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/services/notification_service.dart';
import 'package:marketky/views/widgets/page_container.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<AppNotification> _items = [];
  Set<int> _read = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await NotificationService.fetch();
    final read = await NotificationService.readIds();
    if (!mounted) return;
    setState(() {
      _items = items;
      _read = read;
      _loading = false;
    });
  }

  IconData _iconFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.order:
        return Icons.local_shipping_outlined;
      case AppNotificationType.promo:
        return Icons.local_offer_outlined;
      case AppNotificationType.system:
        return Icons.shield_outlined;
    }
  }

  Color _colorFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.order:
        return AppColor.primary;
      case AppNotificationType.promo:
        return Colors.orange.shade700;
      case AppNotificationType.system:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          title: const Text('اعلان‌ها',
              style: TextStyle(fontFamily: 'Estedad', fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () async {
                await NotificationService.markAllRead();
                await _load();
              },
              child: const Text('خواندن همه',
                  style: TextStyle(fontFamily: 'Estedad', fontSize: 12)),
            ),
          ],
        ),
        body: PageContainer(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  color: AppColor.primary,
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (NotificationService.isMock) _mockBanner(),
                      if (_items.isEmpty) _empty() else ..._items.map(_tile),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _mockBanner() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          border: Border.all(color: Colors.amber.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: Colors.amber.shade800),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'اعلان‌ها نمایشی است؛ برای push واقعی به endpoint اعلان و FCM نیاز است.',
                style: TextStyle(fontFamily: 'Estedad', fontSize: 11),
              ),
            ),
          ],
        ),
      );

  Widget _empty() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.notifications_none,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('اعلانی ندارید',
                style: TextStyle(fontFamily: 'Estedad')),
          ],
        ),
      );

  Widget _tile(AppNotification n) {
    final isRead = _read.contains(n.id);
    final color = _colorFor(n.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : AppColor.primarySoft.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await NotificationService.markRead(n.id);
            if (!mounted) return;
            await _load();
            if (!mounted) return;
            if (n.route != null) Navigator.of(context).pushNamed(n.route!);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconFor(n.type), size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                fontFamily: 'Estedad',
                                fontSize: 13,
                                fontWeight:
                                    isRead ? FontWeight.w600 : FontWeight.w800,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColor.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(n.body,
                          style: const TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 12,
                              height: 1.6)),
                      const SizedBox(height: 6),
                      Text(n.createdAt,
                          style: TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 10,
                              color: Colors.grey.shade500)),
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
