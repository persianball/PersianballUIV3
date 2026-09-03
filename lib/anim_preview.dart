// موقتی: پیش‌نمایش انیمیشن افزودن به سبد
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/views/widgets/cart_flight_animation.dart';

void main() {
  timeDilation = 8.0;
  runApp(const _App());
}

class _App extends StatelessWidget {
  const _App();
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const _Home(),
      );
}

class _Home extends StatefulWidget {
  const _Home();
  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  final _key = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.milk,
      body: Stack(children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColor.card,
            child: Row(children: [
              Container(key: _key, width: 56, height: 56, color: AppColor.cardMuted,
                child: Image.asset('assets/images/placeholder.jpg', fit: BoxFit.contain)),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  final r = CartFlightOverlay.rectOf(_key);
                  if (r != null) {
                    CartFlightOverlay.launch(context, imageUrl: '', sourceRect: r);
                  }
                },
                child: const Text('go'),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
