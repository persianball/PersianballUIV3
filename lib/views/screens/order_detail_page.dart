// lib/views/screens/order_detail_page.dart
//
// جزئیات یک سفارش از /v2/order/order/<id>/ — اقلامِ واقعی، خطِ زمانیِ
// وضعیت، آدرسِ گیرنده و صورتحساب.
//
// پیش‌تر این صفحه داده‌ی ماک نشان می‌داد (اقلامِ ساختگی، آدرسِ ثابت، مالیاتِ
// حساب‌شده از روی درصد) چون endpoint جزئیات وجود نداشت.
import 'package:flutter/material.dart';

import 'package:marketky/constant/app_breakpoints.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/constant/urls.dart';
import 'package:marketky/models/order_models.dart';
import 'package:marketky/services/order_service.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/utils/jalali_date.dart';
import 'package:marketky/views/widgets/motion.dart';
import 'package:marketky/views/widgets/shimmer.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.orderId, this.preview});

  final int orderId;

  /// اگر از صفحه‌ی لیست آمده‌ایم، همان سفارش را داریم و می‌شود صفحه را
  /// فوراً پر نشان داد و در پس‌زمینه تازه کرد — به‌جای اسکلتونِ بی‌مورد.
  final Order? preview;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Order? _order;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _order = widget.preview;
    _loading = widget.preview == null;
    _load();
  }

  Future<void> _load() async {
    if (_order == null && mounted) setState(() => _loading = true);
    try {
      final order = await OrderService.fetchOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // اگر نسخه‌ی لیست را داریم، خطای تازه‌سازی نباید صفحه را خالی کند
        _error = _order == null ? _messageOf(e) : null;
        _loading = false;
      });
    }
  }

  static String _messageOf(Object e) {
    final s = e.toString().replaceFirst('Exception: ', '');
    return s.isEmpty ? 'خطای ناشناخته' : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.obsidianBg,
      appBar: AppBar(
        backgroundColor: AppColor.obsidianBg,
        foregroundColor: AppColor.onSurface,
        elevation: 0,
        title: Text(
          'سفارش #${widget.orderId}',
          style: const TextStyle(
              fontFamily: 'Estedad',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColor.onSurface),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_order != null) {
      return KeyedSubtree(
        key: const ValueKey('content'),
        child: RefreshIndicator(
          color: AppColor.pitchGreen,
          onRefresh: _load,
          child: _content(_order!),
        ),
      );
    }
    if (_loading) {
      return const KeyedSubtree(
          key: ValueKey('skeleton'), child: _OrderDetailSkeleton());
    }
    return KeyedSubtree(
      key: const ValueKey('error'),
      child: _errorView(_error ?? 'سفارش پیدا نشد'),
    );
  }

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 48, color: AppColor.lineStrong),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 14,
                    color: AppColor.onSurfaceVariant)),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColor.pitchGreen,
                side: const BorderSide(color: AppColor.pitchGreen),
                shape: AppShapes.pill,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              label: const Text('تلاش مجدد',
                  style: TextStyle(
                      fontFamily: 'Estedad', fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- چیدمان ----------

  Widget _content(Order o) {
    final bool desktop = AppBreakpoints.isDesktop(context);

    // ورودِ پلکانی بخش‌ها؛ هر بخش کمی بعد از بخشِ بالایی می‌آید
    int step = 0;
    Widget stagger(Widget child) => FadeSlideIn(
          delay: Duration(milliseconds: 70 * step++),
          child: child,
        );

    if (desktop) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: CenteredContent(
          maxWidth: 1080,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              stagger(_headerCard(o)),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        stagger(_timelineCard(o)),
                        const SizedBox(height: 16),
                        stagger(_itemsCard(o)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 340,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        stagger(_invoiceCard(o)),
                        if (o.needsShipping && !o.address.isEmpty) ...[
                          const SizedBox(height: 16),
                          stagger(_addressCard(o)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        stagger(_headerCard(o)),
        const SizedBox(height: 14),
        stagger(_timelineCard(o)),
        const SizedBox(height: 14),
        stagger(_itemsCard(o)),
        const SizedBox(height: 14),
        if (o.needsShipping && !o.address.isEmpty) ...[
          stagger(_addressCard(o)),
          const SizedBox(height: 14),
        ],
        stagger(_invoiceCard(o)),
      ],
    );
  }

  // ---------- کارت‌ها ----------

  static Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: AppColor.surfaceContainer,
        shape: AppShapes.border(AppShapes.rLg),
        shadows: AppColor.cardShadow,
      ),
      child: child,
    );
  }

  static Widget _sectionTitle(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColor.pitchGreen),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontFamily: 'Estedad',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColor.onSurface)),
      ],
    );
  }

  /// سربرگ: وضعیت، تاریخ، کد رهگیری و مبلغ نهایی
  Widget _headerCard(Order o) {
    final color = _statusColor(o.status);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusChip(status: o.status, color: color),
              const Spacer(),
              Text(formatOrderDate(o.createdAt),
                  style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 12,
                      color: AppColor.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaPill(
                  icon: Icons.local_shipping_outlined,
                  label: 'روش ارسال',
                  value: o.deliveryLabel),
              _MetaPill(
                  icon: Icons.inventory_2_outlined,
                  label: 'تعداد اقلام',
                  value: '${o.itemCount}'),
              // کد رهگیری فقط بعد از پرداخت ساخته می‌شود؛ برای سفارشِ
              // پرداخت‌نشده سرور رشته‌ی "None" می‌فرستد که نباید نشان داده شود.
              if (o.trackingCode != null)
                _MetaPill(
                    icon: Icons.qr_code_2_rounded,
                    label: 'کد رهگیری',
                    value: o.trackingCode!,
                    selectable: true),
            ],
          ),
          const Divider(height: 26, color: AppColor.outlineVariantDark),
          Row(
            children: [
              const Text('مبلغ پرداختی',
                  style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 13,
                      color: AppColor.onSurfaceVariant)),
              const Spacer(),
              _AnimatedPrice(value: o.price.payable, fontSize: 19),
            ],
          ),
        ],
      ),
    );
  }

  /// خطِ زمانیِ وضعیت سفارش
  Widget _timelineCard(Order o) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('وضعیت سفارش', Icons.timeline_rounded),
          const SizedBox(height: 18),
          if (o.status.isTerminalFailure)
            _failedNotice(o)
          else
            _OrderTimeline(currentIndex: o.status.timelineIndex),
        ],
      ),
    );
  }

  Widget _failedNotice(Order o) {
    final bool canceled = o.status == OrderStatus.canceled;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ShapeDecoration(
        color: AppColor.danger.withValues(alpha: 0.08),
        shape: AppShapes.border(AppShapes.rLg,
            side: BorderSide(color: AppColor.danger.withValues(alpha: 0.35))),
      ),
      child: Row(
        children: [
          Icon(canceled ? Icons.block_rounded : Icons.error_outline_rounded,
              color: AppColor.danger, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              canceled
                  ? 'این سفارش لغو شده است.'
                  : 'پرداخت این سفارش ناموفق بود و سفارش ثبت نهایی نشد.',
              style: const TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 13,
                  height: 1.7,
                  color: AppColor.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  /// اقلام سفارش
  Widget _itemsCard(Order o) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle('اقلام سفارش', Icons.shopping_bag_outlined),
              const Spacer(),
              Text('${o.items.length} قلم',
                  style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 12,
                      color: AppColor.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 6),
          if (o.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('قلمی برای این سفارش ثبت نشده است.',
                  style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 13,
                      color: AppColor.onSurfaceVariant)),
            )
          else
            for (int i = 0; i < o.items.length; i++)
              FadeSlideIn(
                delay: Duration(milliseconds: 60 * i),
                child: _OrderLineTile(
                  line: o.items[i],
                  showDivider: i != o.items.length - 1,
                ),
              ),
        ],
      ),
    );
  }

  /// آدرس گیرنده
  Widget _addressCard(Order o) {
    final a = o.address;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle('آدرس تحویل', Icons.location_on_outlined),
              if (a.name != null) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: ShapeDecoration(
                    color: AppColor.pitchGreen.withValues(alpha: 0.1),
                    shape: AppShapes.pill,
                  ),
                  child: Text(a.name!,
                      style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColor.pitchGreen)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            a.line.isEmpty ? a.raw : a.line,
            style: const TextStyle(
                fontFamily: 'Estedad',
                fontSize: 13,
                height: 1.9,
                color: AppColor.onSurface),
          ),
          if (a.postalCode != null || a.receiverPhone != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (a.postalCode != null)
                  _MetaPill(
                      icon: Icons.markunread_mailbox_outlined,
                      label: 'کد پستی',
                      value: a.postalCode!,
                      selectable: true),
                if (a.receiverPhone != null)
                  _MetaPill(
                      icon: Icons.phone_iphone_rounded,
                      label: 'موبایل گیرنده',
                      value: a.receiverPhone!,
                      selectable: true),
                if (a.homePhone != null)
                  _MetaPill(
                      icon: Icons.call_outlined,
                      label: 'تلفن ثابت',
                      value: a.homePhone!,
                      selectable: true),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// صورتحساب
  Widget _invoiceCard(Order o) {
    final p = o.price;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('صورتحساب', Icons.receipt_long_outlined),
          const SizedBox(height: 14),
          _InvoiceRow(label: 'جمع اقلام', value: p.subtotal),
          if (p.discount > 0)
            _InvoiceRow(
                label: 'تخفیف', value: -p.discount, color: AppColor.danger),
          if (p.nat > 0) _InvoiceRow(label: 'مالیات', value: p.nat),
          _InvoiceRow(
            label: 'هزینه ارسال',
            value: p.shipping,
            // ارسالِ رایگان با «۰ تومان» گنگ است؛ صریح نوشته می‌شود.
            freeLabel: p.shipping == 0 ? 'رایگان' : null,
            color: p.shipping == 0 ? AppColor.pitchGreen : null,
          ),
          const Divider(height: 24, color: AppColor.outlineVariantDark),
          Row(
            children: [
              const Text('مبلغ نهایی',
                  style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColor.onSurface)),
              const Spacer(),
              _AnimatedPrice(value: p.payable, fontSize: 17),
            ],
          ),
        ],
      ),
    );
  }

  static Color _statusColor(OrderStatus s) {
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
}

