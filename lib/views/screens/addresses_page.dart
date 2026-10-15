// lib/views/screens/addresses_page.dart
// Standalone addresses manager page based on address_selection_page
import 'package:flutter/material.dart';
import 'package:persian_ball/constant/app_breakpoints.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persian_ball/bloc/address/address_bloc.dart';
import 'package:persian_ball/bloc/address/address_event.dart';
import 'package:persian_ball/bloc/address/address_state.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/models/address_model.dart';
import 'package:persian_ball/views/widgets/motion.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  @override
  void initState() {
    super.initState();
    context.read<AddressBloc>().add(LoadAddresses(context));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.obsidianBg,
        appBar: AppBar(
          backgroundColor: AppColor.obsidianBg,
          foregroundColor: AppColor.onSurface,
          elevation: 0,
          title: const Text('آدرس‌ها',
              style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface)),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openCreateDialog,
          backgroundColor: AppColor.goldEnd,
          shape: AppShapes.border(AppShapes.rMd),
          child: const Icon(Icons.add, color: AppColor.onGold),
        ),
        body: BlocConsumer<AddressBloc, AddressState>(
          listener: (context, state) {
            if (state is AddressError) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is AddressLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColor.goldEnd));
            }
            if (state is AddressLoaded) {
              final list = state.list;
              if (list.isEmpty) {
                return _EmptyAddresses(onCreate: _openCreateDialog);
              }
              // دسکتاپ: گرید دو ستونه‌ی وسط‌چین؛ موبایل/تبلت: لیست قبلی
              if (AppBreakpoints.isDesktop(context)) {
                return _desktopGrid(context, list);
              }
              return ListView.separated(
                padding: const EdgeInsets.only(top: 12, bottom: 96),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => FadeSlideIn(
                  delay: Duration(milliseconds: 45 * (i % 6)),
                  child: _addressCard(list[i]),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  /// گرید دو ستونه‌ی دسکتاپ؛ کارت‌ها از بالا هم‌تراز می‌شوند و
  /// انیمیشن FadeSlideIn هر کارت حفظ شده است.
  Widget _desktopGrid(BuildContext context, List<AddressModel> list) {
    final rows = <Widget>[];
    for (int i = 0; i < list.length; i += 2) {
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FadeSlideIn(
                delay: Duration(milliseconds: 45 * (i % 6)),
                child: _addressCard(list[i], desktop: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: (i + 1 < list.length)
                  ? FadeSlideIn(
                      delay: Duration(milliseconds: 45 * ((i + 1) % 6)),
                      child: _addressCard(list[i + 1], desktop: true),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 96),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppBreakpoints.gutter(context)),
            child: Column(children: rows),
          ),
        ),
      ),
    );
  }

  Widget _addressCard(AddressModel a, {bool desktop = false}) {
    return Container(
      margin: desktop
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            Row(
              children: [
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
                if (a.defaultAddress == true)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child:
                        Icon(Icons.check_circle, color: AppColor.successDark, size: 18),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColor.onSurfaceVariant),
                  onPressed: () => _openEditDialog(a),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
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
          ],
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
      // در دسکتاپ فرم تمام‌عرض صفحه نشود
      constraints: AppBreakpoints.isDesktop(context)
          ? const BoxConstraints(maxWidth: 560)
          : null,
      backgroundColor: AppColor.surfaceContainerOpaque,
      shape: AppShapes.borderTop(AppShapes.rXl),
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
                    _input(postal, 'کدپستی',
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'کدپستی الزامی است'
                            : null),
                    _input(addr, 'نشانی',
                        maxLines: 3,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'نشانی الزامی است' : null),
                    Row(children: [
                      Expanded(child: _input(city, 'شهر')),
                      const SizedBox(width: 8),
                      Expanded(child: _input(province, 'استان')),
                    ]),
                    _input(name, 'عنوان آدرس'),
                    Row(children: [
                      Expanded(
                          child: _input(mobile, 'موبایل گیرنده',
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'موبایل الزامی است'
                                  : null)),
                      const SizedBox(width: 8),
                      Expanded(child: _input(home, 'تلفن ثابت')),
                    ]),
                    _input(email, 'ایمیل'),
                    Row(children: [
                      Checkbox(
                          value: isDefault,
                          activeColor: AppColor.goldEnd,
                          onChanged: (b) =>
                              setState(() => isDefault = b ?? false)),
                      const Text('آدرس پیش‌فرض',
                          style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface)),
                    ]),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final payload = AddressModel(
                          postalCode: postal.text.trim(),
                          address: addr.text.trim(),
                          receiverHomePhone:
                              home.text.trim().isEmpty ? null : home.text.trim(),
                          receiverMobilePhone: mobile.text.trim(),
                          email: email.text.trim().isEmpty
                              ? null
                              : email.text.trim(),
                          addressName:
                              name.text.trim().isEmpty ? null : name.text.trim(),
                          city:
                              city.text.trim().isEmpty ? null : city.text.trim(),
                          province: province.text.trim().isEmpty
                              ? null
                              : province.text.trim(),
                          defaultAddress: isDefault,
                        );
                        if (model == null) {
                          context
                              .read<AddressBloc>()
                              .add(CreateAddress(context, payload));
                        } else {
                          context
                              .read<AddressBloc>()
                              .add(UpdateAddress(context, model.id!, payload));
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

  Widget _input(TextEditingController c, String label,
      {int maxLines = 1, String? Function(String?)? validator}) {
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
}

class _EmptyAddresses extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyAddresses({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_outlined,
              size: 64, color: AppColor.onSurfaceVariant),
          const SizedBox(height: 12),
          const Text('هنوز آدرسی ثبت نکرده‌اید',
              style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onCreate,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.goldEnd, shape: AppShapes.pill),
            child: const Text('افزودن آدرس',
                style: TextStyle(fontFamily: 'Estedad', color: AppColor.onGold)),
          ),
        ],
      ),
    );
  }
}
