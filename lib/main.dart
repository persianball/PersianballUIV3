import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/bloc/cart/cart_bloc.dart';
import 'package:marketky/bloc/login/login_bloc.dart';
import 'package:marketky/bloc/product_detail/product_detail_bloc.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:flutter/services.dart';
import 'package:marketky/core/app_router.dart';
import 'package:marketky/bloc/address/address_bloc.dart';
import 'package:app_links/app_links.dart';
import 'package:marketky/core/deep_link_resolver.dart';

import 'bloc/product/product_bloc.dart';
import 'dart:async';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());




  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: AppColor.primary,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final authBloc = LoginBloc()..add(CheckAuthStatus());
  StreamSubscription? _linkSub;
  AppLinks? _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      _appLinks = AppLinks();

      // Cold start (initial link)
      final initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }

      // Runtime links stream
      _linkSub = _appLinks!.uriLinkStream.listen((uri) {
        _handleUri(uri);
      }, onError: (_) {});
    } catch (_) {}
  }

  void _handleUri(Uri uri) {
    final route = DeepLinkResolver.resolve(uri);
    // لینک ناشناس (مثلاً /media/... یا هاست غیرمجاز) نادیده گرفته می‌شود
    if (route == null || route == '/') return;
    _pushWhenReady(route);
  }

  /// در کلد استارت ممکن است Navigator هنوز ساخته نشده باشد؛ تا آماده شدن
  /// چند بار با فاصله کوتاه تلاش می‌کند.
  void _pushWhenReady(String route, {int attempt = 0}) {
    final navigator = appNavigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamed(route);
      return;
    }
    if (attempt >= 20) return; // حدود ۵ ثانیه
    Future.delayed(const Duration(milliseconds: 250), () {
      _pushWhenReady(route, attempt: attempt + 1);
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => CartBloc()),
        BlocProvider(create: (context) => authBloc),
        BlocProvider(create: (context) => ProductBloc()),
        BlocProvider(create: (context) => ProductDetailBloc()),
        BlocProvider(create: (context) => ProductDetailVariantBloc()),
        BlocProvider(create: (context) => AddressBloc()),
      ],
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'Estedad',
        ),
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: '/',
      ),
    );
  }
}


//////////////////////////////////////////////////////////////////////////////


