// lib/views/screens/my_course_loader_page.dart
//
// مسیرِ /my-course/<id>: صفحه‌ی دوره‌ی خریداری‌شده با آدرسِ قابلِ کپی.
//
// وقتی از فهرستِ «دوره‌های من» می‌آییم، خودِ آبجکتِ دوره همراهِ مسیر داده
// می‌شود و مستقیم صفحه باز می‌شود. ولی با رفرشِ صفحه‌ی وب یا باز کردنِ
// لینک، چیزی جز شناسه نداریم: اینجا اول ورود را مطمئن می‌شویم (اگر لازم
// بود صفحه‌ی ورود می‌آید و بعدِ ورود همین‌جا ادامه می‌دهیم)، بعد فهرستِ
// دوره‌های کاربر را می‌گیریم و دوره را با همان شناسه پیدا می‌کنیم.
import 'package:flutter/material.dart';

import 'package:persian_ball/constant/app_breakpoints.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:persian_ball/models/course_models.dart';
import 'package:persian_ball/services/auth_service.dart';
import 'package:persian_ball/services/course_service.dart';
import 'package:persian_ball/views/screens/my_course_detail_page.dart';
import 'package:persian_ball/views/widgets/app_buttons.dart';
import 'package:persian_ball/views/widgets/shimmer.dart';

class MyCourseLoaderPage extends StatefulWidget {
  const MyCourseLoaderPage({super.key, required this.courseId});

  /// شناسه‌ی دوره (همان `course_id`ِ بک‌اند، نه شناسه‌ی خرید)
  final int courseId;

  @override
  State<MyCourseLoaderPage> createState() => _MyCourseLoaderPageState();
}

enum _Phase { loading, needLogin, notFound, error, ready }

class _MyCourseLoaderPageState extends State<MyCourseLoaderPage> {
  _Phase _phase = _Phase.loading;
  MyCourse? _course;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!mounted) return;
    setState(() => _phase = _Phase.loading);
    if (!await AuthService.isLoggedIn()) {
      if (!mounted) return;
      // بعدِ ورودِ موفق صفحه‌ی ورود با true برمی‌گردد و همین‌جا ادامه می‌دهیم
      final ok = await Navigator.of(context)
          .pushNamed<bool>('/login', arguments: {'popOnSuccess': true});
      if (!mounted) return;
      if (ok != true) {
        setState(() => _phase = _Phase.needLogin);
        return;
      }
    }
    await _load();
  }

  Future<void> _load() async {
    try {
      // فهرستِ دوره‌های کاربر صفحه‌بندی دارد؛ تا پیدا شدن جلو می‌رویم
      String? next;
      MyCourse? found;
      do {
        final page =
            await CourseService.fetchUserCourses(context, nextPageUrl: next);
        for (final c in page.results) {
          if (c.courseId == widget.courseId) {
            found = c;
            break;
          }
        }
        next = page.next;
      } while (found == null && next != null && next.isNotEmpty);
      if (!mounted) return;
      setState(() {
        _course = found;
        _phase = found == null ? _Phase.notFound : _Phase.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'دریافتِ دوره ممکن نشد. اتصالت را بررسی کن.';
        _phase = _Phase.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.ready:
        return MyCourseDetailPage(myCourse: _course!);
      case _Phase.loading:
        return _Shell(child: _Skeleton());
      case _Phase.needLogin:
        return _Shell(
          child: _Message(
            icon: Icons.lock_outline_rounded,
            title: 'برای دیدنِ این دوره وارد شو',
            body: 'دوره‌های خریداری‌شده فقط در حسابِ خودت دیده می‌شوند.',
            primary: 'ورود به حساب',
            onPrimary: _start,
            secondary: 'صفحه‌ی اصلی',
            onSecondary: _goHome,
          ),
        );
      case _Phase.notFound:
        return _Shell(
          child: _Message(
            icon: Icons.school_outlined,
            title: 'این دوره در دوره‌های تو نیست',
            body: 'شاید هنوز تهیه‌اش نکرده‌ای یا با حسابِ دیگری خریده شده.',
            primary: 'دیدنِ دوره',
            onPrimary: () => Navigator.of(context)
                .pushReplacementNamed('/course/${widget.courseId}'),
            secondary: 'دوره‌های من',
            onSecondary: _goHome,
          ),
        );
      case _Phase.error:
        return _Shell(
          child: _Message(
            icon: Icons.wifi_off_rounded,
            title: 'مشکلی پیش آمد',
            body: _error ?? '',
            primary: 'تلاش دوباره',
            onPrimary: _start,
            secondary: 'صفحه‌ی اصلی',
            onSecondary: _goHome,
          ),
        );
    }
  }

  void _goHome() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed('/home');
    }
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.milk,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColor.ink,
          title: const Text('دوره‌ی من',
              style: TextStyle(fontFamily: 'Estedad', color: AppColor.ink)),
        ),
        body: child,
      ),
    );
  }
}

/// اسکلتونِ همان صفحه: کادرِ ویدیو، عنوان و چند ردیفِ درس.
class _Skeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool desktop = AppBreakpoints.isDesktop(context);
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: desktop ? 820 : 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Bone(radius: AppShapes.rLg),
                  ),
                  const SizedBox(height: 18),
                  const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Bone(width: 220, height: 18)),
                  const SizedBox(height: 8),
                  const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Bone(width: 140, height: 12)),
                  const SizedBox(height: 22),
                  for (int i = 0; i < 4; i++) ...[
                    const Bone(height: 64, radius: 14),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
  });

  final IconData icon;
  final String title, body, primary, secondary;
  final VoidCallback onPrimary, onSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const ShapeDecoration(
                    color: AppColor.pitchGreenSoft, shape: CircleBorder()),
                child: Icon(icon, size: 32, color: AppColor.pitchGreen),
              ),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColor.ink)),
              const SizedBox(height: 8),
              Text(body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 13,
                      height: 1.7,
                      color: AppColor.inkMuted)),
              const SizedBox(height: 20),
              GradientButton(label: primary, onPressed: onPrimary),
              const SizedBox(height: 10),
              SoftButton(label: secondary, onPressed: onSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
