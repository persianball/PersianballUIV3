// lib/views/screens/splash_router.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketky/constant/app_color.dart';

/// Decides initial route based on whether welcome was seen.
class SplashRouter extends StatelessWidget {
  const SplashRouter({super.key});

  Future<String> _decideInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('has_seen_welcome') ?? false;
    return seen ? '/home' : '/welcome';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _decideInitialRoute(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColor.obsidianBg,
            body: Center(child: CircularProgressIndicator(color: AppColor.goldEnd)),
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // اگر روی این صفحه چیز دیگری باز است (مثلاً یک دیپ‌لینک)، جایگزین
          // کردن، آن صفحه را می‌بندد نه این را. فقط وقتی خودمان رویِ پشته‌ایم.
          final route = ModalRoute.of(context);
          if (route == null || !route.isCurrent) return;
          Navigator.of(context).pushReplacementNamed(snapshot.data!);
        });
        return const Scaffold(backgroundColor: AppColor.obsidianBg);
      },
    );
  }
}