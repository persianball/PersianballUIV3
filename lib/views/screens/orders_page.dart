// lib/views/screens/orders_page.dart
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_breakpoints.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/views/screens/order_detail_page.dart';
import 'package:marketky/models/payment_models.dart';
import 'package:marketky/services/payment_service.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/views/widgets/motion.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  PaymentsResponse? _data;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String? _nextUrl;
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fetch();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool loadMore = false}) async {
    setState(() {
      if (!loadMore) _loading = true;
      if (loadMore) _loadingMore = true;
      _error = null;
    });
    try {
      final res = await PaymentService.fetchPayments(
          nextPageUrl: loadMore ? _nextUrl : null);
      setState(() {
        if (loadMore && _data != null) {
          _data = PaymentsResponse(
            count: res.count,
            next: res.next,
            previous: res.previous,
            results: [..._data!.results, ...res.results],
          );
        } else {
          _data = res;
        }
        _nextUrl = res.next;
        _loading = false;
        _loadingMore = false;
      });
      // فقط لود اول کل لیست fade-in می‌شود؛ صفحه‌ی بعدی نباید آیتم‌های
      // از قبل نمایش‌داده‌شده را دوباره محو/ظاهر کند (همان چشمک‌زدن هنگام
      // رسیدن به انتهای اسکرول).
      if (!loadMore) _fadeCtrl.forward(from: 0);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_nextUrl == null || _loadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // near bottom, load next page
      final next = _nextUrl;
      // _nextUrl = null; // prevent duplicate calls
      if (next != null) {
        _fetch(loadMore: true);
        _nextUrl = null;
      }
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'success':
        return Colors.green.shade600;
      case 'paid':
        return Colors.green.shade600;
      case 'pending':
        return Colors.orange.shade700;
      case 'failed':
      default:
        return Colors.red.shade600;
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'success':
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_bottom;
      case 'failed':
      default:
        return Icons.error_outline;
    }
  }

  Widget _buildItem(PaymentItem item) {
    final statusClr = _statusColor(item.status);
    final priceText = '${thousandSeparator(item.price)} تومان';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: ShapeDecoration(
            color: AppColor.surfaceContainer,
            shape: AppShapes.border(AppShapes.rLg),
            shadows: AppColor.cardShadow,
          ),
      child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrderDetailPage(payment: item),
              ),
            ),
            child: Padding(
              // دسکتاپ: کارت کمی جادارتر
              padding: EdgeInsets.all(
                  AppBreakpoints.isDesktop(context) ? 18 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ردیف اول: وضعیت (مهم‌ترین اطلاعات) و شماره سفارش
                  Row(
                    children: [
                      Icon(_statusIcon(item.status),
                          color: statusClr, size: 20),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusClr.withOpacity(0.12),
                        ),
                        child: Text(
                          _statusFa(item.status),
                          style: TextStyle(
                            fontFamily: 'Estedad',
                            color: statusClr,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right,
                          size: 18, color: AppColor.onSurfaceVariant),
                      Text(
                        'سفارش #${item.id}',
                        style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 12,
                          color: AppColor.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // ردیف دوم: مبلغ، برجسته‌ترین عدد کارت
                  Text(
                    priceText,
                    style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColor.goldEnd,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(height: 1, color: AppColor.outlineVariantDark),
                  const SizedBox(height: 8),
                  // ردیف سوم: کد پیگیری، اطلاعات کم‌اهمیت‌تر
                  Row(
                    children: [
                      Icon(Icons.confirmation_number_outlined,
                          size: 15, color: AppColor.onSurfaceVariant),
                      const SizedBox(width: 6),
                      const Text(
                        'کد پیگیری',
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 12,
                          color: AppColor.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.trackingCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColor.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildLoadMoreFooter() {
    if (!_loadingMore) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColor.goldEnd,
          ),
        ),
      ),
    );
  }

  String _statusFa(String s) {
    switch (s.toLowerCase()) {
      case 'success':
      case 'paid':
        return 'موفق';
      case 'pending':
        return 'در انتظار';
      case 'failed':
      default:
        return 'ناموفق';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.obsidianBg,
        appBar: AppBar(
          title: const Text('سفارش‌های من',
              style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface)),
          backgroundColor: AppColor.obsidianBg,
          foregroundColor: AppColor.onSurface,
          elevation: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColor.goldEnd))
            : _error != null
                ? _ErrorView(message: _error!, onRetry: () => _fetch())
                : RefreshIndicator(
                    color: AppColor.goldEnd,
                    onRefresh: () async {
                      _nextUrl = null;
                      await _fetch();
                    },
                    child: FadeTransition(
                      // فقط لود اول کل لیست fade-in می‌شود (توضیح در _fetch)
                      opacity: _fadeCtrl,
                      child: _centerOnDesktop(ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        // +۱ برای هدر «مجموع سفارش‌ها» و در صورت لود صفحه‌ی
                        // بعدی، +۱ دیگر برای اسپینر کوچک انتهای لیست
                        itemCount:
                            (_data?.results.length ?? 0) + 1 + (_loadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Text(
                                'مجموع سفارش‌ها: ${_data?.count ?? 0}',
                                style: const TextStyle(
                                    fontFamily: 'Estedad',
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.onSurface),
                              ),
                            );
                          }
                          final itemsCount = _data?.results.length ?? 0;
                          if (index == itemsCount + 1) {
                            return _buildLoadMoreFooter();
                          }
                          final item = _data!.results[index - 1];
                          return FadeSlideIn(
                            delay:
                                Duration(milliseconds: 45 * ((index - 1) % 6)),
                            child: _buildItem(item),
                          );
                        },
                      )),
                    ),
                  ),
      ),
    );
  }

  /// دسکتاپ: لیست سفارش‌ها وسط‌چین با حداکثر عرض ۹۰۰؛ موبایل بی‌اثر.
  /// کنترلر اسکرول و لود بی‌نهایت دست‌نخورده می‌مانند.
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 40, color: AppColor.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Estedad', color: AppColor.onSurfaceVariant)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.goldEnd, shape: AppShapes.pill),
            child: const Text('تلاش مجدد',
                style: TextStyle(fontFamily: 'Estedad', color: AppColor.onGold)),
          ),
        ],
      ),
    );
  }
}
