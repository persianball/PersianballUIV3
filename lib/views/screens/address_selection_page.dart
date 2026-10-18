// lib/views/screens/address_selection_page.dart
import 'package:flutter/material.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persian_ball/bloc/address/address_event.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:persian_ball/bloc/address/address_bloc.dart';
import 'package:persian_ball/models/address_model.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/views/widgets/checkout_timeline.dart';
import 'package:persian_ball/views/screens/order_summary_page.dart';
import 'package:persian_ball/models/CartModel.dart';
import 'package:persian_ball/constant/app_breakpoints.dart';
import 'package:persian_ball/views/widgets/motion.dart';
import 'package:persian_ball/views/widgets/page_container.dart';

import '../../bloc/address/address_state.dart';

class AddressSelectionPage extends StatefulWidget {
  const AddressSelectionPage({super.key});

  @override
  State<AddressSelectionPage> createState() => _AddressSelectionPageState();
}

class _AddressSelectionPageState extends State<AddressSelectionPage> {
  int? selectedAddressId;

  @override
  void initState() {
    super.initState();
    context.read<AddressBloc>().add(LoadAddresses(context));
  }

  /// همان پوسته‌ی سبد خرید (قدمِ قبلیِ همین جریان)، تا رفتن از سبد به آدرس
  /// و بعد خلاصه‌ی سفارش پرش نداشته باشد.
  static const double _desktopMaxWidth = 1080;

