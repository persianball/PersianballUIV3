// lib/views/screens/address_selection_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/bloc/address/address_event.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:marketky/bloc/address/address_bloc.dart';
import 'package:marketky/models/address_model.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/views/screens/payment_webview_page.dart';
import 'package:marketky/views/widgets/checkout_timeline.dart';
import 'package:marketky/views/screens/order_summary_page.dart';
import 'package:marketky/models/CartModel.dart';
import 'package:marketky/bloc/address/address_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
    // Try get passed cart and delivery method from previous page (CartPage)
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    AllCartFromBackend? passedCart;
    String? passedDeliveryMethod;
    if (routeArgs is Map) {
      final map = routeArgs as Map;
      if (map['cart'] is AllCartFromBackend) passedCart = map['cart'] as AllCartFromBackend;
      if (map['delivery_method'] is String) passedDeliveryMethod = map['delivery_method'] as String;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('انتخاب آدرس', style: TextStyle(color: Colors.black))),
      floatingActionButton: FloatingActionButton(

        onPressed: _openCreateDialog,
        backgroundColor: AppColor.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocConsumer<AddressBloc, AddressState>(
        listener: (context, state) {
          if (state is AddressError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is AddressLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AddressLoaded) {
            final list = state.list;
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: CheckoutTimeline(currentStep: 1),
                ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Expanded(
                    child: ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final item = list[i];
                        final isFirst = i == 0;
                        final isLast = i == list.length - 1;
                        return TimelineTile(
                          isFirst: isFirst,
                          isLast: isLast,
                          indicatorStyle: IndicatorStyle(
                            width: 24,
                            height: 24,
                            indicator: Container(
                              decoration: BoxDecoration(
                                color: selectedAddressId == item.id ? AppColor.primary : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColor.primary, width: 2),
                              ),
                              child: const Icon(Icons.location_on, size: 14, color: Colors.white),
                            ),
                          ),
                          beforeLineStyle: LineStyle(color: Colors.grey.shade300, thickness: 2),
                          afterLineStyle: LineStyle(color: Colors.grey.shade300, thickness: 2),
                          endChild: _addressCard(item),
                        );
                      },
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width*0.5,
                      child: ElevatedButton(
                        onPressed: selectedAddressId == null ? null : _goToPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('نهایی‌سازی و پرداخت', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _addressCard(AddressModel a) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => setState(() => selectedAddressId = a.id),
        borderRadius: BorderRadius.circular(12),
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
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _openEditDialog(a),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(a.id!),
                  ),
                  Radio<int>(
                    value: a.id ?? -1,
                    groupValue: selectedAddressId,
                    onChanged: (_) => setState(() => selectedAddressId = a.id),
                    activeColor: AppColor.primary,
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
              if (a.defaultAddress == true) ...[
                const SizedBox(height: 8),
                Row(children: const [Icon(Icons.check_circle, color: Colors.green, size: 18), SizedBox(width: 6), Text('آدرس پیش‌فرض')]),
              ],
            ],
          ),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                      Text(model == null ? 'افزودن آدرس' : 'ویرایش آدرس', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
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
                  Row(children: [
                    Checkbox(value: isDefault, onChanged: (b) => setState(() => isDefault = b ?? false)),
                    const Text('آدرس پیش‌فرض'),
                  ]),
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
                    style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary),
                    child: Text(model == null ? 'افزودن' : 'ویرایش', style: const TextStyle(color: Colors.white)),
                  ),
                ],
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('لغو')),
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
        final map = args as Map;
        if (map['cart'] is AllCartFromBackend) cart = map['cart'] as AllCartFromBackend;
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