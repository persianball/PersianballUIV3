// lib/views/screens/orders_page.dart
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/payment_models.dart';
import 'package:marketky/services/payment_service.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  PaymentsResponse? _data;
  bool _loading = true;
  String? _error;
  String? _nextUrl;
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
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
      _error = null;
    });
    try {
      final res = await PaymentService.fetchPayments(nextPageUrl: loadMore ? _nextUrl : null);
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
      });
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onScroll() {
    if (_nextUrl == null) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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
    return FadeTransition(
      opacity: _fadeCtrl,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: statusClr.withOpacity(.12),
            child: Icon(_statusIcon(item.status), color: statusClr),
          ),
          title: Text(
            'کد پیگیری: ${item.trackingCode} , ${item.id}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusClr.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusFa(item.status),
                    style: TextStyle(color: statusClr, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.price_change, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(priceText, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          trailing:null,
          onTap: () {
            // Optionally navigate to a payment detail page later
          },
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('سفارش‌های من', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorView(message: _error!, onRetry: () => _fetch())
                : RefreshIndicator(
                    color: AppColor.primary,
                    onRefresh: () async {
                      _nextUrl = null;
                      await _fetch();
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: (_data?.results.length ?? 0) + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              'مجموع سفارش‌ها: ${_data?.count ?? 0}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          );
                        }
                        final item = _data!.results[index - 1];
                        return _buildItem(item);
                      },
                    ),
                  ),
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
          const Icon(Icons.wifi_off, size: 40, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary),
            child: const Text('تلاش مجدد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}