// ---------- اجزای کوچک ----------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});

  final OrderStatus status;
  final Color color;

  IconData get _icon {
    switch (status) {
      case OrderStatus.paid:
        return Icons.check_circle_rounded;
      case OrderStatus.delivered:
        return Icons.inventory_rounded;
      case OrderStatus.sent:
        return Icons.local_shipping_rounded;
      case OrderStatus.pending:
      case OrderStatus.waitForAdmin:
        return Icons.hourglass_bottom_rounded;
      case OrderStatus.failed:
        return Icons.error_outline_rounded;
      case OrderStatus.canceled:
        return Icons.block_rounded;
      case OrderStatus.unknown:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.12),
        shape: AppShapes.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(status.label,
              style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.value,
    this.selectable = false,
  });

  final IconData icon;
  final String label;
  final String value;

  /// کد رهگیری و کد پستی را کاربر باید بتواند کپی کند
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final text = Text(value,
        style: const TextStyle(
            fontFamily: 'Estedad',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColor.onSurface));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: ShapeDecoration(
        color: AppColor.cardMuted,
        shape: AppShapes.border(AppShapes.rMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColor.onSurfaceVariant),
          const SizedBox(width: 6),
          Text('$label: ',
              style: const TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 12,
                  color: AppColor.onSurfaceVariant)),
          selectable ? SelectionArea(child: text) : text,
        ],
      ),
    );
  }
}

