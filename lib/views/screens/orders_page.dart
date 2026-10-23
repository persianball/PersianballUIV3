// lib/views/screens/orders_page.dart
//
// سفارش‌های کاربر از /v2/order/order/.
//
// پیش‌تر این صفحه از /v1/payment/payments/ می‌خواند که فقط شناسه‌ی پرداخت،
// وضعیت و مبلغ دارد. مشکل اصلی این بود که شناسه‌ی پرداخت با شناسه‌ی سفارش
// یکی نیست (پرداختِ ۱۹۸۲ ↔ سفارشِ ۲۰۹۷)، پس با آن نمی‌شد جزئیات سفارش را
// گرفت و صفحه‌ی جزئیات مجبور بود داده‌ی ساختگی نشان دهد.
import 'package:flutter/material.dart';

import 'package:persian_ball/constant/app_breakpoints.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:persian_ball/constant/urls.dart';
import 'package:persian_ball/models/order_models.dart';
import 'package:persian_ball/services/order_service.dart';
import 'package:persian_ball/utils/ThousandsFormatter.dart';
import 'package:persian_ball/utils/jalali_date.dart';
import 'package:persian_ball/views/screens/order_detail_page.dart';
import 'package:persian_ball/views/widgets/motion.dart';
import 'package:persian_ball/views/widgets/shimmer.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final List<Order> _orders = [];
  int _count = 0;
  String? _nextUrl;

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetch();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool loadMore = false}) async {
    if (!mounted) return;
    setState(() {
      if (loadMore) {
        _loadingMore = true;
      } else {
        _loading = _orders.isEmpty;
        _error = null;
      }
    });
    try {
      final res = await OrderService.fetchOrders(
          nextUrl: loadMore ? _nextUrl : null);
      if (!mounted) return;
      setState(() {
        if (!loadMore) _orders.clear();
        // اگر وسطِ ورق زدن سفارشِ تازه‌ای ثبت شود، مرزِ صفحه‌ها جابه‌جا می‌شود
        // و یک سفارش ممکن است دوباره بیاید.
        final seen = {for (final o in _orders) o.id};
        _orders.addAll(res.results.where((o) => seen.add(o.id)));
        _count = res.count;
        _nextUrl = res.next;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        // اگر قبلاً چیزی نشان داده‌ایم، خطای صفحه‌ی بعد نباید لیست را پاک کند
        if (_orders.isEmpty) {
          _error = e.toString().replaceFirst('Exception: ', '');
        }
      });
    }
  }

  void _onScroll() {
    if (_nextUrl == null || _loadingMore || _loading) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
      _fetch(loadMore: true);
    }
  }

  void _openDetail(Order order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        // نسخه‌ی لیست را همراه می‌فرستیم تا صفحه‌ی جزئیات فوراً پر باز شود
        // و فقط در پس‌زمینه تازه شود.
        builder: (_) => OrderDetailPage(orderId: order.id, preview: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.obsidianBg,
      appBar: AppBar(
        title: const Text('سفارش‌های من',
            style: TextStyle(
                fontFamily: 'Estedad',
                fontWeight: FontWeight.w700,
                color: AppColor.onSurface)),
        backgroundColor: AppColor.obsidianBg,
        foregroundColor: AppColor.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _body(),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      // اسکلتون هم مثل لیستِ واقعی وسط‌چین می‌شود، وگرنه لحظه‌ی رسیدنِ
      // داده چیدمان می‌پرد.
      return KeyedSubtree(
        key: const ValueKey('skeleton'),
        child: _centerOnDesktop(const _OrdersSkeleton()),
      );
    }
    if (_error != null) {
      return KeyedSubtree(
        key: const ValueKey('error'),
        child: _ErrorView(message: _error!, onRetry: () => _fetch()),
      );
    }
    if (_orders.isEmpty) {
      return KeyedSubtree(
        key: const ValueKey('empty'),
        child: _EmptyView(onRetry: () => _fetch()),
      );
    }
    return KeyedSubtree(
      key: const ValueKey('list'),
      child: RefreshIndicator(
        color: AppColor.pitchGreen,
        onRefresh: () async {
          _nextUrl = null;
          await _fetch();
        },
        child: _centerOnDesktop(
          ListView.builder(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: _orders.length + 1 + (_loadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == 0) return _header();
              if (index == _orders.length + 1) return _loadMoreFooter();
              final order = _orders[index - 1];
              return FadeSlideIn(
                delay: Duration(milliseconds: 45 * ((index - 1) % 6)),
                child: _OrderCard(order: order, onTap: () => _openDetail(order)),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_rounded,
                size: 18, color: AppColor.pitchGreen),
            const SizedBox(width: 8),
            Text('مجموع سفارش‌ها: $_count',
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontWeight: FontWeight.w700,
                    color: AppColor.onSurface)),
          ],
        ),
      );

  Widget _loadMoreFooter() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColor.pitchGreen),
          ),
        ),
      );

  /// دسکتاپ: لیست وسط‌چین با حداکثر عرض ۹۰۰؛ موبایل بی‌اثر.
  Widget _centerOnDesktop(Widget child) {
    if (!AppBreakpoints.isDesktop(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: child,
      ),
    );
  }
}

