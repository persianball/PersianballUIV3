// lib/views/screens/splash_router.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(snapshot.data!);
        });
        return const SizedBox.shrink();
      },
    );
  }
}