/// خطِ زمانیِ افقی (دسکتاپ) / عمودی‌نما با نقطه‌های متحرک
class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    // در RTL فرزندِ اول سمت راست می‌نشیند، پس مرحله‌ی «ثبت سفارش»
    // خودبه‌خود اول از راست می‌آید و نیازی به وارونه کردن نیست.
    return Row(
      children: [
        for (int i = 0; i < kOrderTimeline.length; i++) ...[
          if (i != 0)
            Expanded(
              child: _TimelineBar(filled: i <= currentIndex),
            ),
          _TimelineDot(
            label: kOrderTimeline[i],
            done: i < currentIndex,
            active: i == currentIndex,
          ),
        ],
      ],
    );
  }
}

class _TimelineBar extends StatelessWidget {
  const _TimelineBar({required this.filled});
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: LayoutBuilder(
        builder: (context, constraints) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: filled ? 1 : 0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          // Stack با AlignmentDirectional.topStart می‌چیند، پس نوارِ سبز
          // در RTL از راست پر می‌شود — هم‌جهت با ترتیبِ مراحل.
          builder: (context, t, _) => Stack(
            children: [
              Container(height: 3, color: AppColor.cardMuted),
              SizedBox(
                width: constraints.maxWidth * t,
                child: Container(height: 3, color: AppColor.pitchGreen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({
    required this.label,
    required this.done,
    required this.active,
  });

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final bool reached = done || active;
    final Color color = reached ? AppColor.pitchGreen : AppColor.lineStrong;
    return SizedBox(
      width: 74,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: reached ? 1 : 0.85),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, t, child) =>
                Transform.scale(scale: t, child: child),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: reached ? AppColor.pitchGreen : AppColor.cardMuted,
                // مرحله‌ی جاری با هاله مشخص می‌شود تا در یک نگاه پیدا شود
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColor.pitchGreen.withValues(alpha: 0.28),
                          blurRadius: 0,
                          spreadRadius: 4,
                        )
                      ]
                    : null,
              ),
              child: Icon(
                done ? Icons.check_rounded : Icons.circle,
                size: done ? 15 : 8,
                color: reached ? Colors.white : AppColor.lineStrong,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Estedad',
              fontSize: 11,
              height: 1.4,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              color: reached ? color : AppColor.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderLineTile extends StatelessWidget {
  const _OrderLineTile({required this.line, required this.showDivider});

  final OrderLine line;
  final bool showDivider;

  static String _abs(String path) {
    if (path.startsWith('http')) return path;
    final base = URLs.baseUrl.endsWith('/')
        ? URLs.baseUrl.substring(0, URLs.baseUrl.length - 1)
        : URLs.baseUrl;
    return '$base${path.startsWith('/') ? '' : '/'}$path';
  }

  Color? get _swatch {
    final rgb = line.colorRgb;
    if (rgb == null || rgb.isEmpty) return null;
    final v = int.tryParse(rgb.replaceAll('#', ''), radix: 16);
    return v == null ? null : Color(0xFF000000 | v);
  }

  @override
  Widget build(BuildContext context) {
    final swatch = _swatch;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppShapes.radius(AppShapes.rMd),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: line.image == null || line.image!.isEmpty
                      ? Container(
                          color: AppColor.cardMuted,
                          child: Icon(
                              line.isCourse
                                  ? Icons.school_rounded
                                  : Icons.image_not_supported_outlined,
                              color: AppColor.lineStrong),
                        )
                      : Image.network(
                          _abs(line.image!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColor.cardMuted,
                            child: const Icon(Icons.broken_image_outlined,
                                color: AppColor.lineStrong),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.title.isEmpty ? 'بدون عنوان' : line.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.6,
                          color: AppColor.onSurface),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (line.size != null && line.size!.isNotEmpty)
                          _tag('سایز ${line.size}'),
                        if (line.color != null && line.color!.isNotEmpty)
                          _colorTag(line.color!, swatch),
                        if (line.location != null && line.location!.isNotEmpty)
                          _tag('مکان: ${line.location}'),
                        if (line.time != null && line.time!.isNotEmpty)
                          _tag(line.time!),
                        _tag('تعداد ${line.quantity}'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '${thousandSeparator(line.lineTotal)} تومان',
                          style: const TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColor.pitchGreen),
                        ),
                        if (line.hasDiscount) ...[
                          const SizedBox(width: 8),
                          Text(
                            thousandSeparator(line.unitPrice * line.quantity),
                            style: const TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 12,
                              color: AppColor.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: ShapeDecoration(
                              color: AppColor.danger,
                              shape: AppShapes.pill,
                            ),
                            child: Text('${line.discountPercentage}٪',
                                style: const TextStyle(
                                    fontFamily: 'Estedad',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColor.outlineVariantDark),
      ],
    );
  }

  static Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: ShapeDecoration(
          color: AppColor.cardMuted,
          shape: AppShapes.pill,
        ),
        child: Text(text,
            style: const TextStyle(
                fontFamily: 'Estedad',
                fontSize: 11,
                color: AppColor.onSurfaceVariant)),
      );

  static Widget _colorTag(String name, Color? swatch) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: ShapeDecoration(
          color: AppColor.cardMuted,
          shape: AppShapes.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (swatch != null) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: swatch,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColor.lineStrong, width: 0.5),
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(name,
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 11,
                    color: AppColor.onSurfaceVariant)),
          ],
        ),
      );
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({
    required this.label,
    required this.value,
    this.color,
    this.freeLabel,
  });

  final String label;
  final int value;
  final Color? color;
  final String? freeLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 13,
                  color: AppColor.onSurfaceVariant)),
          const Spacer(),
          Text(
            freeLabel ?? '${thousandSeparator(value)} تومان',
            style: TextStyle(
                fontFamily: 'Estedad',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color ?? AppColor.onSurface),
          ),
        ],
      ),
    );
  }
}