// ---------- کارت سفارش ----------

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  static Color statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.paid:
      case OrderStatus.delivered:
        return AppColor.successDark;
      case OrderStatus.sent:
        return AppColor.pitchGreen;
      case OrderStatus.pending:
      case OrderStatus.waitForAdmin:
        return AppColor.warning;
      case OrderStatus.failed:
      case OrderStatus.canceled:
        return AppColor.danger;
      case OrderStatus.unknown:
        return AppColor.onSurfaceVariant;
    }
  }

  static String _abs(String path) {
    if (path.startsWith('http')) return path;
    final base = URLs.baseUrl.endsWith('/')
        ? URLs.baseUrl.substring(0, URLs.baseUrl.length - 1)
        : URLs.baseUrl;
    return '$base${path.startsWith('/') ? '' : '/'}$path';
  }

  @override
  Widget build(BuildContext context) {
    final color = statusColor(order.status);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: PressableScale(
        onTap: onTap,
        hoverScale: 1.01,
        child: Container(
          padding: EdgeInsets.all(
              AppBreakpoints.isDesktop(context) ? 18 : 14),
          decoration: ShapeDecoration(
            color: AppColor.surfaceContainer,
            shape: AppShapes.border(AppShapes.rLg),
            shadows: AppColor.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: ShapeDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: AppShapes.pill,
                    ),
                    child: Text(order.status.label,
                        style: TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ),
                  const SizedBox(width: 8),
                  Text(formatOrderDate(order.createdAt, withTime: false),
                      style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 12,
                          color: AppColor.onSurfaceVariant)),
                  const Spacer(),
                  Text('#${order.id}',
                      style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 12,
                          color: AppColor.onSurfaceVariant)),
                  const Icon(Icons.chevron_left_rounded,
                      size: 20, color: AppColor.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 12),
              // پیش‌نمایشِ اقلام: کاربر بدون باز کردن سفارش می‌فهمد چه خریده
              if (order.items.isNotEmpty) _itemsPreview(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('${thousandSeparator(order.price.payable)} تومان',
                      style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColor.pitchGreen)),
                  const Spacer(),
                  Icon(Icons.local_shipping_outlined,
                      size: 15, color: AppColor.onSurfaceVariant),
                  const SizedBox(width: 5),
                  Text(order.deliveryLabel,
                      style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 12,
                          color: AppColor.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemsPreview() {
    const int maxThumbs = 3;
    final thumbs = order.items.take(maxThumbs).toList();
    final extra = order.items.length - thumbs.length;
    return Row(
      children: [
        for (final line in thumbs)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ClipRRect(
              borderRadius: AppShapes.radius(AppShapes.rSm),
              child: SizedBox(
                width: 46,
                height: 46,
                child: line.image == null || line.image!.isEmpty
                    ? Container(
                        color: AppColor.cardMuted,
                        child: Icon(
                            line.isCourse
                                ? Icons.school_rounded
                                : Icons.image_outlined,
                            size: 18,
                            color: AppColor.lineStrong))
                    : Image.network(_abs(line.image!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: AppColor.cardMuted,
                            child: const Icon(Icons.broken_image_outlined,
                                size: 18, color: AppColor.lineStrong))),
              ),
            ),
          ),
        if (extra > 0)
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: AppColor.cardMuted,
              shape: AppShapes.border(AppShapes.rSm),
            ),
            child: Text('+$extra',
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColor.onSurfaceVariant)),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            order.items.first.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontFamily: 'Estedad',
                fontSize: 13,
                height: 1.6,
                color: AppColor.onSurface),
          ),
        ),
      ],
    );
  }
}

// ---------- حالت‌های خالی/خطا/بارگذاری ----------

class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Bone(width: 150, height: 16),
          ),
          for (int i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: ShapeDecoration(
                  color: AppColor.surfaceContainer,
                  shape: AppShapes.border(AppShapes.rLg),
                  shadows: AppColor.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(children: [
                      Bone(width: 84, height: 22, radius: 999),
                      SizedBox(width: 8),
                      Bone(width: 96, height: 13),
                      Spacer(),
                      Bone(width: 44, height: 13),
                    ]),
                    SizedBox(height: 14),
                    Row(children: [
                      Bone(width: 46, height: 46, radius: 10),
                      SizedBox(width: 8),
                      Bone(width: 46, height: 46, radius: 10),
                      SizedBox(width: 10),
                      Expanded(child: Bone(height: 14)),
                    ]),
                    SizedBox(height: 14),
                    Row(children: [
                      Bone(width: 132, height: 18),
                      Spacer(),
                      Bone(width: 70, height: 13),
                    ]),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 52, color: AppColor.lineStrong),
            const SizedBox(height: 14),
            const Text('هنوز سفارشی ثبت نکرده‌اید',
                style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColor.onSurface)),
            const SizedBox(height: 8),
            const Text('سفارش‌های شما بعد از خرید اینجا نمایش داده می‌شوند.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 12,
                    color: AppColor.onSurfaceVariant)),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColor.pitchGreen,
                side: const BorderSide(color: AppColor.pitchGreen),
                shape: AppShapes.pill,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              label: const Text('بارگذاری مجدد',
                  style: TextStyle(
                      fontFamily: 'Estedad', fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final bool needsLogin = message.contains('ورود');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(needsLogin ? Icons.lock_outline_rounded : Icons.wifi_off_rounded,
                size: 44, color: AppColor.lineStrong),
            const SizedBox(height: 14),
            Text(
                needsLogin
                    ? 'برای دیدن سفارش‌ها وارد حساب کاربری شوید'
                    : message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 14,
                    color: AppColor.onSurfaceVariant)),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.pitchGreen,
                  foregroundColor: Colors.white,
                  shape: AppShapes.pill,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12)),
              child: const Text('تلاش مجدد',
                  style: TextStyle(
                      fontFamily: 'Estedad', fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
