// تب‌های اصلی باید تنبل ساخته شوند: باز شدنِ اپ نباید هر چهار صفحه (و
// درخواست‌ها و تصویرهایشان) را با هم راه بیندازد، ولی تبِ دیده‌شده بعد از
// رفتن به تبِ دیگر حالتش را نگه می‌دارد.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/views/widgets/motion.dart';

class _Probe extends StatefulWidget {
  const _Probe(this.name, this.log);
  final String name;
  final List<String> log;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.log.add(widget.name);
  }

  @override
  Widget build(BuildContext context) => Text(widget.name);
}

void main() {
  warmUpTests();
  testWidgets('فقط تبِ انتخاب‌شده ساخته می‌شود و بعد زنده می‌ماند',
      (tester) async {
    final log = <String>[];
    Widget app(int index) => MaterialApp(
          home: FadeIndexedStack(
            index: index,
            children: [
              _Probe('a', log),
              _Probe('b', log),
              _Probe('c', log),
            ],
          ),
        );

    await tester.pumpWidget(app(0));
    expect(log, ['a']);

    await tester.pumpWidget(app(2));
    await tester.pump(const Duration(milliseconds: 400));
    expect(log, ['a', 'c']);

    // برگشت: دوباره ساخته نمی‌شود (حالت حفظ شده)
    await tester.pumpWidget(app(0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(log, ['a', 'c']);
    expect(find.text('b'), findsNothing);
  });
}

// گرم‌کردنِ پس‌زمینه: بعد از مکث، تب‌های ندیده یکی‌یکی ساخته می‌شوند.
void warmUpTests() {
  testWidgets('تب‌های ندیده بعد از مکث یکی‌یکی ساخته می‌شوند', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: FadeIndexedStack(
        index: 0,
        warmUpAfter: const Duration(seconds: 4),
        children: [_Probe('a', log), _Probe('b', log), _Probe('c', log)],
      ),
    ));
    expect(log, ['a']);
    await tester.pump(const Duration(seconds: 4));
    expect(log, ['a', 'b']);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(log, ['a', 'b', 'c']);
    await tester.pump(const Duration(milliseconds: 1500));
  });
}
