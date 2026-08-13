// lib/views/screens/addresses_page.dart
// Standalone addresses manager page based on address_selection_page
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/bloc/address/address_bloc.dart';
import 'package:marketky/bloc/address/address_event.dart';
import 'package:marketky/bloc/address/address_state.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/address_model.dart';
import 'package:marketky/views/widgets/page_container.dart';

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
    return Scaffold(
      // چیدمان اپ‌بار راست‌به‌چپ: عنوان و دکمه بازگشت سمت راست
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: AppBar(
            title: const Text('آدرس‌ها', style: TextStyle(color: Colors.black)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        backgroundColor: AppColor.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: PageContainer(
        child: BlocConsumer<AddressBloc, AddressState>(
          listener: (context, state) {
            if (state is AddressError) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is AddressLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AddressLoaded) {
              final list = state.list;
              if (list.isEmpty) {
                return _EmptyAddresses(onCreate: _openCreateDialog);
              }
              return Directionality(
                textDirection: TextDirection.rtl,
                child: ListView.separated(
                  padding: const EdgeInsets.only(top: 12, bottom: 96),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _addressCard(list[i]),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _addressCard(AddressModel a) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                if (a.defaultAddress == true)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child:
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
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
            Text(a.address, style: const TextStyle(color: Colors.black87)),
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
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: Colors.grey.shade300),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
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
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: const Icon(Icons.close),
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
                        onChanged: (b) =>
                            setState(() => isDefault = b ?? false)),
                    const Text('آدرس پیش‌فرض'),
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
                        backgroundColor: AppColor.primary),
                    child: Text(model == null ? 'افزودن' : 'ویرایش',
                        style: const TextStyle(color: Colors.white)),
                  ),
                ],
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
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف آدرس'),
        content: const Text('آیا از حذف این آدرس مطمئن هستید؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('لغو')),
          TextButton(
            onPressed: () {
              context.read<AddressBloc>().add(DeleteAddress(context, id));
              Navigator.of(ctx).pop();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _EmptyAddresses extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyAddresses({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('هنوز آدرسی ثبت نکرده‌اید'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onCreate,
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColor.primary),
              child: const Text('افزودن آدرس',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
