import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/bloc/cart/cart_bloc.dart';
import 'package:marketky/bloc/login/login_bloc.dart';
import 'package:marketky/bloc/product_detail/product_detail_bloc.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:flutter/services.dart';
import 'package:marketky/views/screens/home_page.dart';
import 'package:marketky/views/screens/otp_verification_page.dart';
import 'package:marketky/views/screens/welcome_page.dart';

import 'bloc/product/product_bloc.dart';

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

class MyApp extends StatelessWidget {

  final authBloc = LoginBloc()..add(CheckAuthStatus());
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers:[
        BlocProvider(create: (context) => CartBloc()),
        BlocProvider(create: (context) => authBloc),
        BlocProvider(create: (context) => ProductBloc()),
        BlocProvider(create: (context) => ProductDetailBloc()),
        BlocProvider(create: (context) => ProductDetailVariantBloc() )
      ],
      child:
         MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            fontFamily: 'Estedad',
          ),
          home: SafeArea(child: WelcomePage()),
         )

    );
  }
}


//////////////////////////////////////////////////////////////////////////////


