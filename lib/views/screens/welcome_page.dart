import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/bloc/login/login_bloc.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/views/widgets/page_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatefulWidget {
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();

    context.read<LoginBloc>().add(CheckAuthStatus());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.obsidianBg,
      body: SafeArea(
        child: BlocConsumer<LoginBloc, LoginState>(listener: (context, state) {
          if (state is LoginAuthenticated) {
            SharedPreferences.getInstance().then((p) async {
              await p.setBool('has_seen_welcome', true);
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/home');
              }
            });
          }
        }, builder: (context, state) {
          if (state is LoginUnauthenticated) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: PageContainer(
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Section 1 - Illustration
                            Container(
                              margin: EdgeInsets.only(top: 32),
                              width: double.infinity,
                              constraints: BoxConstraints(maxWidth: 480),
                              child: SvgPicture.asset(
                                  'assets/icons/welcome_page.svg'),
                            ),
                            // Section 2 - Marketky with Caption
                            Column(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    'پرشین شاپ',
                                    style: TextStyle(
                                      color: AppColor.goldEnd,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 32,
                                      fontFamily: 'Estedad',
                                    ),
                                  ),
                                ),
                                Text(
                                  'رو به سوی پیشرفت',
                                  style: TextStyle(
                                      fontFamily: 'Estedad',
                                      color: AppColor.onSurfaceVariant,
                                      fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            // Section 3 - Get Started Button
                            Container(
                              width: double.infinity,
                              constraints: BoxConstraints(maxWidth: 480),
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              margin: EdgeInsets.only(top: 24, bottom: 16),
                              child: ElevatedButton(
                                onPressed: () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool('has_seen_welcome', true);
                                  if (!mounted) return;
                                  // Go to home (PageSwitcher). Login can be triggered when needed elsewhere.
                                  Navigator.of(context)
                                      .pushReplacementNamed('/home');
                                },
                                child: Text(
                                  'شروع',
                                  style: TextStyle(
                                      fontFamily: 'Estedad',
                                      color: AppColor.onGold,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 36, vertical: 18),
                                  backgroundColor: AppColor.goldEnd,
                                  shape: const RoundedRectangleBorder(),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return Container();
          }
        }),
      ),
    );
  }
}
