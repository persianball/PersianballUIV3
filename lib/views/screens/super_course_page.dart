// lib/views/screens/super_course_page.dart
//
// صفحه‌ی سوپرکورس (مسیرِ آموزشی): معرفیِ مسیر و دوره‌هایش به ترتیب.
// هر دوره صفحه‌ی خودش را دارد (برنامه‌ی هفتگی، ویدیوها، خرید)، پس ضربه روی
// هر گام همان /course/<id> را باز می‌کند.
import 'package:flutter/material.dart';
import 'package:persian_ball/constant/app_breakpoints.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:persian_ball/constant/urls.dart';
import 'package:persian_ball/models/super_course.dart';
import 'package:persian_ball/services/super_course_service.dart';
import 'package:persian_ball/utils/ThousandsFormatter.dart';
import 'package:persian_ball/views/widgets/app_network_image.dart';
import 'package:persian_ball/views/widgets/course_path.dart';
import 'package:persian_ball/views/widgets/motion.dart';
import 'package:persian_ball/views/widgets/rich_description.dart';

/// آدرسِ کاملِ تصویر؛ سرور مسیرِ نسبی (/media/...) می‌دهد.
String superCourseMediaUrl(String raw) {
  final v = raw.trim();
  if (v.isEmpty || v.startsWith('http')) return v;
  return '${URLs.origin}${v.startsWith('/') ? v : '/$v'}';
}

class SuperCoursePage extends StatefulWidget {
  const SuperCoursePage({super.key, required this.idOrSlug, this.initial});

  /// شناسه یا نامِ انگلیسی (همان که در آدرس است)
  final String idOrSlug;

  /// داده‌ی کارتِ لیست تا جزئیات برسد (صفحه خالی نماند)
  final SuperCourse? initial;

  @override
  State<SuperCoursePage> createState() => _SuperCoursePageState();
}

class _SuperCoursePageState extends State<SuperCoursePage> {
  SuperCourse? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _data = widget.initial;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sc = await SuperCourseService.fetchDetail(widget.idOrSlug);
      if (!mounted) return;
      setState(() {
        _data = sc;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.obsidianBg,
        appBar: AppBar(
          backgroundColor: AppColor.obsidianBg,
          foregroundColor: AppColor.onSurface,
          elevation: 0,
          centerTitle: true,
          title: const Text('مسیر آموزشی',
              style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColor.onSurface)),
        ),
        body: data == null
            ? (_loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColor.goldEnd))
                : _errorView())
            : RefreshIndicator(
                color: AppColor.goldEnd,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    CenteredContent(maxWidth: 900, child: _content(data)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.route_rounded,
                  size: 48, color: AppColor.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(_error ?? 'خطا',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 14,
                      color: AppColor.onSurface)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                style: FilledButton.styleFrom(
                    backgroundColor: AppColor.goldEnd),
                child: const Text('تلاش دوباره',
                    style: TextStyle(fontFamily: 'Estedad')),
              ),
            ],
          ),
        ),
      );

  Widget _content(SuperCourse sc) {
    final cover = superCourseMediaUrl(sc.cover);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: ClipRRect(
            borderRadius: AppShapes.radius(AppShapes.rLg),
            // دسکتاپ: ۱۶:۹ در عرضِ ۹۰۰ حدودِ ۵۰۰px می‌شد و مسیر زیرِ تا
            // می‌رفت؛ ارتفاع ثابت می‌ماند و تصویر برش می‌خورد.
            child: AppBreakpoints.isDesktop(context)
                ? SizedBox(
                    height: 280,
                    width: double.infinity,
                    child: AppNetworkImage(
                      url: cover.isEmpty ? null : cover,
                      fit: BoxFit.cover,
                      fallbackAsset: 'assets/images/course_not_found.jpg',
                    ),
                  )
                : AspectRatio(
                    aspectRatio: 16 / 9,
                    child: AppNetworkImage(
                      url: cover.isEmpty ? null : cover,
                      fit: BoxFit.cover,
                      fallbackAsset: 'assets/images/course_not_found.jpg',
                    ),
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(sc.title,
              style: const TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColor.ink)),
        ),
        if (sc.nameEnglish.isNotEmpty && sc.nameEnglish != sc.title)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Text(sc.nameEnglish,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 12,
                    color: AppColor.onSurfaceVariant)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(Icons.layers_rounded, '${sc.courses.length} دوره'),
              if (sc.totalWeeks > 0)
                _chip(Icons.calendar_month_rounded, '${sc.totalWeeks} هفته'),
              if (sc.totalVideos > 0)
                _chip(Icons.play_circle_fill_rounded, '${sc.totalVideos} ویدیو'),
            ],
          ),
        ),
        if (sc.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: RichDescription(
              text: sc.description,
              style: const TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 14,
                  height: 1.8,
                  color: AppColor.onSurfaceVariant),
              strongColor: AppColor.onSurface,
            ),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text('دوره‌های این مسیر به ترتیب',
              style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColor.onSurface)),
        ),
        if (sc.courses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('دوره‌های این مسیر به‌زودی اضافه می‌شوند.',
                style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 13,
                    color: AppColor.onSurfaceVariant)),
          )
        else
          for (int i = 0; i < sc.courses.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FadeSlideIn(
                delay: Duration(milliseconds: 50 * (i % 8)),
                child: CoursePathStep(
                  index: i,
                  isLast: i == sc.courses.length - 1,
                  highlighted: i == 0,
                  child: _courseCard(sc.courses[i]),
                ),
              ),
            ),
      ],
    );
  }

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: ShapeDecoration(
          color: AppColor.pitchGreenSoft,
          shape: AppShapes.border(AppShapes.rMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColor.pitchGreen),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColor.pitchGreen)),
          ],
        ),
      );

  Widget _courseCard(SuperCourseItem c) {
    final image = superCourseMediaUrl(c.image);
    return Container(
      decoration: ShapeDecoration(
        color: AppColor.surfaceContainer,
        shape: AppShapes.border(AppShapes.rLg),
        shadows: AppColor.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppShapes.radius(AppShapes.rLg),
          onTap: () => Navigator.of(context).pushNamed('/course/${c.id}'),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: AppShapes.radius(AppShapes.rMd),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: AppNetworkImage(
                      url: image.isEmpty ? null : image,
                      fit: BoxFit.cover,
                      fallbackAsset: 'assets/images/course_not_found.jpg',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title.isEmpty ? 'دوره ${c.id}' : c.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w800,
                            color: AppColor.onSurface),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (c.weekCount > 0)
                            _mini(Icons.calendar_month_rounded,
                                '${c.weekCount} هفته'),
                          if (c.videoCount > 0)
                            _mini(Icons.play_circle_fill_rounded,
                                '${c.videoCount} ویدیو'),
                          if (c.difficulty.isNotEmpty)
                            _mini(Icons.military_tech_rounded, c.difficulty),
                          if (c.price > 0)
                            Text('${thousandSeparator(c.finalPrice)} تومان',
                                style: const TextStyle(
                                    fontFamily: 'Estedad',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.pitchGreen)),
                        ],
                      ),
                    ],
                  ),
                ),
                // در RTL آیکن آینه می‌شود: chevron_right رو به چپ (جلو) است
                const Icon(Icons.chevron_right_rounded,
                    color: AppColor.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mini(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColor.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 11.5,
                  color: AppColor.onSurfaceVariant)),
        ],
      );
}