/// مبلغ با شمارشِ نرم از صفر — تأکید بصری روی عددِ مهمِ صفحه
class _AnimatedPrice extends StatelessWidget {
  const _AnimatedPrice({required this.value, this.fontSize = 16});

  final int value;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '${thousandSeparator(v.round())} تومان',
        style: TextStyle(
          fontFamily: 'Estedad',
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: AppColor.pitchGreen,
        ),
      ),
    );
  }
}

/// اسکلتونِ صفحه در حالِ بارگذاری — ساختارش عمداً شبیهِ صفحه‌ی واقعی است
/// تا وقتی داده رسید، چیدمان نپَرَد.
class _OrderDetailSkeleton extends StatelessWidget {
  const _OrderDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget card(Widget child) => Container(
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: AppColor.surfaceContainer,
            shape: AppShapes.border(AppShapes.rLg),
            shadows: AppColor.cardShadow,
          ),
          child: child,
        );

    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(children: [
                Bone(width: 110, height: 26, radius: 999),
                Spacer(),
                Bone(width: 130, height: 14),
              ]),
              SizedBox(height: 16),
              Row(children: [
                Bone(width: 120, height: 32),
                SizedBox(width: 10),
                Bone(width: 96, height: 32),
              ]),
              SizedBox(height: 22),
              Row(children: [
                Bone(width: 88, height: 14),
                Spacer(),
                Bone(width: 140, height: 20),
              ]),
            ],
          )),
          const SizedBox(height: 14),
          card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Bone(width: 100, height: 16),
              const SizedBox(height: 22),
              Row(
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    if (i != 0)
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 22),
                          child: Bone(height: 3, radius: 2),
                        ),
                      ),
                    const SizedBox(
                      width: 74,
                      child: Column(children: [
                        Bone.circle(size: 26),
                        SizedBox(height: 8),
                        Bone(width: 52, height: 11),
                      ]),
                    ),
                  ],
                ],
              ),
            ],
          )),
          const SizedBox(height: 14),
          card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Bone(width: 110, height: 16),
              for (int i = 0; i < 2; i++)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Bone(width: 72, height: 72, radius: 12),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Bone(width: 160, height: 15),
                            SizedBox(height: 10),
                            Row(children: [
                              Bone(width: 54, height: 18, radius: 999),
                              SizedBox(width: 8),
                              Bone(width: 62, height: 18, radius: 999),
                            ]),
                            SizedBox(height: 12),
                            Bone(width: 118, height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          )),
          const SizedBox(height: 14),
          card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Bone(width: 90, height: 16),
              SizedBox(height: 18),
              Bone(height: 13),
              SizedBox(height: 10),
              Bone(height: 13),
              SizedBox(height: 10),
              Bone(width: 200, height: 13),
            ],
          )),
        ],
      ),
    );
  }
}
