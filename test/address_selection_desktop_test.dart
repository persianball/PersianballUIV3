import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/bloc/address/address_bloc.dart';
import 'package:persian_ball/bloc/address/address_event.dart';
import 'package:persian_ball/bloc/address/address_state.dart';
import 'package:persian_ball/models/address_model.dart';
import 'package:persian_ball/views/screens/address_selection_page.dart';

/// بلاکی که به‌جای شبکه، لیستِ ثابت برمی‌گرداند.
class _FakeAddressBloc extends Bloc<AddressEvent, AddressState>
    implements AddressBloc {
  _FakeAddressBloc(List<AddressModel> items)
      : super(AddressLoaded(list: items)) {
    on<LoadAddresses>((e, emit) => emit(AddressLoaded(list: items)));
  }
}

final _addresses = [
  for (int i = 1; i <= 3; i++)
    AddressModel(
      id: i,
      postalCode: '123456789$i',
      address: 'تهران، خیابان آزادی، کوچه‌ی $i، پلاک ${i * 4}',
      receiverMobilePhone: '0912000000$i',
      addressName: 'آدرس $i',
      city: 'تهران',
      province: 'تهران',
      defaultAddress: i == 1,
    ),
];

Future<void> _pump(WidgetTester t, Size size) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(BlocProvider<AddressBloc>(
    create: (_) => _FakeAddressBloc(_addresses),
    child: const MaterialApp(home: AddressSelectionPage()),
  ));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('دسکتاپ: پوسته‌ی ۱۰۸۰ با دو ستون کارت و ستونِ کناری', (t) async {
    await _pump(t, const Size(1600, 1000));
    // کارت‌ها تمام‌عرضِ ۱۶۰۰ نیستند
    final card = t.getRect(find.text('آدرس 1').first);
    expect(card.left, greaterThan(200));
    // ستونِ کناری و دکمه‌ی پرداخت
    expect(find.text('ارسال به'), findsOneWidget);
    expect(find.text('یکی از آدرس‌ها را انتخاب کن'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    // دو کارت در یک ردیف
    final c1 = t.getRect(find.text('آدرس 1'));
    final c2 = t.getRect(find.text('آدرس 2'));
    expect((c1.top - c2.top).abs(), lessThan(2));

    await t.tap(find.text('آدرس 2'));
    await t.pumpAndSettle();
    expect(find.text('آدرس 2'), findsNWidgets(2)); // کارت + ستونِ کناری
  });

  testWidgets('موبایل: لیستِ تایم‌لاین و FAB', (t) async {
    await _pump(t, const Size(390, 844));
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('ارسال به'), findsNothing);
  });
}
