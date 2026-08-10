import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/bloc/login/login_bloc.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatefulWidget {
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {

  @override
  void initState() {

    super.initState();

    context.read<LoginBloc>().add(
        CheckAuthStatus()
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: BlocConsumer<LoginBloc,LoginState>(
        listener: (context,state){
          if(state is LoginAuthenticated){
            SharedPreferences.getInstance().then((p) async {
              await p.setBool('has_seen_welcome', true);
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/home');
              }
            });
          }
        },
        builder: (context,state) {
          print(state);
          if(state is LoginUnauthenticated){
            return Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Section 1 - Illustration
                  Container(
                    margin: EdgeInsets.only(top: 32),
                    width: MediaQuery.of(context).size.width,
                    child: SvgPicture.asset('assets/icons/welcome_page.svg'),
                  ),
                  // Section 2 - Marketky with Caption
                  Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'پرشین شاپ',
                          style: TextStyle(
                            color: AppColor.secondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 32,
                            fontFamily: 'Estedad',
                          ),
                        ),
                      ),
                      Text(
                        'رو به سوی پیشرفت',
                        style: TextStyle(fontFamily: 'Estedad',color: AppColor.secondary.withOpacity(0.7), fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  // Section 3 - Get Started Button
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    margin: EdgeInsets.only(bottom: 16),
                    child: ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('has_seen_welcome', true);
                        if (!mounted) return;
                        // Go to home (PageSwitcher). Login can be triggered when needed elsewhere.
                        Navigator.of(context).pushReplacementNamed('/home');
                      },
                      child: Text(
                        'شروع',
                        style: TextStyle(fontFamily: 'Estedad',color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 36, vertical: 18), backgroundColor: AppColor.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          else {
            return Container();
          }

        }
      ),
    );
  }
}
