// lib/views/screens/order_summary_page.dart
import 'package:persian_ball/utils/payment_redirect.dart';
import 'dart:convert';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:flutter/material.dart';
import 'package:persian_ball/views/widgets/page_container.dart';
import 'package:http/http.dart' as http;
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/constant/urls.dart';
import 'package:persian_ball/models/CartModel.dart';
import 'package:persian_ball/models/address_model.dart';
import 'package:persian_ball/utils/ThousandsFormatter.dart';
import 'package:persian_ball/utils/api_error.dart';
import 'package:persian_ball/utils/order_totals.dart';
import 'package:persian_ball/views/widgets/checkout_timeline.dart';
import 'package:persian_ball/views/widgets/html_description_image.dart';
import 'package:persian_ball/constant/app_breakpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderSummaryPage extends StatefulWidget {
  final AllCartFromBackend cart;
  /// سفارشِ فقط-دوره آدرس ندارد؛ آن‌وقت این مقدار null است.
  final AddressModel? address;
  final String deliveryMethod; // 'post' | 'peyk' | 'free'

  const OrderSummaryPage({
    super.key,
    required this.cart,
    this.address,
    required this.deliveryMethod,
  });

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  final TextEditingController _discountCtrl = TextEditingController();
  bool _useWallet = false;
  bool _posting = false;
  int _discountPercent = 0;
  bool _applyingDiscount = false;

  /// کدی که سرور تأیید کرده (فقط همین به سفارش فرستاده می‌شود)
  String? _appliedCode;
  ApiError? _discountError;

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Ask user to login if token is missing, then return token if available
  Future<String?> _requireToken() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      await _showLoginDialog();
      return null;
    }
    return token;
  }

  Future<void> _showLoginDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColor.surfaceContainerOpaque,
          shape: AppShapes.border(AppShapes.rLg),
          title: const Text('نیاز به ورود دارید',
              style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface)),
          content: const Text('برای ادامه، لطفاً ابتدا وارد حساب کاربری خود شوید.',
              style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurfaceVariant)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('انصراف',
                  style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurfaceVariant)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushNamed(
                  '/login',
                  arguments: {'popOnSuccess': true},
                );
              },
              child: const Text('ورود',
                  style: TextStyle(fontFamily: 'Estedad', color: AppColor.goldEnd)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyDiscountCode() async {
    final code = _discountCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _discountError =
          const ApiError(status: 0, message: 'کد تخفیف را وارد کن'));
      return;
    }
    if (_applyingDiscount) return;
    setState(() {
      _applyingDiscount = true;
      _discountError = null;
    });

    try {
      final token = await _requireToken();
      if (token == null || token.isEmpty) return;

      final resp = await http.post(
        Uri.parse('${URLs.baseUrl}/v1/payment/voucher/verify/'),
        headers: {
          'Authorization': 'token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'code': code}),
      );
      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));
        final int percent = data is Map
            ? (int.tryParse('${data['discount_percent'] ?? 0}') ?? 0)
            : 0;
        if (percent <= 0) {
          setState(() {
            _discountPercent = 0;
            _appliedCode = null;
            _discountError = ApiError(
                status: resp.statusCode,
                message: 'این کد تخفیفی ندارد',
                raw: utf8.decode(resp.bodyBytes));
          });
          return;
        }
        setState(() {
          _discountPercent = percent;
          _appliedCode = code;
          _discountError = null;
        });
        _showSnack('کد «$code» اعمال شد: ٪$percent تخفیف');
      } else {
        setState(() {
          _discountPercent = 0;
          _appliedCode = null;
          _discountError =
              ApiError.fromResponse(resp.statusCode, utf8.decode(resp.bodyBytes));
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _discountError =
          ApiError(status: 0, message: 'اتصال برقرار نشد', raw: '$e'));
    } finally {
      if (mounted) setState(() => _applyingDiscount = false);
    }
  }

  /// لغوِ کدِ تخفیف: جمع‌ها به حالتِ بدونِ کد برمی‌گردند و سفارش بدونِ کد
  /// ثبت می‌شود.
  void _removeDiscount() {
    setState(() {
      _discountPercent = 0;
      _appliedCode = null;
      _discountError = null;
      _discountCtrl.clear();
    });
    _showSnack('کد تخفیف حذف شد');
  }

  /// ساختِ سفارش. v1 دیگر POST ندارد؛ v2 همان فیلدها را می‌گیرد
  /// (delivery_method، address، discount_code، is_browser_view، use_wallet).
  static const String _orderEndpoint = '/v2/order/order/';

  Future<void> _submitOrder() async {
    if (_posting) return;
    setState(() => _posting = true);
    try {
      final token = await _requireToken();
      if (token == null || token.isEmpty) {
        setState(() => _posting = false);
        return;
      }
      final body = {
        'delivery_method': widget.deliveryMethod,
        'address': widget.address?.id,
        // فقط کدی که سرور تأیید کرده؛ متنِ تایپ‌شده‌ی تأییدنشده فرستاده نمی‌شود
        'discount_code': _appliedCode,
        'is_browser_view': true,
        'use_wallet': _useWallet,
      }..removeWhere((k, v) => v == null);

      final resp = await http.post(
        Uri.parse('${URLs.origin}$_orderEndpoint'),
        headers: {
          'Authorization': 'token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final redirectUrl =
            paymentRedirectUrl(jsonDecode(utf8.decode(resp.bodyBytes)));
        if (redirectUrl != null) {
          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (_) => PaymentWebViewPage(paymentUrl: redirectUrl),
          //   ),
          // );
          if (await canLaunchUrl(Uri.parse(redirectUrl))) {
            await launchUrl(Uri.parse(redirectUrl));
          }

          Navigator.pop(context);
        } else {
          await _showErrorDialog(
            title: 'پاسخِ سرور بدونِ آدرسِ درگاه',
            error: ApiError(
                status: resp.statusCode,
                message: 'سرور آدرسِ درگاه را برنگرداند',
                raw: utf8.decode(resp.bodyBytes)),
            endpoint: _orderEndpoint,
          );
        }
      } else {
        await _showErrorDialog(
          title: 'ایجادِ سفارش انجام نشد',
          error: ApiError.fromResponse(resp.statusCode, utf8.decode(resp.bodyBytes)),
          endpoint: _orderEndpoint,
        );
      }
    } catch (e) {
      if (!mounted) return;
      await _showErrorDialog(
        title: 'اتصال به سرور برقرار نشد',
        error: ApiError(status: 0, message: 'خطای شبکه', raw: '$e'),
        endpoint: _orderEndpoint,
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  /// TODO(release): پیش از انتشار، نمایشِ بدنه‌ی خام/HTML را بردار و فقط
  /// پیامِ خوانای بک‌اند (ApiError.message) را نشان بده.
  ///
  /// فعلاً جزئیاتِ فنیِ خطا کامل نشان داده می‌شود تا معلوم شود سرور دقیقاً
  /// چه گفته: صفحه‌ی HTMLِ جنگو رندر می‌شود، JSON با تورفتگی.
  Future<void> _showErrorDialog({
    required String title,
    required ApiError error,
    required String endpoint,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColor.surfaceContainerOpaque,
          shape: AppShapes.border(AppShapes.rLg),
          title: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColor.errorDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColor.onSurface)),
              ),
            ],
          ),
          // بدونِ سقفِ ارتفاع، بدنه‌ی خامِ بلند (مثلاً HTMLِ درگاه) دیالوگ را
          // از صفحه بیرون می‌زد و اسکرول نمی‌شد.
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: error.isHtml ? 760 : 520,
              maxHeight: MediaQuery.of(ctx).size.height * 0.8,
            ),
            child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(error.message,
                    style: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 13.5,
                        height: 1.7,
                        color: AppColor.onSurface)),
                const SizedBox(height: 12),
                Text(
                  'HTTP ${error.status == 0 ? '-' : error.status} — $endpoint',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 11,
                      color: AppColor.onSurfaceVariant),
                ),
                if ((error.raw ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColor.obsidianBg,
                      borderRadius: AppShapes.radius(AppShapes.rMd),
                      border: Border.all(color: AppColor.outlineVariantDark),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(ctx).size.height * 0.5),
                      child: SingleChildScrollView(
                        child: error.isHtml
                            // صفحه‌ی خطای جنگو همان‌طور که مرورگر نشان می‌دهد
                            ? Directionality(
                                textDirection: TextDirection.ltr,
                                child: HtmlDescriptionBody(
                                    html: error.prettyRaw),
                              )
                            : SelectableText(
                                error.prettyRaw,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    height: 1.5,
                                    color: AppColor.onSurfaceVariant),
                              ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('باشه',
                  style: TextStyle(fontFamily: 'Estedad', color: AppColor.goldEnd)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final hasCart = widget.cart.results.isNotEmpty;
    final items =
        hasCart ? widget.cart.results[0].items : <CartItemFromBackend>[];
    final price = hasCart ? widget.cart.results[0].price : TotalPriceFromBack();

    final postPrice = price.postShippingPrice ?? 0;
    final peykPrice = price.peykShippingPrice ?? 0;
    final isFree =
        widget.deliveryMethod == 'free' || (price.isFreeShipping ?? false);
    final totals = OrderTotals.compute(
      base: price.price ?? 0,
      productDiscount: price.discountedPrice ?? 0,
      tax: price.nat ?? 0,
      shipping: widget.deliveryMethod == 'peyk' ? peykPrice : postPrice,
      freeShipping: isFree,
      voucherPercent: _discountPercent,
    );

    final bool isDesktop = AppBreakpoints.isDesktop(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.obsidianBg,
        appBar: AppBar(
          backgroundColor: AppColor.obsidianBg,
          foregroundColor: AppColor.onSurface,
          elevation: 0,
          title: const Text('خلاصه سفارش',
              style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface)),
        ),
        body: SafeArea(
          child: isDesktop
              ? _buildDesktopBody(
                  items: items,
                  totals: totals,
                )
              // تبلت: مثلِ صفحه‌ی آدرس حداکثر ۷۲۰، نه تمام‌عرض
              : PageContainer(
                  maxWidth: 720,
                  child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: CheckoutTimeline(
                          currentStep: widget.address == null ? 1 : 2,
                          skipAddress: widget.address == null),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildItemsCard(items),
                          const SizedBox(height: 12),
                          _buildAddressCard(),
                          const SizedBox(height: 12),
                          _buildDiscountCard(),
                          const SizedBox(height: 12),
                          _buildTotalsCard(
                            totals: totals,
                          ),
                          const SizedBox(height: 20),
                          _buildPayButton(),
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

  /// چیدمان دسکتاپ (>=1024): همان پوسته‌ی ۱۰۸۰ِ سبد و آدرس (سه قدمِ یک
  /// جریان؛ پیش‌تر ۹۰۰ بود و محتوا در قدمِ آخر یک‌باره جمع می‌شد) با دو ستون —
  /// آیتم‌ها/آدرس/کد تخفیف در ستون اصلی و جمع مبالغ + دکمه پرداخت در ستون کناری.
  Widget _buildDesktopBody({
    required List<CartItemFromBackend> items,
    required OrderTotals totals,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: CenteredContent(
        maxWidth: 1080,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CheckoutTimeline(
                currentStep: widget.address == null ? 1 : 2,
                skipAddress: widget.address == null),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ستون اصلی
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildItemsCard(items),
                      const SizedBox(height: 12),
                      _buildAddressCard(),
                      const SizedBox(height: 12),
                      _buildDiscountCard(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // ستون کناری: جمع مبالغ + پرداخت (بالا-چین)
                SizedBox(
                  width: AppBreakpoints.sidebarWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTotalsCard(
                        totals: totals,
                      ),
                      const SizedBox(height: 16),
                      _buildPayButton(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// کارت فهرست آیتم‌های سفارش.
  Widget _buildItemsCard(List<CartItemFromBackend> items) {
    return Container(
                      decoration: ShapeDecoration(
            color: AppColor.surfaceContainer,
            shape: AppShapes.border(AppShapes.rLg),
            shadows: AppColor.cardShadow,
          ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('محصولات',
                                style: TextStyle(
                                    fontFamily: 'Estedad',
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.onSurface)),
                            const SizedBox(height: 8),
                            ...items.map((it) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              it.product?.productVariant
                                                      ?.productName ??
                                                  it.course?.courseName ??
                                                  'محصول',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontFamily: 'Estedad',
                                                  color: AppColor.onSurface),
                                            ),
                                            // رنگ و سایز، مینیمال، فقط اگر باشند
                                            if (_variantLine(it) != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 2),
                                                child: Text(
                                                  _variantLine(it)!,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontFamily: 'Estedad',
                                                      fontSize: 11.5,
                                                      color: AppColor
                                                          .onSurfaceVariant),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('×${it.quantity}',
                                          style: const TextStyle(
                                              fontFamily: 'Estedad',
                                              color: AppColor.onSurfaceVariant)),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    );
  }

  /// «رنگ مشکی، سایز ۳۸» از فیلدهای خودِ آیتم؛ null وقتی هیچ‌کدام نیست.
  static String? _variantLine(CartItemFromBackend it) {
    final p = it.product;
    if (p == null) return null;
    final color = (p.productVariant?.color ?? '').trim();
    final parts = <String>[
      if (color.isNotEmpty && color.toLowerCase() != 'null') 'رنگ $color',
      if (p.sizeLabel != null) 'سایز ${p.sizeLabel}',
    ];
    return parts.isEmpty ? null : parts.join('، ');
  }

  /// کارت آدرس و روش ارسال — برای سفارشِ بدون ارسال، به‌جای آدرس یک
  /// توضیح نشان داده می‌شود.
  Widget _buildAddressCard() {
    final address = widget.address;
    if (address == null) return _buildNoShippingCard();
    return Container(
                      decoration: ShapeDecoration(
            color: AppColor.surfaceContainer,
            shape: AppShapes.border(AppShapes.rLg),
            shadows: AppColor.cardShadow,
          ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('آدرس و ارسال',
                                style: TextStyle(
                                    fontFamily: 'Estedad',
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.onSurface)),
                            const SizedBox(height: 8),
                            Text(address.addressName ?? 'آدرس انتخابی',
                                style: const TextStyle(
                                    fontFamily: 'Estedad', color: AppColor.onSurface)),
                            const SizedBox(height: 6),
                            Text(address.address,
                                style: const TextStyle(
                                    fontFamily: 'Estedad',
                                    color: AppColor.onSurfaceVariant)),
                            const SizedBox(height: 6),
                            Wrap(spacing: 12, runSpacing: 6, children: [
                              if (address.city != null)
                                _infoChip('شهر: ${address.city}'),
                              if (address.province != null)
                                _infoChip('استان: ${address.province}'),
                              _infoChip(
                                  'روش ارسال: ${_deliveryLabel(widget.deliveryMethod)}'),
                            ]),
                          ],
                        ),
                      ),
                    );
  }

  /// سفارشی که فقط دوره دارد ارسال فیزیکی ندارد، پس به‌جای کارت آدرس این
  /// توضیح می‌آید تا نبودِ آدرس عمدی به نظر برسد، نه جاافتاده.
  Widget _buildNoShippingCard() {
    return Container(
      decoration: ShapeDecoration(
        color: AppColor.surfaceContainer,
        shape: AppShapes.border(AppShapes.rLg),
        shadows: AppColor.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.school_outlined, color: AppColor.successDark),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('بدون ارسال فیزیکی',
                      style: TextStyle(
                          fontFamily: 'Estedad',
                          fontWeight: FontWeight.w700,
                          color: AppColor.onSurface)),
                  SizedBox(height: 4),
                  Text('این سفارش فقط شامل دوره است و نیازی به آدرس ندارد.',
                      style: TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 12,
                          color: AppColor.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// کارت کد تخفیف و کیف پول.
  Widget _buildDiscountCard() {
    return Container(
                      decoration: ShapeDecoration(
            color: AppColor.surfaceContainer,
            shape: AppShapes.border(AppShapes.rLg),
            shadows: AppColor.cardShadow,
          ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('کد تخفیف',
                                style: TextStyle(
                                    fontFamily: 'Estedad',
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.onSurface)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _discountCtrl,
                                    style: const TextStyle(
                                        fontFamily: 'Estedad', color: AppColor.onSurface),
                                    decoration: InputDecoration(
                                      hintText: 'کد تخفیف خود را وارد کنید',
                                      hintStyle: const TextStyle(
                                          fontFamily: 'Estedad',
                                          color: AppColor.onSurfaceVariant),
                                      filled: true,
                                      fillColor: AppColor.obsidianBg,
                                      border: OutlineInputBorder(
                                        borderRadius: AppShapes.radius(AppShapes.rMd),
                                        borderSide:
                                            BorderSide(color: AppColor.outlineVariantDark),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: AppShapes.radius(AppShapes.rMd),
                                        borderSide:
                                            BorderSide(color: AppColor.outlineVariantDark),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: AppShapes.radius(AppShapes.rMd),
                                        borderSide:
                                            BorderSide(color: AppColor.goldEnd, width: 2),
                                      ),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _applyingDiscount
                                      ? null
                                      : _applyDiscountCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColor.goldEnd,
                                    shape: AppShapes.pill,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  child: _applyingDiscount
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColor.onGold,
                                          ),
                                        )
                                      : const Text('اعمال',
                                          style: TextStyle(
                                              fontFamily: 'Estedad',
                                              color: AppColor.onGold)),
                                ),
                              ],
                            ),
                            if (_discountError != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColor.errorDark.withValues(alpha: 0.08),
                                  border: Border.all(
                                      color: AppColor.errorDark.withValues(alpha: 0.4)),
                                  borderRadius: AppShapes.radius(AppShapes.rMd),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.error_outline_rounded,
                                        size: 18, color: AppColor.errorDark),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _discountError!.message,
                                            style: const TextStyle(
                                              fontFamily: 'Estedad',
                                              fontSize: 12.5,
                                              height: 1.6,
                                              color: AppColor.errorDark,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (_discountError!.status > 0)
                                            Text(
                                              'HTTP ${_discountError!.status}'
                                              '${(_discountError!.raw ?? '').isNotEmpty ? ' — ${_discountError!.raw}' : ''}',
                                              textDirection: TextDirection.ltr,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontFamily: 'Estedad',
                                                fontSize: 10.5,
                                                color: AppColor.onSurfaceVariant,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (_discountPercent > 0 && _appliedCode != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                                decoration: BoxDecoration(
                                  color: AppColor.successDark.withValues(alpha: 0.08),
                                  border: Border.all(
                                      color: AppColor.successDark.withValues(alpha: 0.4)),
                                  borderRadius: AppShapes.radius(AppShapes.rMd),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded,
                                        size: 18, color: AppColor.successDark),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'کد «$_appliedCode» اعمال شد: ٪$_discountPercent تخفیف',
                                        style: const TextStyle(
                                          fontFamily: 'Estedad',
                                          fontSize: 12.5,
                                          color: AppColor.successDark,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _removeDiscount,
                                      icon: const Icon(Icons.close_rounded,
                                          size: 16, color: AppColor.errorDark),
                                      label: const Text('حذف کد',
                                          style: TextStyle(
                                              fontFamily: 'Estedad',
                                              fontSize: 12,
                                              color: AppColor.errorDark)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Checkbox(
                                  value: _useWallet,
                                  activeColor: AppColor.goldEnd,
                                  onChanged: (v) =>
                                      setState(() => _useWallet = v ?? false),
                                ),
                                const Text('استفاده از کیف پول',
                                    style: TextStyle(
                                        fontFamily: 'Estedad', color: AppColor.onSurface)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
  }

  /// کارت جمع مبالغ سفارش — هر ردیف یک عددِ API یا کدِ تخفیفِ تأییدشده.
  Widget _buildTotalsCard({required OrderTotals totals}) {
    final t = totals;
    return Container(
      decoration: ShapeDecoration(
        color: AppColor.surfaceContainer,
        shape: AppShapes.border(AppShapes.rLg),
        shadows: AppColor.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _priceRow('قیمت کل', '${thousandSeparator(t.base)} تومان'),
            if (t.productDiscount > 0)
              _priceRow('تخفیف محصولات',
                  '${thousandSeparator(t.productDiscount)}- تومان',
                  valueColor: AppColor.errorDark),
            if (t.hasVoucher)
              _priceRow('کد تخفیف (٪${t.voucherPercent})',
                  '${thousandSeparator(t.voucherAmount)}- تومان',
                  valueColor: AppColor.successDark),
            _priceRow('مالیات', '${thousandSeparator(t.tax)} تومان'),
            _priceRow(
                'هزینه ارسال',
                t.freeShipping
                    ? 'رایگان'
                    : '${thousandSeparator(t.shipping)} تومان',
                valueColor: t.freeShipping ? AppColor.successDark : null),
            Divider(height: 24, color: AppColor.outlineVariantDark),
            _priceRow('مبلغ قابل پرداخت',
                t.payable == 0
                    ? 'رایگان'
                    : '${thousandSeparator(t.payable)} تومان',
                valueColor: AppColor.goldEnd),
          ],
        ),
      ),
    );
  }

  /// دکمه رفتن به درگاه پرداخت.
  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
                        onPressed: _posting ? null : _submitOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.goldEnd,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: AppShapes.pill,
                        ),
                        child: _posting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColor.onGold))
                            : const Text('رفتن به درگاه پرداخت',
                                style: TextStyle(
                                    fontFamily: 'Estedad', color: AppColor.onGold)),
      ),
    );
  }

  Widget _infoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: ShapeDecoration(
            color: AppColor.obsidianBg,
            shape: AppShapes.border(AppShapes.rLg),
            shadows: AppColor.cardShadow,
          ),
      child: Text(label,
          style: const TextStyle(
              fontFamily: 'Estedad', fontSize: 12, color: AppColor.onSurfaceVariant)),
    );
  }

  Widget _priceRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Estedad', fontSize: 14, color: AppColor.onSurfaceVariant)),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColor.onSurface)),
        ],
      ),
    );
  }

  String _deliveryLabel(String method) {
    switch (method) {
      case 'post':
        return 'پست';
      case 'peyk':
        return 'پیک';
      case 'free':
        return 'ارسال رایگان';
      default:
        return method;
    }
  }
}
