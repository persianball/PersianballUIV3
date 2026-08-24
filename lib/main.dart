import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/bloc/cart/cart_bloc.dart';
import 'package:marketky/bloc/login/login_bloc.dart';
import 'package:marketky/bloc/product_detail/product_detail_bloc.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:flutter/services.dart';
import 'package:marketky/core/app_router.dart';
import 'package:marketky/core/fade_page_transitions.dart';
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
    statusBarColor: AppColor.obsidianBg,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColor.obsidianBg,
    systemNavigationBarIconBrightness: Brightness.light,
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
        // همه‌ی صفحات زنده‌ی اپ به تم Obsidian Gold Athletics بازطراحی
        // شده‌اند و رنگ خودشان را صریحاً ست می‌کنند؛ این colorScheme فقط
        // فالبک ویجت‌های استاندارد متریال (دیالوگ/اسنک‌بار/دکمه‌ی بدون
        // استایل و…) را از بنفش پیش‌فرض فلاتر به همین پالت طلایی/تیره
        // تغییر می‌دهد تا هیچ رنگ بنفشی در جایی از اپ باقی نماند.
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColor.obsidianBg,
          fontFamily: 'Estedad',
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColor.goldEnd,
            brightness: Brightness.dark,
            primary: AppColor.goldEnd,
            onPrimary: AppColor.onGold,
            secondary: AppColor.goldStart,
            onSecondary: AppColor.onGold,
            surface: AppColor.obsidianBg,
            onSurface: AppColor.onSurface,
            error: AppColor.errorDark,
            onError: AppColor.onGold,
          ),
          dialogTheme: DialogThemeData(
            // surfaceContainer فقط ۵٪ آلفا دارد؛ دیالوگ‌ها روی یک scrim
            // شفاف باز می‌شوند نه پس‌زمینه‌ی خودِ صفحه، پس با آن رنگ تقریباً
            // نامرئی/شفاف دیده می‌شدند. نسخه‌ی کدرشده استفاده می‌شود.
            backgroundColor: AppColor.surfaceContainerOpaque,
            shape: const RoundedRectangleBorder(),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: AppColor.surfaceContainerHigh,
            contentTextStyle: const TextStyle(
                fontFamily: 'Estedad', color: AppColor.onSurface),
            actionTextColor: AppColor.goldEnd,
            shape: const RoundedRectangleBorder(),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: AppColor.goldEnd,
          ),
          // ترنزیشن ورود/خروج یکدست (محو + سر خوردن ملایم از بالا) برای
          // همه‌ی صفحات اپ، چون MaterialPageRoute (همه‌جای اپ استفاده
          // می‌شود) وقتی ترنزیشن اختصاصی ندارد به همین تنظیم رجوع می‌کند.
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              for (final platform in TargetPlatform.values)
                platform: const FadeThroughTopPageTransitionsBuilder(),
            },
          ),
        ),
        // اپ لوکیل/جهت سراسری ست نمی‌کند، پس بدون این builder جهت پیش‌فرض
        // فلاتر (LTR) حاکم بود و هر صفحه مجبور بود خودش را دستی در
        // Directionality(rtl) بپیچد؛ خیلی جاها این کار فراموش شده بود یا
        // فقط بدنه را می‌پیچید نه AppBar را، و دکمه‌ی برگشت (leading) که
        // بر اساس همین جهت تصمیم می‌گیرد کدام‌طرف باشد، سمت چپ می‌افتاد.
        // این builder جهت RTL را برای کل اپ (همه‌ی روت‌ها، از جمله
        // AppBarها) یک‌جا تضمین می‌کند؛ Directionality(rtl) تکراری که
        // صفحات خودشان دارند بی‌ضرر و اضافی می‌ماند.
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        // initialRoute عمداً ست نشده: اگر مقداردهی شود، فلاتر وب همیشه
        // مسیر '/' را در بارگذاری اول باز می‌کند و آدرس واقعی مرورگر
        // (مثلاً /#/product/4) نادیده گرفته می‌شود. بدون آن، مسیر اولیه
        // به‌صورت خودکار از defaultRouteName (همان URL مرورگر) خوانده
        // می‌شود و لینک مستقیم به صفحات داخلی درست کار می‌کند.
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}


//////////////////////////////////////////////////////////////////////////////


