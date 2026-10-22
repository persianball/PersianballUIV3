import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/bloc/product_detail/product_detail_bloc.dart';
import 'package:persian_ball/bloc/product_detail/product_detail_event.dart';
import 'package:persian_ball/bloc/product_detail/product_detail_state.dart';
import 'package:persian_ball/models/ProductModel.dart';
import 'package:persian_ball/views/widgets/variant_swatch_picker.dart';

const _swatches = [
  VariantSwatch(name: 'طوسی', color: Color(0xFF2F4F4F)),
  VariantSwatch(name: 'سفید', color: Color(0xFFFFFAFA), available: false),
  VariantSwatch(name: 'مشکی', color: Color(0xFF353935)),
];

class _Host extends StatefulWidget {
  const _Host({required this.onPick});
  final ValueChanged<int> onPick;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int sel = 0;
  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: VariantSwatchPicker(
                swatches: _swatches,
                selectedIndex: sel,
                onSelected: (i) {
                  widget.onPick(i);
                  setState(() => sel = i);
                },
              ),
            ),
          ),
        ),
      );
}

void main() {
  testWidgets('نامِ رنگ در سربرگ و انتخاب با ضربه', (t) async {
    final picks = <int>[];
    await t.pumpWidget(_Host(onPick: picks.add));
    expect(find.text('طوسی'), findsOneWidget);
    expect(find.text('۳ رنگ'), findsOneWidget);

    await t.tap(find.bySemanticsLabel('رنگ مشکی'));
    await t.pumpAndSettle();
    expect(picks, [2]);
    expect(find.text('مشکی'), findsOneWidget);
    expect(find.text('طوسی'), findsNothing);
  });

  testWidgets('رنگِ ناموجود قابلِ انتخاب است و برچسب دارد', (t) async {
    final picks = <int>[];
    await t.pumpWidget(_Host(onPick: picks.add));
    await t.tap(find.bySemanticsLabel('رنگ سفید، ناموجود'));
    await t.pumpAndSettle();
    expect(picks, [1]);
    expect(find.text('ناموجود'), findsOneWidget);
  });

  test('رنگِ بدونِ سایز دیگر bloc را نمی‌شکند', () async {
    final bloc = ProductDetailVariantBloc();
    final v = ProductVariant(id: 1, isActive: true, sizeVariants: const [], images: const []);
    final states = <ProductDetailState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(ChangeProductColorEvent(v, null));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(states.single, isA<ProductDetailChangedState>());
    await sub.cancel();
    await bloc.close();
  });
  group('رنگ‌های زیاد: اسکرولِ افقی', () {
    List<VariantSwatch> many(int n) => [
          for (int i = 0; i < n; i++)
            VariantSwatch(name: 'شماره $i', color: Color(0xFF203040 + i * 0x1A2B3C)),
        ];

    Future<void> pump(WidgetTester t, int n, int sel) async {
      t.view.physicalSize = const Size(390, 200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: VariantSwatchPicker(
                swatches: many(n),
                selectedIndex: sel,
                tileSize: 60,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 900));
    }

    // کادرِ خودِ کاشی (بدونِ حلقه): ویجتِ Semantics هر کاشی
    Rect tileRect(WidgetTester t, String name) => t.getRect(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == 'رنگ شماره $name',
            skipOffstage: false,
          ),
        );

    testWidgets('حلقه‌ی کاشیِ اول (سمتِ راست در RTL) داخلِ کادر جا می‌شود',
        (t) async {
      await pump(t, 4, 0);
      final viewport = t.getRect(find.byType(SingleChildScrollView));
      final first = tileRect(t, '0');
      // دست‌کم ۴px (پهنای حلقه) تا لبه‌ی راستِ کادر فاصله دارد
      expect(viewport.right - first.right, greaterThanOrEqualTo(4));
    });

    testWidgets('رنگِ از قبل انتخاب‌شده‌ی آخر از همان اول دیده می‌شود',
        (t) async {
      await pump(t, 9, 8);
      final viewport = t.getRect(find.byType(SingleChildScrollView));
      final last = tileRect(t, '8');
      expect(last.left, greaterThanOrEqualTo(viewport.left));
      expect(last.right, lessThanOrEqualTo(viewport.right));
      // و کاشیِ اول حالا بیرونِ کادر است (یعنی واقعاً اسکرول خورده)
      expect(tileRect(t, '0').left, greaterThan(viewport.right));
    });

    testWidgets('با کشیدنِ افقی به رنگ‌های بعدی می‌رسیم', (t) async {
      await pump(t, 9, 0);
      final viewport = t.getRect(find.byType(SingleChildScrollView));
      expect(tileRect(t, '8').right, lessThan(viewport.left));
      await t.drag(find.byType(SingleChildScrollView), const Offset(600, 0));
      await t.pumpAndSettle();
      expect(tileRect(t, '8').left, greaterThanOrEqualTo(viewport.left));
    });
  });
}