  @override
  Widget build(BuildContext context) {
    final bool desktop = AppBreakpoints.isDesktop(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.obsidianBg,
        appBar: AppBar(
          backgroundColor: AppColor.obsidianBg,
          foregroundColor: AppColor.onSurface,
          elevation: 0,
          title: const Text('انتخاب آدرس',
              style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface)),
          // موبایل: «افزودن آدرس» در نوارِ بالا؛ FABِ «+» روی دکمه‌ی تمام‌عرضِ
          // پرداخت می‌افتاد. دسکتاپ دکمه را در سربرگِ لیست دارد.
          actions: [
            if (!desktop)
              IconButton(
                tooltip: 'افزودن آدرس',
                onPressed: _openCreateDialog,
                icon: const Icon(Icons.add_location_alt_outlined,
                    color: AppColor.goldEnd),
              ),
          ],
        ),
        body: BlocConsumer<AddressBloc, AddressState>(
          listener: (context, state) {
            if (state is AddressError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is AddressLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColor.goldEnd));
            }
            if (state is AddressLoaded) {
              return desktop
                  ? _desktopBody(state.list)
                  : _mobileBody(state.list);
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  // ---------- موبایل/تبلت ----------

  Widget _mobileBody(List<AddressModel> list) {
    return PageContainer(
      maxWidth: 720,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: CheckoutTimeline(currentStep: 1),
          ),
          Expanded(
            child: list.isEmpty
                ? _emptyState()
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = list[i];
                      return TimelineTile(
                        isFirst: i == 0,
                        isLast: i == list.length - 1,
                        indicatorStyle: IndicatorStyle(
                          width: 24,
                          height: 24,
                          indicator: Container(
                            decoration: BoxDecoration(
                              color: selectedAddressId == item.id
                                  ? AppColor.goldEnd
                                  : AppColor.surfaceContainer,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColor.goldEnd, width: 2),
                            ),
                            child: Icon(Icons.location_on,
                                size: 14,
                                color: selectedAddressId == item.id
                                    ? AppColor.onGold
                                    : AppColor.goldEnd),
                          ),
                        ),
                        beforeLineStyle: LineStyle(color: AppColor.outlineVariantDark, thickness: 2),
                        afterLineStyle: LineStyle(color: AppColor.outlineVariantDark, thickness: 2),
                        endChild: _addressCard(item),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              // تمام‌عرض روی گوشی (پیش‌تر به اندازه‌ی متنش جمع می‌شد)، روی
              // تبلت حداکثر ۴۲۰
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SizedBox(width: double.infinity, child: _payButton()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- دسکتاپ ----------

  Widget _desktopBody(List<AddressModel> list) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: CenteredContent(
        maxWidth: _desktopMaxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CheckoutTimeline(currentStep: 1),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text('آدرس‌های شما',
                                style: TextStyle(
                                    fontFamily: 'Estedad',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.onSurface)),
                          ),
                          TextButton.icon(
                            onPressed: _openCreateDialog,
                            icon: const Icon(Icons.add_location_alt_outlined,
                                color: AppColor.goldEnd),
                            label: const Text('افزودن آدرس جدید',
                                style: TextStyle(
                                    fontFamily: 'Estedad',
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.goldEnd)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (list.isEmpty)
                        SizedBox(height: 320, child: _emptyState())
                      else
                        // دو ستون: کارتِ آدرس در یک ستونِ ۷۰۰ پیکسلی خیلی
                        // کشیده و کم‌ارتفاع می‌شد
                        LayoutBuilder(builder: (context, c) {
                          const gap = 14.0;
                          final w = (c.maxWidth - gap) / 2;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (int i = 0; i < list.length; i++)
                                SizedBox(
                                  width: w,
                                  child: FadeSlideIn(
                                    delay: Duration(milliseconds: 45 * (i % 6)),
                                    child: _addressCard(list[i], margin: EdgeInsets.zero),
                                  ),
                                ),
                            ],
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: AppBreakpoints.sidebarWidth,
                  child: FadeSlideIn(
                    delay: const Duration(milliseconds: 90),
                    child: _desktopSidebar(list),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _desktopSidebar(List<AddressModel> list) {
    AddressModel? selected;
    for (final a in list) {
      if (a.id == selectedAddressId) selected = a;
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: AppColor.card,
        shape: AppShapes.border(AppShapes.rLg),
        shadows: AppColor.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('ارسال به',
              style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColor.onSurface)),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: selected == null
                ? Row(
                    key: const ValueKey('none'),
                    children: const [
                      Icon(Icons.touch_app_outlined,
                          size: 20, color: AppColor.onSurfaceVariant),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('یکی از آدرس‌ها را انتخاب کن',
                            style: TextStyle(
                                fontFamily: 'Estedad',
                                fontSize: 13,
                                color: AppColor.onSurfaceVariant)),
                      ),
                    ],
                  )
                : Row(
                    key: ValueKey(selected.id),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on,
                          size: 20, color: AppColor.goldEnd),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(selected.addressName ?? 'آدرس بدون نام',
                                style: const TextStyle(
                                    fontFamily: 'Estedad',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.onSurface)),
                            const SizedBox(height: 4),
                            Text(selected.address,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontFamily: 'Estedad',
                                    fontSize: 12.5,
                                    height: 1.7,
                                    color: AppColor.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          _payButton(),
        ],
      ),
    );
  }

  Widget _payButton() {
    return ElevatedButton(
      onPressed: selectedAddressId == null ? null : _goToPayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.goldEnd,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: AppShapes.pill,
      ),
      child: const Text('نهایی‌سازی و پرداخت',
          style: TextStyle(fontFamily: 'Estedad', color: AppColor.onGold)),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_outlined,
                size: 48, color: AppColor.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text('هنوز آدرسی ثبت نکرده‌ای',
                style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColor.onSurface)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openCreateDialog,
              icon: const Icon(Icons.add, color: AppColor.goldEnd),
              label: const Text('افزودن آدرس',
                  style: TextStyle(fontFamily: 'Estedad', color: AppColor.goldEnd)),
              style: OutlinedButton.styleFrom(
                shape: AppShapes.pill,
                side: const BorderSide(color: AppColor.goldEnd),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressCard(AddressModel a,
      {EdgeInsets margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 4)}) {
    final bool selected = a.id == selectedAddressId;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: margin,
      decoration: ShapeDecoration(
            color: AppColor.surfaceContainer,
            shape: AppShapes.border(AppShapes.rLg,
                side: BorderSide(
                    color: selected ? AppColor.goldEnd : Colors.transparent,
                    width: 1.5)),
            shadows: AppColor.cardShadow,
          ),
      child: InkWell(
        customBorder: AppShapes.border(AppShapes.rLg),
        onTap: () => setState(() => selectedAddressId = a.id),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // دایره‌ی انتخاب سمتِ راست، کنارِ نام (پیش‌تر انتهای چپِ ردیف بود)
                  Radio<int>(
                    value: a.id ?? -1,
                    groupValue: selectedAddressId,
                    onChanged: (_) => setState(() => selectedAddressId = a.id),
                    activeColor: AppColor.goldEnd,
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: Text(
                      a.addressName ?? 'آدرس بدون نام',
                      style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColor.onSurface),
                    ),
                  ),
                  IconButton(
                    tooltip: 'ویرایش',
                    icon: const Icon(Icons.edit_outlined, color: AppColor.onSurfaceVariant),
                    onPressed: () => _openEditDialog(a),
                  ),
                  IconButton(
                    tooltip: 'حذف',
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(a.id!),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(a.address,
                  style: const TextStyle(fontFamily: 'Estedad', color: AppColor.onSurfaceVariant)),
              const SizedBox(height: 6),
              Wrap(spacing: 12, runSpacing: 6, children: [
                _chip('شهر', a.city),
                _chip('استان', a.province),
                _chip('کدپستی', a.postalCode),
                _chip('موبایل', a.receiverMobilePhone),
                _chip('تلفن', a.receiverHomePhone),
              ]),
              if (a.defaultAddress == true) ...[
                const SizedBox(height: 8),
                Row(children: const [
                  Icon(Icons.check_circle, color: AppColor.successDark, size: 18),
                  SizedBox(width: 6),
                  Text('آدرس پیش‌فرض',
                      style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface)),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: ShapeDecoration(
            color: AppColor.obsidianBg,
            shape: AppShapes.border(AppShapes.rLg),
            shadows: AppColor.cardShadow,
          ),
      child: Text('$label: $value',
          style: const TextStyle(
              fontFamily: 'Estedad', fontSize: 12, color: AppColor.onSurfaceVariant)),
    );
  }

  void _openCreateDialog() {
    _openAddressDialog();
  }

  void _openEditDialog(AddressModel a) {
    _openAddressDialog(model: a);
  }

  void _openAddressDialog({AddressModel? model}) {
    final formKey = GlobalKey<FormState>();
    final postal = TextEditingController(text: model?.postalCode);
    final addr = TextEditingController(text: model?.address);
    final home = TextEditingController(text: model?.receiverHomePhone);
    final mobile = TextEditingController(text: model?.receiverMobilePhone);
    final email = TextEditingController(text: model?.email);
    final name = TextEditingController(text: model?.addressName);
    final city = TextEditingController(text: model?.city);
    final province = TextEditingController(text: model?.province);
    bool isDefault = model?.defaultAddress ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.surfaceContainerOpaque,
      shape: AppShapes.borderTop(AppShapes.rXl),
      // در دسکتاپ شیت تمام‌عرضِ پنجره نمی‌شود
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(model == null ? 'افزودن آدرس' : 'ویرایش آدرس',
                            style: const TextStyle(
                                fontFamily: 'Estedad',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColor.onSurface)),
                        IconButton(
                            icon: const Icon(Icons.close, color: AppColor.onSurfaceVariant),
                            onPressed: () => Navigator.of(ctx).pop()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _input(postal, 'کدپستی', validator: (v) => (v == null || v.isEmpty) ? 'کدپستی الزامی است' : null),
                    _input(addr, 'نشانی', maxLines: 3, validator: (v) => (v == null || v.isEmpty) ? 'نشانی الزامی است' : null),
                    Row(children: [
                      Expanded(child: _input(city, 'شهر')),
                      const SizedBox(width: 8),
                      Expanded(child: _input(province, 'استان')),
                    ]),
                    _input(name, 'عنوان آدرس'),
                    Row(children: [
                      Expanded(child: _input(mobile, 'موبایل گیرنده', validator: (v) => (v == null || v.isEmpty) ? 'موبایل الزامی است' : null)),
                      const SizedBox(width: 8),
                      Expanded(child: _input(home, 'تلفن ثابت')),
                    ]),
                    _input(email, 'ایمیل'),
                    // setStateِ خودِ شیت؛ setStateِ صفحه تیکِ داخلِ شیت را
                    // تازه نمی‌کرد
                    StatefulBuilder(builder: (ctx, setSheet) => Row(children: [
                      Checkbox(
                          value: isDefault,
                          activeColor: AppColor.goldEnd,
                          onChanged: (b) => setSheet(() => isDefault = b ?? false)),
                      const Text('آدرس پیش‌فرض',
                          style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface)),
                    ])),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final payload = AddressModel(
                          postalCode: postal.text.trim(),
                          address: addr.text.trim(),
                          receiverHomePhone: home.text.trim().isEmpty ? null : home.text.trim(),
                          receiverMobilePhone: mobile.text.trim(),
                          email: email.text.trim().isEmpty ? null : email.text.trim(),
                          addressName: name.text.trim().isEmpty ? null : name.text.trim(),
                          city: city.text.trim().isEmpty ? null : city.text.trim(),
                          province: province.text.trim().isEmpty ? null : province.text.trim(),
                          defaultAddress: isDefault,
                        );
                        if (model == null) {
                          context.read<AddressBloc>().add(CreateAddress(context, payload));
                        } else {
                          context.read<AddressBloc>().add(UpdateAddress(context, model.id!, payload));
                        }
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.goldEnd, shape: AppShapes.pill),
                      child: Text(model == null ? 'افزودن' : 'ویرایش',
                          style: const TextStyle(fontFamily: 'Estedad', color: AppColor.onGold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _input(TextEditingController c, String label, {int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        validator: validator,
        maxLines: maxLines,
        style: const TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'Estedad', color: AppColor.onSurfaceVariant),
          filled: true,
          fillColor: AppColor.obsidianBg,
          border: OutlineInputBorder(
            borderRadius: AppShapes.radius(AppShapes.rMd),
            borderSide: BorderSide(color: AppColor.outlineVariantDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppShapes.radius(AppShapes.rMd),
            borderSide: BorderSide(color: AppColor.outlineVariantDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppShapes.radius(AppShapes.rMd),
            borderSide: BorderSide(color: AppColor.goldEnd, width: 2),
          ),
          isDense: true,
        ),
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColor.surfaceContainerOpaque,
          shape: AppShapes.border(AppShapes.rLg),
          title: const Text('حذف آدرس',
              style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface)),
          content: const Text('آیا از حذف این آدرس مطمئن هستید؟',
              style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurfaceVariant)),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('لغو',
                    style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurfaceVariant))),
            TextButton(
              onPressed: () {
                context.read<AddressBloc>().add(DeleteAddress(context, id));
                Navigator.of(ctx).pop();
              },
              child: const Text('حذف', style: TextStyle(fontFamily: 'Estedad', color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _goToPayment() {
    if (selectedAddressId == null) return;

    // Prefer delivery method passed from previous step if available
    final args = ModalRoute.of(context)?.settings.arguments;
    String initialMethod = 'free';
    if (args is Map && args['delivery_method'] is String && (args['delivery_method'] as String).isNotEmpty) {
      initialMethod = args['delivery_method'] as String;
    }

    Navigator.of(context).pop();
    final state = context.read<AddressBloc>().state;
    if (state is AddressLoaded) {
      final addr = state.list.firstWhere((a) => a.id == selectedAddressId);
      AllCartFromBackend? cart;
      String useMethod = initialMethod;

      if (args is Map) {
        final map = args;
        if (map['cart'] is AllCartFromBackend) cart = map['cart'];
        if (map['delivery_method'] is String && (map['delivery_method'] as String).isNotEmpty) {
          useMethod = map['delivery_method'];
        }
      }
      if (cart != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderSummaryPage(
              cart: cart!,
              address: addr,
              deliveryMethod: useMethod,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اطلاعات سبد در دسترس نیست. لطفاً از سبد خرید وارد شوید.')),
        );
      }
    }





    // showModalBottomSheet(
    //   context: context,
    //   backgroundColor: Colors.white,
    //   shape: const RoundedRectangleBorder(
    //     borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    //   ),
    //   builder: (ctx) {
    //     String method = initialMethod;
    //     return StatefulBuilder(
    //       builder: (context, setStateSB) {
    //         return Directionality(
    //           textDirection: TextDirection.rtl,
    //           child: Padding(
    //             padding: const EdgeInsets.all(16.0),
    //             child: Column(
    //               mainAxisSize: MainAxisSize.min,
    //               crossAxisAlignment: CrossAxisAlignment.stretch,
    //               children: [
    //                 const Text('انتخاب روش ارسال', style: TextStyle(fontWeight: FontWeight.w700)),
    //                 RadioListTile<String>(
    //                   value: 'post',
    //                   groupValue: method,
    //                   onChanged: (v) => setStateSB(() => method = v ?? 'post'),
    //                   title: const Text('پست'),
    //                 ),
    //                 RadioListTile<String>(
    //                   value: 'peyk',
    //                   groupValue: method,
    //                   onChanged: (v) => setStateSB(() => method = v ?? 'post'),
    //                   title: const Text('پیک'),
    //                 ),
    //                 RadioListTile<String>(
    //                   value: 'free',
    //                   groupValue: method,
    //                   onChanged: (v) => setStateSB(() => method = v ?? 'post'),
    //                   title: const Text('ارسال رایگان'),
    //                 ),
    //                 const SizedBox(height: 8),
    //                 ElevatedButton(
    //                   onPressed: () {
    //                     Navigator.of(context).pop();
    //                     final state = context.read<AddressBloc>().state;
    //                     if (state is AddressLoaded) {
    //                       final addr = state.list.firstWhere((a) => a.id == selectedAddressId);
    //                       AllCartFromBackend? cart;
    //                       String useMethod = method;
    //                       if (args is Map) {
    //                         final map = args as Map;
    //                         if (map['cart'] is AllCartFromBackend) cart = map['cart'] as AllCartFromBackend;
    //                         if (map['delivery_method'] is String && (map['delivery_method'] as String).isNotEmpty) {
    //                           useMethod = method; // respect user choice from this sheet
    //                         }
    //                       }
    //                       if (cart != null) {
    //                         Navigator.of(context).push(
    //                           MaterialPageRoute(
    //                             builder: (_) => OrderSummaryPage(
    //                               cart: cart!,
    //                               address: addr,
    //                               deliveryMethod: useMethod,
    //                             ),
    //                           ),
    //                         );
    //                       } else {
    //                         ScaffoldMessenger.of(context).showSnackBar(
    //                           const SnackBar(content: Text('اطلاعات سبد در دسترس نیست. لطفاً از سبد خرید وارد شوید.')),
    //                         );
    //                       }
    //                     }
    //                   },
    //                   style: ElevatedButton.styleFrom(
    //                     backgroundColor: AppColor.primary,
    //                     padding: const EdgeInsets.symmetric(vertical: 14),
    //                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    //                   ),
    //                   child: const Text('ادامه'),
    //                 ),
    //               ],
    //             ),
    //           ),
    //         );
    //       },
    //     );
    //   },
    // );
  }
}