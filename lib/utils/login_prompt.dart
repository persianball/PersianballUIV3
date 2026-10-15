// utils/login_prompt.dart
//
// دیالوگ «ورود لازم است» با انیمیشن، و انتقالِ نرم به صفحه‌ی ورود.
// در بخش‌های مختلف صفحه‌ی خانه برای کاربر مهمان استفاده می‌شود.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persian_ball/bloc/login/login_bloc.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/constant/app_text_styles.dart';
import 'package:persian_ball/views/screens/login_page.dart';
import 'package:persian_ball/views/widgets/app_buttons.dart';

/// آیا کاربر (بر اساس LoginBloc) وارد شده است؟
bool isLoggedIn(BuildContext context) =>
    context.read<LoginBloc>().state is LoginAuthenticated;

/// اگر کاربر وارد نشده باشد: دیالوگ توضیحی با انیمیشن نمایش داده می‌شود و
/// در صورت تأیید، با ترنزیشن نرم به صفحه‌ی ورود می‌رود.
/// خروجی: true یعنی کاربر در پایان وارد است (از قبل یا پس از ورود موفق).
Future<bool> promptLoginIfNeeded(
  BuildContext context, {
  String message =
      'برای استفاده از این بخش ابتدا وارد حساب کاربری خود شوید.',
}) async {
  if (isLoggedIn(context)) return true;

  final bool? go = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'ورود',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, anim, __, ___) {
      final t = Curves.easeOutBack.transform(anim.value.clamp(0.0, 1.0));
      return Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.85 + 0.15 * t,
          child: const _LoginPromptCard(),
        ),
      );
    },
  ).then((v) => v);

  // نکته: پیام از طریق ویجت ثابت نمایش داده می‌شود؛ برای سادگی همان متن پیش‌فرض
  // استفاده می‌شود مگر اینکه فراخواننده متن دیگری بخواهد.
  if (go != true || !context.mounted) return false;

  final result = await Navigator.of(context).push<bool>(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => LoginPage(popOnSuccess: true),
      transitionsBuilder: (context, anim, __, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(position: slide, child: child),
        );
      },
    ),
  );
  return result == true;
}

class _LoginPromptCard extends StatelessWidget {
  const _LoginPromptCard();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppColor.card,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          // در نمایشگرهای بزرگ دیالوگ تمام‌عرض کشیده نشود.
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColor.greenGradient,
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              Text('ورود لازم است',
                  style: AppTextStyles.headlineMd
                      .copyWith(fontSize: 18, color: AppColor.ink)),
              const SizedBox(height: 8),
              Text(
                'برای استفاده از این بخش ابتدا وارد حساب کاربری خود شوید.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd
                    .copyWith(fontSize: 13, color: AppColor.inkMuted),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('بعداً'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GradientButton(
                      label: 'ورود',
                      height: 46,
                      fontSize: 13,
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
