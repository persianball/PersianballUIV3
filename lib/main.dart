import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/bloc/cart/cart_bloc.dart';
import 'package:marketky/services/auth_service.dart';
import 'package:marketky/bloc/login/login_bloc.dart';
import 'package:marketky/bloc/product_detail/product_detail_bloc.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:flutter/services.dart';
import 'package:marketky/core/app_router.dart';
import 'package:marketky/core/fade_page_transitions.dart';
import 'package:marketky/bloc/address/address_bloc.dart';
import 'package:app_links/app_links.dart';
import 'package:marketky/core/deep_link_resolver.dart';
import 'package:marketky/views/widgets/animated_gradient_background.dart';

import 'bloc/product/product_bloc.dart';
import 'dart:async';
import 'package:marketky/services/slider_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // سرور گالری کند است (TTFB حدود ۲ تا ۶ ثانیه). کشِ دیسک را قبل از اولین
  // فریم می‌خوانیم تا اسلایدرها فوراً چیزی نشان دهند، و واکشیِ تازه را در
  // پس‌زمینه شروع می‌کنیم تا هزینه‌اش با اسپلش/خوش‌آمد همپوشانی کند.
  await SliderService.warmUp();
  SliderService.prefetchAll();

  runApp(MyApp());




  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: AppColor.milk,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColor.milk,
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
      child: _AuthChangeReloader(
        child: MaterialApp(
        navigatorKey: appNavigatorKey,
        debugShowCheckedModeBanner: false,
        // تم «چمن و شیر»: پس‌زمینه‌ی شیری، سطح کارت سفید برجسته با سایه‌ی
        // نرم، و سبز چمن فوتبال به‌عنوان رنگ اکشن. گوشه‌ها همه‌جا اسکوئرکل
        // (انحنای پیوسته به سبک اپل) هستند، نه کمان دایره‌ای.
        theme: ThemeData(
          useMaterial3: true,
          // پس‌زمینه‌ی صفحه‌ها شفاف است تا گرادیانِ متحرکِ سراسری
          // (AnimatedGradientBackground در builder) از پشت دیده شود.
          scaffoldBackgroundColor: Colors.transparent,
          fontFamily: 'Estedad',
          splashFactory: InkSparkle.splashFactory,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColor.pitchGreen,
            brightness: Brightness.light,
            primary: AppColor.pitchGreen,
            onPrimary: AppColor.onPitchGreen,
            secondary: AppColor.pitchGreenLight,
            onSecondary: AppColor.onPitchGreen,
            surface: AppColor.card,
            onSurface: AppColor.ink,
            surfaceContainerHighest: AppColor.cardMuted,
            outline: AppColor.lineStrong,
            outlineVariant: AppColor.line,
            error: AppColor.danger,
            onError: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColor.milk,
            surfaceTintColor: Colors.transparent,
            foregroundColor: AppColor.ink,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontFamily: 'Estedad',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColor.ink,
            ),
          ),
          cardTheme: CardThemeData(
            color: AppColor.card,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape: AppShapes.border(AppShapes.rMd),
            margin: EdgeInsets.zero,
          ),
          dividerTheme: const DividerThemeData(
            color: AppColor.line,
            thickness: 1,
            space: 1,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppColor.card,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape: AppShapes.border(AppShapes.rLg),
            titleTextStyle: const TextStyle(
              fontFamily: 'Estedad',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColor.ink,
            ),
            contentTextStyle: const TextStyle(
              fontFamily: 'Estedad',
              fontSize: 14,
              color: AppColor.inkMuted,
            ),
          ),
          bottomSheetTheme: BottomSheetThemeData(
            backgroundColor: AppColor.card,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            modalBackgroundColor: AppColor.card,
            modalElevation: 0,
            shape: AppShapes.borderTop(AppShapes.rXl),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: AppColor.ink,
            contentTextStyle: const TextStyle(
                fontFamily: 'Estedad', color: Colors.white),
            actionTextColor: AppColor.pitchGreenLight,
            behavior: SnackBarBehavior.floating,
            shape: AppShapes.border(AppShapes.rMd),
          ),
          popupMenuTheme: PopupMenuThemeData(
            color: AppColor.card,
            surfaceTintColor: Colors.transparent,
            elevation: 8,
            shadowColor: const Color(0x2214261B),
            shape: AppShapes.border(AppShapes.rMd),
            textStyle: const TextStyle(
                fontFamily: 'Estedad', fontSize: 14, color: AppColor.ink),
          ),
          menuTheme: MenuThemeData(
            style: MenuStyle(
              backgroundColor: const WidgetStatePropertyAll(AppColor.card),
              surfaceTintColor:
                  const WidgetStatePropertyAll(Colors.transparent),
              elevation: const WidgetStatePropertyAll(8),
              shape: WidgetStatePropertyAll(AppShapes.border(AppShapes.rMd)),
            ),
          ),
          tooltipTheme: TooltipThemeData(
            decoration: ShapeDecoration(
              color: AppColor.ink,
              shape: AppShapes.pill,
            ),
            textStyle: const TextStyle(
                fontFamily: 'Estedad', fontSize: 12, color: Colors.white),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.pitchGreen,
              foregroundColor: AppColor.onPitchGreen,
              elevation: 0,
              shape: AppShapes.pill,
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              textStyle: const TextStyle(
                fontFamily: 'Estedad',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColor.pitchGreen,
              side: const BorderSide(color: AppColor.pitchGreen),
              shape: AppShapes.pill,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(
                fontFamily: 'Estedad',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColor.pitchGreen,
              shape: AppShapes.pill,
              textStyle: const TextStyle(
                fontFamily: 'Estedad',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: AppColor.card,
            selectedColor: AppColor.pitchGreenSoft,
            side: const BorderSide(color: AppColor.line),
            shape: AppShapes.pill,
            labelStyle: const TextStyle(
              fontFamily: 'Estedad',
              fontSize: 13,
              color: AppColor.ink,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColor.card,
            hintStyle: const TextStyle(
                fontFamily: 'Estedad', color: AppColor.inkMuted, fontSize: 13),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: AppShapes.radius(AppShapes.rMd),
              borderSide: const BorderSide(color: AppColor.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppShapes.radius(AppShapes.rMd),
              borderSide: const BorderSide(color: AppColor.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppShapes.radius(AppShapes.rMd),
              borderSide:
                  const BorderSide(color: AppColor.pitchGreen, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppShapes.radius(AppShapes.rMd),
              borderSide: const BorderSide(color: AppColor.danger),
            ),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: AppColor.pitchGreen,
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
          child: Stack(
            children: [
              const Positioned.fill(child: AnimatedGradientBackground()),
              child ?? const SizedBox.shrink(),
            ],
          ),
        ),
        // initialRoute عمداً ست نشده: اگر مقداردهی شود، فلاتر وب همیشه
        // مسیر '/' را در بارگذاری اول باز می‌کند و آدرس واقعی مرورگر
        // (مثلاً /#/product/4) نادیده گرفته می‌شود. بدون آن، مسیر اولیه
        // به‌صورت خودکار از defaultRouteName (همان URL مرورگر) خوانده
        // می‌شود و لینک مستقیم به صفحات داخلی درست کار می‌کند.
        onGenerateRoute: AppRouter.onGenerateRoute,
        // رفتار پیش‌فرض فلاتر برای مسیر اولیه‌ی چندبخشی، پشته را از روی
        // بخش‌های مسیر می‌سازد: '/course/20' تبدیل می‌شود به
        // ['/', '/course', '/course/20']. آن '/' یعنی SplashRouter هم ساخته
        // می‌شود و بعد از یک فریم pushReplacementNamed می‌زند، که صفحه‌ی
        // دیپ‌لینک‌شده را با '/welcome' یا '/home' جایگزین می‌کرد؛ یعنی
        // رفرشِ /#/course/20 کاربر را به صفحه‌ی خوش‌آمد می‌انداخت.
        // اینجا پشته صریحاً ساخته می‌شود: خانه در پایین (تا دکمه‌ی برگشت
        // کار کند) و خودِ مسیر دیپ‌لینک روی آن.
        onGenerateInitialRoutes: (initialRoute) {
          if (initialRoute == '/' || initialRoute.isEmpty) {
            return [
              AppRouter.onGenerateRoute(const RouteSettings(name: '/')),
            ];
          }
          return [
            AppRouter.onGenerateRoute(const RouteSettings(name: '/home')),
            AppRouter.onGenerateRoute(RouteSettings(name: initialRoute)),
          ];
        },
      ),
      ),
    );
  }
}

/// وقتی کاربر وارد یا خارج می‌شود، سبد را دوباره می‌خواند.
///
/// بدون این، ورودِ وسطِ کار روی صفحه‌های از قبل ساخته‌شده اثری نداشت:
/// صفحه‌ی خانه LoadCart را فقط در initState می‌فرستد، پس بعد از بازگشت از
/// صفحه‌ی ورود، بجِ تعداد سبد روی صفر می‌ماند. اینجا بالای درخت نشسته تا
/// همه‌ی صفحه‌ها با یک‌بار خواندن به‌روز شوند، نه اینکه هر صفحه جدا فکرش را
/// بکند.
class _AuthChangeReloader extends StatefulWidget {
  const _AuthChangeReloader({required this.child});

  final Widget child;

  @override
  State<_AuthChangeReloader> createState() => _AuthChangeReloaderState();
}

class _AuthChangeReloaderState extends State<_AuthChangeReloader> {
  @override
  void initState() {
    super.initState();
    AuthService.authRevision.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    AuthService.authRevision.removeListener(_onAuthChanged);
    super.dispose();
  }

  /// خروج هم مثل ورود مهم است: LoadCart برای کاربر بدون توکن
  /// CartRequiresLogin می‌دهد و بج صفر می‌شود.
  void _onAuthChanged() {
    if (!mounted) return;
    context.read<CartBloc>().add(LoadCart(context));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}


//////////////////////////////////////////////////////////////////////////////


