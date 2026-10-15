// lib/views/screens/course_detail_page.dart
import 'package:flutter/material.dart';
import 'package:marketky/views/widgets/app_buttons.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketky/constant/app_breakpoints.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/urls.dart';
import 'package:marketky/models/course_detail_model.dart';
import 'package:marketky/services/course_progress_service.dart';
import 'package:marketky/services/course_service.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/views/widgets/modals/add_course_to_cart_modal.dart';
import 'package:marketky/bloc/cart/cart_bloc.dart';
import 'package:marketky/views/widgets/detail_tabs.dart';
import 'package:marketky/views/widgets/shimmer.dart';
import 'package:marketky/views/widgets/modals/video_player_dialog.dart';
import 'package:marketky/views/widgets/locked_lessons_veil.dart';

class CourseDetailPage extends StatefulWidget {
  final int id;
  const CourseDetailPage({super.key, required this.id});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage>
    with SingleTickerProviderStateMixin {
  late Future<CourseDetailResponse> _future;

  /// آخرین داده‌ی موفق؛ هنگام «کشیدن برای تازه‌سازی» نگه داشته می‌شود تا
  /// محتوای صفحه با یک اسپینر تمام‌صفحه جایگزین نشود.
  CourseDetailResponse? _lastData;

  /// واریانتِ انتخاب‌شده (زمان/مکان برگزاری). پیش‌تر دکمه‌ی خرید همیشه
  /// اولین واریانتِ فعال را می‌فرستاد، پس دوره‌های چندزمانه عملاً فقط یک
  /// گزینه‌ی قابل‌خرید داشتند.
  int? _selectedVariantId;

  /// پیشرفتِ تماشا روی همین دستگاه (کدام ویدیو تا کجا دیده شده).
  CourseProgress _progress = CourseProgress.empty;

  /// هفته‌ی بازِ آکاردئون، به‌شکلِ «محدوده|شماره» (محدوده خالی = خودِ دوره،
  /// c<id> = یک زیرمجموعه). هر زیرمجموعه هفته‌ی ۱ خودش را دارد، پس شماره‌ی
  /// هفته به‌تنهایی یکتا نیست. با ورود به صفحه هفته‌ی اول باز است.
  String? _openWeek;

  /// زیرمجموعه‌های بازِ یک دوره‌ی مجموعه‌ای
  final Set<int> _openSubCourses = <int>{};

  /// پیشنهادِ «ادامه‌ی تماشا» در هر بار ورود فقط یک‌بار نشان داده می‌شود.
  bool _resumeAsked = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _future = CourseService.fetchCourseDetail(id: widget.id);
    // اولین واریانتِ فعال از ابتدا انتخاب می‌شود تا دکمه‌ی خرید هیچ‌وقت
    // بدون گزینه نماند.
    _future.then((data) {
      if (!mounted) return;
      _lastData = data;
      _openFirstWeek(data);
      _maybeOfferResume(data);
      if (_selectedVariantId != null) return;
      final active = _activeVariants(data);
      if (active.isNotEmpty) setState(() => _selectedVariantId = active.first.id);
    }).catchError((_) {});
  }

  /// «کشیدن برای تازه‌سازی»: جزییات دوره را دوباره می‌گیرد. اگر واریانتِ
  /// انتخاب‌شده دیگر فعال نباشد، اولین واریانت فعالِ جدید انتخاب می‌شود.
  Future<void> _refresh() async {
    final future = CourseService.fetchCourseDetail(id: widget.id);
    setState(() => _future = future);
    try {
      final data = await future;
      if (!mounted) return;
      _lastData = data;
      final active = _activeVariants(data);
      final stillValid = active.any((v) => v.id == _selectedVariantId);
      if (!stillValid) {
        setState(() =>
            _selectedVariantId = active.isEmpty ? null : active.first.id);
      }
    } catch (_) {
      // خطا را همان FutureBuilder نمایش می‌دهد
    }
  }

  List<CourseTimeAndLocationItem> _activeVariants(CourseDetailResponse data) =>
      data.detail.timeAndLocation.where((v) => v.isActive).toList();

  /// واریانتِ فعالِ انتخاب‌شده؛ اگر انتخاب معتبر نبود، اولین فعال.
  CourseTimeAndLocationItem? _selectedVariant(CourseDetailResponse data) =>
      pickCourseVariant(data.detail.timeAndLocation, _selectedVariantId);

  void _selectVariant(CourseTimeAndLocationItem item) {
    if (!item.isActive || _selectedVariantId == item.id) return;
    setState(() => _selectedVariantId = item.id);
  }

  /// قیمت آیتم زمان و مکان: قیمت نهایی، بج قرمز درصد تخفیف و قیمت اصلی خط‌خورده
  Widget _timeLocationPrice(CourseTimeAndLocationItem item) {
    final int percent = item.discountPercentage;
    final bool hasDiscount = percent > 0 && percent < 100 && item.price > 0;
    final int finalPrice =
        hasDiscount ? (item.price * (1 - percent / 100)).toInt() : item.price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${thousandSeparator(finalPrice)} تومان',
          style: const TextStyle(
            fontFamily: 'Estedad',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColor.goldEnd,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red,
                ),
                child: Text(
                  '٪$percent',
                  style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                thousandSeparator(item.price),
                style: const TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColor.onSurfaceVariant,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColor.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// بج اطلاعات دوره با آیکن و رنگ اختصاصی
  Widget _infoChip(String label, {required IconData icon, required Color color}) {
    return PillTag(label: label, icon: icon, color: color);
  }

  /// کاور پیش‌فرض بخش‌های هفته
  Widget _sectionFallbackThumb() => Image.asset(
        'assets/images/course_not_found.jpg',
        width: 56,
        height: 36,
        fit: BoxFit.cover,
      );

  /// پیشرفتِ ذخیره‌شده‌ی این دوره را از حافظه‌ی محلی می‌خواند.
  Future<void> _loadProgress() async {
    final p = await CourseProgressService.load(widget.id);
    if (!mounted) return;
    setState(() => _progress = p);
    final data = _lastData;
    if (data != null) _maybeOfferResume(data);
  }

  void _openFirstWeek(CourseDetailResponse data) {
    if (_openWeek != null) return;
    if (data.detail.isBundle) {
      final first = data.detail.subCourses.first;
      setState(() {
        _openSubCourses.add(first.id);
        if (first.weekGroups.isNotEmpty) {
          _openWeek = _weekId('c${first.id}', first.weekGroups.first.weekNumber);
        }
      });
      return;
    }
    if (data.detail.weekGroups.isEmpty) return;
    setState(() => _openWeek = _weekId('', data.detail.weekGroups.first.weekNumber));
  }

  /// شناسه‌ی یک هفته در آکاردئون
  String _weekId(String scope, String weekNumber) => '$scope|$weekNumber';

  /// باز کردنِ مسیرِ رسیدن به یک ویدیو (زیرمجموعه‌ها + هفته)
  void _reveal(_Located f) {
    setState(() {
      _openSubCourses.addAll(f.path);
      _openWeek = _weekId(f.scope, f.weekNumber);
    });
  }

  /// شناسه‌ی پایدارِ یک ویدیو: آدرسِ ویدیو، و اگر نبود هفته+عنوان.
  ///
  /// برای خودِ دوره (scope خالی) دقیقاً همان قالبِ قبلی است تا پیشرفت‌های
  /// ذخیره‌شده معتبر بمانند؛ در زیرمجموعه‌ها شناسه‌ی دوره هم وارد می‌شود
  /// چون هر کدام «هفته‌ی ۱» خودش را دارد.
  String _sectionKey(CourseWeekSectionItem s, String weekNumber,
      [String scope = '']) {
    final url = (s.videoUrl ?? '').trim();
    if (url.isNotEmpty) return url;
    return scope.isEmpty
        ? 'w$weekNumber::${s.title}'
        : '$scope/w$weekNumber::${s.title}';
  }

  String _clock(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$sec' : '$m:$sec';
  }

  /// «۳ روز پیش» و مانندِ آن، برای اینکه کاربر بفهمد کِی رها کرده بود.
  String _ago(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'همین حالا';
    if (diff.inMinutes < 60) return '${diff.inMinutes} دقیقه پیش';
    if (diff.inHours < 24) return '${diff.inHours} ساعت پیش';
    if (diff.inDays < 30) return '${diff.inDays} روز پیش';
    return '${diff.inDays ~/ 30} ماه پیش';
  }

  /// ویدیوی متناظر با یک پیشرفتِ ذخیره‌شده را در داده‌ی دوره پیدا می‌کند.
  _Located? _findSection(CourseDetailResponse data, String key) {
    for (final week in data.detail.weekGroups) {
      for (final s in week.allSections) {
        if (_sectionKey(s, week.weekNumber) == key) {
          return _Located(s, week.weekNumber, '', const []);
        }
      }
    }
    _Located? walk(List<SubCourse> subs, List<int> path) {
      for (final c in subs) {
        final scope = 'c${c.id}';
        final here = [...path, c.id];
        for (final week in c.weekGroups) {
          for (final s in week.allSections) {
            if (_sectionKey(s, week.weekNumber, scope) == key) {
              return _Located(s, week.weekNumber, scope, here,
                  courseTitle: c.title);
            }
          }
        }
        final deeper = walk(c.subCourses, here);
        if (deeper != null) return deeper;
      }
      return null;
    }

    return walk(data.detail.subCourses, const []);
  }

  /// یک‌بار در هر ورود: اگر ویدیوی نیمه‌کاره‌ای هست، ادامه‌اش را پیشنهاد بده.
  void _maybeOfferResume(CourseDetailResponse data) {
    if (_resumeAsked) return;
    final last = _progress.last;
    if (last == null || !last.resumable) return;
    final found = _findSection(data, last.key);
    if (found == null) return;
    _resumeAsked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showResumeDialog(last, found);
    });
  }

  Future<void> _showResumeDialog(VideoProgress p, _Located found) async {
    final section = found.section;
    final weekNumber = found.weekNumber;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColor.surfaceContainer,
          shape: AppShapes.border(AppShapes.rLg),
          title: Row(
            children: const [
              Icon(Icons.history_rounded, color: AppColor.pitchGreen),
              SizedBox(width: 8),
              Text('ادامه‌ی تماشا',
                  style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColor.onSurface)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.title.isEmpty ? section.title : p.title,
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColor.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                '${found.courseTitle != null ? '${found.courseTitle}، ' : ''}هفته $weekNumber، ${_ago(p.updatedAt)}',
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 12,
                    color: AppColor.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: p.fraction,
                  minHeight: 6,
                  backgroundColor: AppColor.surfaceContainerHigh,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColor.pitchGreen),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'تا دقیقه‌ی ${_clock(p.position)} از ${_clock(p.duration)} دیده‌اید',
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 12,
                    color: AppColor.onSurfaceVariant),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('بعداً',
                  style: TextStyle(
                      fontFamily: 'Estedad',
                      color: AppColor.onSurfaceVariant)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColor.pitchGreen,
                foregroundColor: AppColor.onPitchGreen,
                shape: AppShapes.border(AppShapes.rMd),
              ),
              child: const Text('ادامه بده',
                  style: TextStyle(
                      fontFamily: 'Estedad', fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    if (go != true || !mounted) return;
    _reveal(found);
    _onSectionTap(section, weekNumber, found.scope);
  }

  /// کارتِ «ادامه‌ی تماشا» بالای برنامه‌ی هفتگی — همیشه در دسترس، برخلافِ
  /// دیالوگ که یک‌بار می‌آید.
  Widget? _resumeCard(CourseDetailResponse data) {
    final last = _progress.last;
    if (last == null) return null;
    final found = _findSection(data, last.key);
    if (found == null) return null;
    final section = found.section;
    final weekNumber = found.weekNumber;
    final where = found.courseTitle != null ? '${found.courseTitle}، ' : '';
    final bool done = last.seen;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: ShapeDecoration(
        color: AppColor.pitchGreenSoft,
        shape: AppShapes.border(AppShapes.rLg),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppShapes.radius(AppShapes.rLg),
          onTap: () {
            _reveal(found);
            _onSectionTap(section, weekNumber, found.scope);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(done ? Icons.replay_rounded : Icons.play_circle_fill,
                    color: AppColor.pitchGreen, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        done ? 'دوباره ببینید' : 'ادامه‌ی تماشا',
                        style: const TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColor.pitchGreen),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        last.title.isEmpty ? section.title : last.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColor.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        done
                            ? '$whereهفته $weekNumber، کامل دیده شده، ${_ago(last.updatedAt)}'
                            : '$whereهفته $weekNumber، دقیقه‌ی ${_clock(last.position)}، ${_ago(last.updatedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 11,
                            color: AppColor.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// زیرعنوانِ هفته: تعداد ویدیو و اینکه چندتایش دیده شده.
  String _weekSubtitle(CourseWeekGroup week, [String scope = '']) {
    final total = week.allSections.length;
    final seen = week.allSections
        .where((s) => _progress.isSeen(_sectionKey(s, week.weekNumber, scope)))
        .length;
    if (seen == 0) return '$total ویدیو';
    if (seen == total) return '$total ویدیو، همه دیده شد';
    return '$total ویدیو، $seen دیده شد';
  }

  /// خطِ وضعیتِ زیرِ عنوانِ ویدیو در لیستِ هفته.
  Widget _watchStatus(VideoProgress p) {
    if (p.seen) {
      return const Padding(
        padding: EdgeInsets.only(top: 3),
        child: Text('دیده شد',
            style: TextStyle(
                fontFamily: 'Estedad',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColor.successDark)),
      );
    }
    if (p.fraction <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: p.fraction,
              minHeight: 4,
              backgroundColor: AppColor.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation(AppColor.pitchGreen),
            ),
          ),
          const SizedBox(height: 3),
          Text('تا دقیقه‌ی ${_clock(p.position)} دیده‌اید',
              style: const TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 10,
                  color: AppColor.onSurfaceVariant)),
        ],
      ),
    );
  }

  void _onSectionTap(CourseWeekSectionItem section, String weekNumber,
      [String scope = '']) {
    if (section.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('این ویدیو قفل است، ابتدا دوره را تهیه کنید')),
      );
      return;
    }
    final url = section.videoUrl;
    if ((url ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ویدیویی برای این بخش موجود نیست')),
      );
      return;
    }
    final key = _sectionKey(section, weekNumber, scope);
    final saved = _progress.of(key);
    showVideoPlayerDialog(
      context,
      videoUrl: _abs(url!),
      title: section.title,
      // ادامه از جایی که رها شده بود (ویدیوی تمام‌شده از اول پخش می‌شود).
      startAt: (saved != null && saved.resumable) ? saved.position : Duration.zero,
      onProgress: (p) async {
        final next = await CourseProgressService.record(
          widget.id,
          key: key,
          title: section.title,
          weekNumber: weekNumber,
          position: p.position,
          duration: p.duration,
          seen: p.finished ? true : null,
        );
        if (mounted) setState(() => _progress = next);
      },
    );
  }

  String _abs(String rel) {
    if (rel.isEmpty) return '';
    if (rel.startsWith('http')) return rel;
    return '${URLs.baseUrl}$rel';
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}ساعت ${minutes}دقیقه';
    return '${minutes}دقیقه';
  }

  /// همه‌ی ویدیوهای این هفته قفل‌اند (هنوز خریداری نشده)
  bool _isWeekLocked(CourseWeekGroup week) {
    final all = week.allSections;
    return all.isNotEmpty && all.every((s) => s.isLocked);
  }

  /// می‌شود از روی پرده‌ی قفل مستقیم به خرید رفت؟
  bool get _canPurchase {
    final data = _lastData;
    return data != null && _selectedVariant(data) != null;
  }

  /// همان شیتِ «افزودن به سبد» دکمه‌ی اصلی، برای پرده‌ی ویدیوهای قفل.
  void _openPurchase() {
    final data = _lastData;
    final selected = data == null ? null : _selectedVariant(data);
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('این دوره فعلاً قابل خرید نیست')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddCourseToCartModal(courseItem: selected),
    );
  }

  /// چیپِ قرصیِ کوچک در کارتِ زمان و مکان (وضعیت، ظرفیت)
  Widget _variantChip(String label, {required Color color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: ShapeDecoration(
          color: color.withValues(alpha: 0.12),
          shape: AppShapes.pill,
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: 'Estedad',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      );

  Widget _lockedChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: ShapeDecoration(
          color: AppColor.onSurfaceVariant.withValues(alpha: 0.12),
          shape: AppShapes.pill,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: 11, color: AppColor.onSurfaceVariant),
            SizedBox(width: 3),
            Text('قفل',
                style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColor.onSurfaceVariant)),
          ],
        ),
      );

  /// یک هفته‌ی برنامه. [scope] خالی یعنی خودِ دوره، c<id> یعنی یک زیرمجموعه.
  Widget _weekCard(CourseWeekGroup week,
      {String scope = '', int index = 0, double hMargin = 16}) {
    final id = _weekId(scope, week.weekNumber);
    final locked = _isWeekLocked(week);
    return _AnimatedSlideFade(
      delayMs: 50 * index,
      child: Container(
        margin: EdgeInsets.fromLTRB(hMargin, 8, hMargin, 8),
        decoration: ShapeDecoration(
          color: AppColor.surfaceContainer,
          shape: AppShapes.border(AppShapes.rLg),
          shadows: AppColor.cardShadow,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              unselectedWidgetColor: AppColor.onSurfaceVariant),
          child: ExpansionTile(
            // کلید شاملِ هفته‌ی باز است تا با «ادامه‌ی تماشا» همان هفته
            // باز شود.
            key: ValueKey('week_${id}_$_openWeek'),
            initiallyExpanded: id == _openWeek,
            onExpansionChanged: (open) => _openWeek = open ? id : null,
            iconColor: AppColor.goldEnd,
            collapsedIconColor: AppColor.onSurfaceVariant,
            title: Row(
              children: [
                Flexible(
                  child: Text('هفته ${week.weekNumber}',
                      style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontWeight: FontWeight.w700,
                          color: AppColor.onSurface)),
                ),
                if (locked) ...[const SizedBox(width: 8), _lockedChip()],
              ],
            ),
            subtitle: Text(
                locked
                    ? '${week.allSections.length} ویدیو، پس از تهیه‌ی دوره باز می‌شود'
                    : _weekSubtitle(week, scope),
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 11,
                    color: AppColor.onSurfaceVariant)),
            children: [
              // هفته‌ی کاملاً قفل: همه‌ی گروه‌ها زیرِ یک پرده‌ی تار، نه یک
              // پرده برای هر گروه.
              if (locked)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: LockedLessonsVeil(
                    count: week.allSections.length,
                    onUnlock: _canPurchase ? _openPurchase : null,
                    message:
                        'با تهیه‌ی دوره، همه‌ی جلسه‌های این هفته باز می‌شوند',
                    child: Column(
                      children: [
                        for (final g in week.groups)
                          _groupBlock(g, week, scope,
                              veilLocked: false,
                              margin: const EdgeInsets.only(bottom: 8)),
                      ],
                    ),
                  ),
                )
              else
                for (final g in week.groups) _groupBlock(g, week, scope),
            ],
          ),
        ),
      ),
    );
  }

  /// یک گروهِ داخلِ هفته. اگر بخشی از ویدیوهایش قفل باشد، بازها عادی و
  /// قفل‌ها زیرِ پرده‌ی تار می‌آیند.
  Widget _groupBlock(CourseWeek group, CourseWeekGroup week, String scope,
      {bool veilLocked = true,
      EdgeInsets margin = const EdgeInsets.fromLTRB(12, 0, 12, 12)}) {
    final lockedItems = group.sections.where((s) => s.isLocked).toList();
    final showVeil = veilLocked && lockedItems.isNotEmpty;
    final plain = showVeil
        ? group.sections.where((s) => !s.isLocked).toList()
        : group.sections;
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(8),
      decoration: ShapeDecoration(
        color: AppColor.obsidianBg,
        shape: AppShapes.border(AppShapes.rLg),
        shadows: AppColor.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if ((group.weekName ?? '').trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
              child: Row(
                children: [
                  const Icon(Icons.folder_open_rounded,
                      size: 15, color: AppColor.pitchGreen),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      group.weekName!.trim(),
                      style: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColor.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '${group.sections.length}',
                    style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 11,
                      color: AppColor.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          for (int i = 0; i < plain.length; i++)
            _lessonTile(plain[i], week, scope, i,
                isLast: i == plain.length - 1 && !showVeil),
          if (showVeil) ...[
            if (plain.isNotEmpty) const SizedBox(height: 8),
            LockedLessonsVeil(
              count: lockedItems.length,
              onUnlock: _canPurchase ? _openPurchase : null,
              child: Column(
                children: [
                  for (int i = 0; i < lockedItems.length; i++)
                    _lessonTile(lockedItems[i], week, scope, i,
                        isLast: i == lockedItems.length - 1),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// یک ردیفِ ویدیو
  Widget _lessonTile(
      CourseWeekSectionItem s, CourseWeekGroup week, String scope, int i,
      {required bool isLast}) {
    final watched = _progress.of(_sectionKey(s, week.weekNumber, scope));
    return _AnimatedSlideFade(
      delayMs: 40 * i,
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
        decoration: BoxDecoration(
          color: AppColor.surfaceContainer,
          border: Border.all(color: AppColor.outlineVariantDark),
        ),
        child: ListTile(
          dense: true,
          // ویدیوهای باز با انیمیشن در دیالوگ پخش می‌شوند
          onTap: () => _onSectionTap(s, week.weekNumber, scope),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          leading: Icon(
              s.isLocked
                  ? Icons.lock
                  : (watched?.seen ?? false)
                      ? Icons.check_circle
                      : Icons.play_circle_fill,
              color: s.isLocked
                  ? AppColor.onSurfaceVariant
                  : AppColor.successDark),
          title: Text(
            s.title,
            style: const TextStyle(
                fontFamily: 'Estedad',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColor.onSurface),
          ),
          // وضعیتِ تماشا: تیکِ «دیده شد» یا نوارِ نیمه‌کاره با محلِ توقف.
          subtitle: watched == null ? null : _watchStatus(watched),
          // اگر کاور ویدیو نبود یا لود نشد، عکس پیش‌فرض
          trailing: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: (s.videoThumbnail ?? '').isEmpty
                ? _sectionFallbackThumb()
                : Image.network(
                    _abs(s.videoThumbnail!),
                    width: 56,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _sectionFallbackThumb(),
                  ),
          ),
        ),
      ),
    );
  }

  // ---------- دوره‌ی مجموعه‌ای ----------

  /// کارتِ خلاصه‌ی بالای مسیر: «این مجموعه از ۳ دوره تشکیل شده».
  Widget _bundleSummary(CourseDetailResponse data) {
    final d = data.detail;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: ShapeDecoration(
        color: AppColor.pitchGreenSoft,
        shape: AppShapes.border(AppShapes.rLg),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const ShapeDecoration(
              color: AppColor.surfaceContainer,
              shape: CircleBorder(),
            ),
            child: const Icon(Icons.layers_rounded,
                color: AppColor.pitchGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'این مجموعه از ${d.subCourses.length} دوره تشکیل شده',
                  style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColor.onSurface),
                ),
                const SizedBox(height: 3),
                Text(
                  '${d.bundleWeekCount} هفته، ${d.bundleVideoCount} ویدیو، به ترتیبِ زیر',
                  style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 11.5,
                      color: AppColor.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// مسیرِ یادگیری: دوره‌ها به ترتیب، با شماره و خطِ اتصال.
  List<Widget> _subCourseNodes(List<SubCourse> subs, {int depth = 0}) => [
        for (int i = 0; i < subs.length; i++)
          _subCourseNode(subs[i],
              index: i, isLast: i == subs.length - 1, depth: depth),
      ];

  Widget _subCourseNode(SubCourse c,
      {required int index, required bool isLast, int depth = 0}) {
    final open = _openSubCourses.contains(c.id);
    final scope = 'c${c.id}';
    const double rail = 18; // فاصله‌ی مرکزِ دایره از لبه‌ی شروع
    const double dot = 36;
    return _AnimatedSlideFade(
      delayMs: 60 * index,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
            depth == 0 ? 16 : 4, 0, depth == 0 ? 16 : 0, 0),
        child: Stack(
          children: [
            // خطِ اتصال به دوره‌ی قبلی و بعدی
            if (index > 0)
              const PositionedDirectional(
                start: rail - 1,
                top: 0,
                height: 10,
                child: _RailLine(),
              ),
            if (!isLast)
              const PositionedDirectional(
                start: rail - 1,
                top: 10 + dot,
                bottom: 0,
                child: _RailLine(),
              ),
            Padding(
              padding: EdgeInsets.only(bottom: isLast ? 4 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: dot,
                      height: dot,
                      alignment: Alignment.center,
                      decoration: ShapeDecoration(
                        gradient: open ? AppColor.greenGradient : null,
                        color: open ? null : AppColor.surfaceContainer,
                        shape: CircleBorder(
                          side: BorderSide(
                              color: AppColor.pitchGreen
                                  .withValues(alpha: open ? 0 : 0.45),
                              width: 1.5),
                        ),
                        shadows: open ? AppColor.greenShadow : null,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: open
                              ? AppColor.onPitchGreen
                              : AppColor.pitchGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _subCourseCard(c, open: open, scope: scope, depth: depth)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subCourseCard(SubCourse c,
      {required bool open, required String scope, required int depth}) {
    final locked = c.isFullyLocked;
    return Container(
      decoration: ShapeDecoration(
        color: AppColor.surfaceContainer,
        shape: AppShapes.border(AppShapes.rLg,
            side: open
                ? BorderSide(
                    color: AppColor.pitchGreen.withValues(alpha: 0.35))
                : null),
        shadows: AppColor.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppShapes.radius(AppShapes.rLg),
              onTap: () => setState(() {
                open ? _openSubCourses.remove(c.id) : _openSubCourses.add(c.id);
              }),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: AppShapes.radius(AppShapes.rMd),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: c.image.isEmpty
                            ? Container(
                                color: AppColor.pitchGreenSoft,
                                child: const Icon(Icons.school_rounded,
                                    color: AppColor.pitchGreen),
                              )
                            : Image.network(
                                _abs(c.image),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColor.pitchGreenSoft,
                                  child: const Icon(Icons.school_rounded,
                                      color: AppColor.pitchGreen),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.title.isEmpty ? 'دوره' : c.title,
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
                            children: [
                              if (c.totalWeeks > 0)
                                _miniChip(Icons.calendar_month_rounded,
                                    '${c.totalWeeks} هفته'),
                              if (c.totalVideos > 0)
                                _miniChip(Icons.play_circle_fill_rounded,
                                    '${c.totalVideos} ویدیو'),
                              if (c.difficulty.trim().isNotEmpty)
                                _miniChip(Icons.military_tech_rounded,
                                    c.difficulty.trim()),
                              if (c.subCourses.isNotEmpty)
                                _miniChip(Icons.layers_rounded,
                                    '${c.subCourses.length} دوره'),
                              if (locked) _lockedChip(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppColor.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (c.description.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                            child: Text(
                              c.description.trim(),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: 'Estedad',
                                  fontSize: 12.5,
                                  height: 1.8,
                                  color: AppColor.onSurfaceVariant),
                            ),
                          ),
                        for (int i = 0; i < c.weekGroups.length; i++)
                          _weekCard(c.weekGroups[i],
                              scope: scope, index: i, hMargin: 8),
                        if (c.subCourses.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                            child: Column(
                              children:
                                  _subCourseNodes(c.subCourses, depth: depth + 1),
                            ),
                          ),
                        if (c.weekGroups.isEmpty && c.subCourses.isEmpty)
                          const Padding(
                            padding: EdgeInsets.fromLTRB(12, 4, 12, 10),
                            child: Text(
                              'برنامه‌ی این دوره به‌زودی منتشر می‌شود.',
                              style: TextStyle(
                                  fontFamily: 'Estedad',
                                  fontSize: 12,
                                  color: AppColor.onSurfaceVariant),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: ShapeDecoration(
          color: AppColor.cardMuted,
          shape: AppShapes.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColor.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 11,
                    color: AppColor.onSurfaceVariant)),
          ],
        ),
      );

  /// آواتار کوچک پشتیبان/مربی
  Widget _coachAvatar(CourseCoach coach) {
    final url = (coach.avatar ?? '').trim();
    return Container(
      width: 22,
      height: 22,
      clipBehavior: Clip.antiAlias,
      decoration: const ShapeDecoration(
        color: AppColor.pitchGreenSoft,
        shape: CircleBorder(),
      ),
      child: url.isEmpty
          ? const Icon(Icons.person_rounded,
              size: 14, color: AppColor.pitchGreen)
          : Image.network(
              _abs(url),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded,
                  size: 14, color: AppColor.pitchGreen),
            ),
    );
  }

  /// بنر هدیه‌ی همراهِ خرید — با رنگ گرم و آیکن، تا مزیتِ خرید فوراً دیده شود.
  Widget _giftBanner(CourseGiftProduct gift) {
    final img = (gift.icon ?? gift.image ?? '').trim();
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0x33D97706), Color(0x11D97706)],
        ),
        shape: AppShapes.border(AppShapes.rMd,
            side: const BorderSide(color: Color(0x55D97706))),
      ),
      child: Row(
        children: [
          if (img.isEmpty)
            const Icon(Icons.card_giftcard_rounded,
                size: 18, color: AppColor.warning)
          else
            Container(
              width: 30,
              height: 30,
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                color: AppColor.card,
                shape: AppShapes.border(AppShapes.rSm),
              ),
              child: Image.network(
                _abs(img),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.card_giftcard_rounded,
                    size: 16,
                    color: AppColor.warning),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('هدیه‌ی همراه این خرید',
                    style: TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColor.warning)),
                Text(
                  gift.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColor.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeLocationCard(CourseDetailResponse data, int index) {
    final item = data.detail.timeAndLocation[index];
    final bool selected = item.isActive && _selectedVariant(data)?.id == item.id;
                        return _AnimatedSlideFade(
                          delayMs: 60 * index,
                          child: Opacity(
                            // واریانتِ غیرفعال قابل خرید نیست؛ باید هم دیده
                            // شود و هم آشکارا غیرقابل انتخاب به نظر برسد.
                            opacity: item.isActive ? 1 : 0.55,
                            child: _VariantTapTarget(
                            enabled: item.isActive,
                            onTap: () => _selectVariant(item),
                            child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            decoration: ShapeDecoration(
            color: AppColor.surfaceContainer,
            shape: AppShapes.border(AppShapes.rLg,
                side: selected
                    ? const BorderSide(color: AppColor.goldEnd, width: 2)
                    : null),
            shadows: AppColor.cardShadow,
          ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  item.image == null || item.image!.isEmpty
                                      ? Container(width: 80, height: 80, color: AppColor.obsidianBg)
                                      : Image.network(_abs(item.image!), width: 80, height: 80, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Image.asset('assets/images/placeholder.jpg',width: 80, height: 80, fit: BoxFit.cover)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // مکان یک خطِ کامل برای خودش دارد؛ پیش‌تر با چیپِ ظرفیت و
                                        // وضعیت در یک ردیف بود و وقتی وضعیت «ثبت‌نام بسته» (پهن‌تر
                                        // از «فعال») بود، نامِ مکان به «دور… ه…» له می‌شد.
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(top: 2),
                                              child: Icon(
                                                  Icons.location_on_outlined,
                                                  size: 16,
                                                  color: AppColor.pitchGreen),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                item.location == null
                                                    ? 'دوره‌ی آنلاین'
                                                    : 'مکان: ${item.location}',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontFamily: 'Estedad',
                                                    height: 1.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColor.onSurface),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _variantChip(
                                              item.isActive ? 'فعال' : 'ثبت‌نام بسته',
                                              color: item.isActive
                                                  ? AppColor.successDark
                                                  : AppColor.onSurfaceVariant,
                                            ),
                                            _variantChip('ظرفیت: ${item.capacity}',
                                                color: AppColor.onSurfaceVariant),
                                          ],
                                        ),
                                        if (item.time != null) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Padding(
                                                padding:
                                                    EdgeInsets.only(top: 2),
                                                child: Icon(
                                                    Icons.schedule_rounded,
                                                    size: 15,
                                                    color:
                                                        AppColor.pitchGreen),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'زمان برگزاری: ${item.time}',
                                                  style: const TextStyle(
                                                      fontFamily: 'Estedad',
                                                      height: 1.6,
                                                      color: AppColor
                                                          .onSurfaceVariant),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (item.coach != null) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              _coachAvatar(item.coach!),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'پشتیبان: ${item.coach!.fullName}',
                                                  style: const TextStyle(
                                                      fontFamily: 'Estedad',
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColor
                                                          .onSurfaceVariant),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (item.giftProduct != null) ...[
                                          const SizedBox(height: 8),
                                          _giftBanner(item.giftProduct!),
                                        ],
                                        const SizedBox(height: 6),
                                        _timeLocationPrice(item),
                                        const SizedBox(height: 12),
                                        // خودِ کارت انتخاب می‌شود و دکمه‌ی
                                        // خرید پایین صفحه همان را به سبد
                                        // می‌افزاید؛ پس اینجا فقط وضعیت
                                        // انتخاب نشان داده می‌شود.
                                        if (item.isActive)
                                          _VariantSelectionMark(selected: selected),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ),
                          ),
                        );
  }

  /// عنوان دوره (در دسکتاپ کمی درشت‌تر)
  Widget _courseTitle(CourseDetailResponse data, {double fontSize = 20}) {
    return Text(
      data.courseTitle,
      style: TextStyle(
        fontFamily: 'Estedad',
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: AppColor.onSurface,
      ),
    );
  }

  /// ردیف بج‌های رنگی دوره (در هر دو چیدمان یکسان)
  Widget _badgesRow(CourseDetailResponse data) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (data.detail.isBundle)
          _infoChip('شامل ${data.detail.subCourses.length} دوره',
              icon: Icons.layers_rounded, color: AppColor.pitchGreen),
        _infoChip('سطح: ${data.courseDifficulty}',
            icon: Icons.military_tech_rounded, color: AppColor.levelExpert),
        _infoChip(
            'تعداد هفته: ${data.weekCount > 0 || !data.detail.isBundle ? data.weekCount : data.detail.bundleWeekCount}',
            icon: Icons.calendar_month_rounded, color: AppColor.categoryBadge),
        _infoChip('تعداد سکشن: ${data.sectionCount}',
            icon: Icons.view_list_rounded, color: AppColor.pitchGreen),
        _infoChip('مدت دوره: ${_formatDuration(data.courseDuration)}',
            icon: Icons.schedule_rounded, color: AppColor.warning),
        _infoChip(
            'تعداد ویدیو: ${data.detail.videoCount > 0 || !data.detail.isBundle ? data.detail.videoCount : data.detail.bundleVideoCount}',
            icon: Icons.play_circle_fill_rounded, color: AppColor.danger),
      ],
    );
  }

  /// توضیحات دوره و پیش‌نیاز
  Widget _descriptionBlock(CourseDetailResponse data) {
    // این بلوک قبلاً بدون پس‌زمینه روی milk رها بود و کنار بقیه‌ی کارت‌ها
    // یتیم دیده می‌شد؛ حالا مثل بقیه‌ی بخش‌ها داخل کارت برجسته می‌نشیند.
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: ShapeDecoration(
        color: AppColor.surfaceContainer,
        shape: AppShapes.border(AppShapes.rLg),
        shadows: AppColor.cardShadow,
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('درباره‌ی دوره',
            style: TextStyle(
                fontFamily: 'Estedad',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColor.onSurface)),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            data.courseDescription,
            key: ValueKey(data.id),
            textAlign: TextAlign.justify,
            style: const TextStyle(
                fontFamily: 'Estedad', color: AppColor.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 16),
        const Text('پیش‌نیاز',
            style: TextStyle(
                fontFamily: 'Estedad',
                fontWeight: FontWeight.w700,
                color: AppColor.onSurface)),
        const SizedBox(height: 6),
        Text(data.detail.preRequirement,
            style: const TextStyle(
                fontFamily: 'Estedad', color: AppColor.onSurfaceVariant)),
      ],
      ),
    );
  }

  /// تب‌های برنامه‌ی هفتگی و زمان و مکان برگزاری
  Widget _detailTabs(CourseDetailResponse data) {
    return DetailTabs(
      tabs: [
        // دوره‌ی مجموعه‌ای: مسیرِ دوره‌های تشکیل‌دهنده، هرکدام با برنامه‌ی
        // هفتگیِ خودش.
        if (data.detail.isBundle)
          DetailTab(
            title: 'دوره‌های این مجموعه',
            icon: Icons.layers_rounded,
            builder: (context) {
              final resume = _resumeCard(data);
              return Column(
                children: [
                  if (resume != null) resume,
                  _bundleSummary(data),
                  ..._subCourseNodes(data.detail.subCourses),
                ],
              );
            },
          ),
        // برنامه‌ی هفتگیِ خودِ دوره (در مجموعه‌ها فقط اگر جلسه‌ی مشترک دارد)
        if (!data.detail.isBundle || data.detail.weekGroups.isNotEmpty)
          DetailTab(
            title: 'برنامه هفتگی',
            icon: Icons.calendar_month_rounded,
            builder: (context) {
              final resume = data.detail.isBundle ? null : _resumeCard(data);
              return Column(
                children: [
                  if (resume != null) resume,
                  for (int i = 0; i < data.detail.weekGroups.length; i++)
                    _weekCard(data.detail.weekGroups[i], index: i),
                ],
              );
            },
          ),
        DetailTab(
          title: 'زمان و مکان برگزاری',
          icon: Icons.place_rounded,
          builder: (context) => Column(
            children: List.generate(
              data.detail.timeAndLocation.length,
              (index) => _timeLocationCard(data, index),
            ),
          ),
        ),
      ],
    );
  }

  /// نوار خرید: اگر دوره چند زمان/مکان دارد، اول نشان می‌دهد کدام یک
  /// انتخاب شده تا کاربر کورکورانه دکمه را نزند.
  Widget _actionSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FutureBuilder<CourseDetailResponse>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final active = _activeVariants(snapshot.data!);
            if (active.length < 2) return const SizedBox.shrink();
            final selected = _selectedVariant(snapshot.data!);
            if (selected == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 16, color: AppColor.goldEnd),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'انتخاب شما: ${_variantLabel(selected)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColor.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        _actionRow(),
      ],
    );
  }

  /// برچسب کوتاه یک واریانت برای نمایش در نوار خرید
  String _variantLabel(CourseTimeAndLocationItem item) {
    final place = (item.location == null || item.location!.isEmpty)
        ? 'دوره‌ی آنلاین'
        : item.location!;
    final time = item.time;
    return (time == null || time.isEmpty) ? place : '$place — $time';
  }

  /// ردیف دکمه‌های اقدام: میان‌بر سبد + افزودن به سبد
  /// (منطق شیت افزودن به سبد دست‌نخورده است؛ فقط جای رندر عوض می‌شود)
  Widget _actionRow() {
    return Row(
      children: [
        // Cart Button
        Container(
          width: 54,
          height: 54,
          margin: const EdgeInsets.only(right: 12),
          decoration: ShapeDecoration(
            color: AppColor.cardMuted,
            shape: AppShapes.pill,
          ),
          child: Material(
            color: Colors.transparent,
            shape: AppShapes.pill,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).pushNamed('/cart'),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: SvgPicture.asset(
                  'assets/icons/Bag.svg',
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                      AppColor.pitchGreen, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ),
        // Add to Cart Button
        Expanded(
          child: FutureBuilder<CourseDetailResponse>(
            future: _future,
            builder: (context, snapshot) {
              // واریانتِ انتخاب‌شده‌ی کاربر (نه صرفاً اولی): دوره می‌تواند
              // چند زمان/مکان داشته باشد و همه باید قابل خرید باشند.
              final selected = snapshot.hasData
                  ? _selectedVariant(snapshot.data!)
                  : null;
              if (selected != null) {
                return ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) =>
                          AddCourseToCartModal(courseItem: selected),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.goldEnd,
                    shape: AppShapes.pill,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: Text(
                    'افزودن به سبد',
                    style: TextStyle(
                      fontFamily: 'Estedad',
                      fontWeight: FontWeight.w600,
                      color: AppColor.onGold,
                      fontSize: 16,
                    ),
                  ),
                );
              }
              return ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.outlineVariantDark,
                  shape: AppShapes.pill,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: Text(
                  'دوره در دسترس نیست',
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    fontWeight: FontWeight.w600,
                    color: AppColor.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------- چیدمان دسکتاپ ----------

  /// سربرگ دسکتاپ: دکمه‌ی بازگشت + عنوان صفحه
  Widget _desktopHeader() {
    return Row(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Material(
            color: AppColor.surfaceContainer,
            shape: AppShapes.pill,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_rounded,
                    size: 20, color: AppColor.onSurface),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text('جزییات دوره',
            style: TextStyle(
                fontFamily: 'Estedad',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColor.onSurface)),
      ],
    );
  }

  /// تصویر بزرگ دوره در ستون راست دسکتاپ
  Widget _desktopHero(CourseDetailResponse data) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppShapes.rLg),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: data.image.isEmpty
            ? _heroPlaceholder()
            : Image.network(
                _abs(data.image),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _heroPlaceholder(),
              ),
      ),
    );
  }

  /// جای‌گزین تصویر برای دوره‌هایی که بک‌اند تصویری برایشان ندارد.
  /// یک مستطیل خالی هم‌رنگ پس‌زمینه، ستون راست را تهی نشان می‌داد؛ این
  /// نسخه با گرادیان سبز و آیکن، قاب را پر و برند را حفظ می‌کند.
  Widget _heroPlaceholder() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColor.greenGradient),
      child: Center(
        child: Icon(
          Icons.school_rounded,
          size: 72,
          color: AppColor.onPitchGreen.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  /// پنل اطلاعات کلیدی دسکتاپ: عنوان، بج‌ها، قیمت و دکمه‌ی افزودن به سبد
  Widget _desktopInfo(CourseDetailResponse data) {
    final items = data.detail.timeAndLocation;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: AppColor.surfaceContainer,
        shape: AppShapes.border(AppShapes.rLg),
        shadows: AppColor.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _courseTitle(data, fontSize: 24),
          const SizedBox(height: 14),
          _badgesRow(data),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 18),
            // قیمتِ همان واریانتی که خریداری می‌شود، نه همیشه اولی
            _timeLocationPrice(_selectedVariant(data) ?? items.first),
          ],
          const SizedBox(height: 20),
          _actionSection(),
        ],
      ),
    );
  }

  /// بدنه‌ی دسکتاپ: تصویر و اطلاعات کنار هم، سپس توضیحات و تب‌ها تمام‌عرض
  Widget _desktopBody(CourseDetailResponse data) {
    const double maxWidth = 1000;
    return ListView(
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 20),
        CenteredContent(maxWidth: maxWidth, child: _desktopHeader()),
        const SizedBox(height: 20),
        CenteredContent(
          maxWidth: maxWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // در RTL فرزند اول سمت راست می‌نشیند: تصویر راست، اطلاعات چپ
              Expanded(flex: 11, child: _desktopHero(data)), // ~۵۵٪ عرض
              const SizedBox(width: 24),
              Expanded(flex: 9, child: _desktopInfo(data)), // ~۴۵٪ عرض
            ],
          ),
        ),
        const SizedBox(height: 28),
        CenteredContent(maxWidth: maxWidth, child: _descriptionBlock(data)),
        const SizedBox(height: 20),
        CenteredContent(maxWidth: maxWidth, child: _detailTabs(data)),
        const SizedBox(height: 40),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColor.obsidianBg,
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: RefreshIndicator(
            color: AppColor.goldEnd,
            backgroundColor: AppColor.surfaceContainer,
            onRefresh: _refresh,
            child: FutureBuilder<CourseDetailResponse>(
            future: _future,
            builder: (context, snapshot) {
              // در حال تازه‌سازی، داده‌ی قبلی روی صفحه می‌ماند
              final cached = snapshot.data ?? _lastData;
              if (snapshot.connectionState != ConnectionState.done) {
                if (cached != null) return _body(cached);
                return _CourseDetailSkeleton(
                    desktop: AppBreakpoints.isDesktop(context));
              }
              if (snapshot.hasError || !snapshot.hasData) {
                if (cached != null) return _body(cached);
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent),
                        const SizedBox(height: 8),
                        Text('خطا در بارگذاری جزییات دوره',
                            style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface)),
                        const SizedBox(height: 8),
                        Text('${snapshot.error}',
                            style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurfaceVariant)),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => setState(() => _future = CourseService.fetchCourseDetail(id: widget.id)),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppColor.goldEnd,
                              side: const BorderSide(color: AppColor.goldEnd),
                              shape: AppShapes.pill),
                          child: const Text('تلاش مجدد', style: TextStyle(fontFamily: 'Estedad')),
                        ),
                      ],
                    ),
                  ),
                );
              }
      
              return _body(snapshot.data!);
            },
          ),
          ),
        ),
        // این صفحه هیچ شنونده‌ای برای CartBloc نداشت: بعد از «افزودن به سبد»
        // نه پیام موفقیت می‌آمد و نه خطا، و کاربر فکر می‌کرد دکمه کار نمی‌کند.
        bottomNavigationBar: BlocListener<CartBloc, CartState>(
          listener: _onCartState,
          child: BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            // دسکتاپ: نوار پایین حذف می‌شود و همین دکمه‌ها داخل پنل اطلاعات
            // رندر می‌شوند؛ منطق شیت افزودن به سبد دست‌نخورده باقی می‌ماند.
            if (AppBreakpoints.isDesktop(context)) {
              return const SizedBox.shrink();
            }
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: ShapeDecoration(
                color: AppColor.card,
                shape: AppShapes.borderTop(AppShapes.rXl),
                shadows: AppColor.floatingShadow,
              ),
              child: _actionSection(),
            );
          },
          ),
        ),
      ),
    );
  }

  /// بدنه‌ی صفحه با داده‌ی آماده (دسکتاپ/موبایل)
  Widget _body(CourseDetailResponse data) {
    // دسکتاپ: تصویر و اطلاعات کلیدی کنار هم، بقیه‌ی بخش‌ها زیرشان
    if (AppBreakpoints.isDesktop(context)) {
      return _desktopBody(data);
    }
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    stretch: true,
                    expandedHeight: 240,
                    backgroundColor: AppColor.obsidianBg,
                    foregroundColor: AppColor.onSurface,
                    automaticallyImplyLeading: false,
                    // در RTL دکمه‌ی بازگشت باید سمت راست و با فلشِ راست باشد.
                    // arrow_back در RTL خودش آینه می‌شود و به راست اشاره می‌کند؛
                    // arrow_forward برعکس، آینه شده و به چپ می‌رفت.
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    title: const Text('جزییات دوره',
                        style: TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface)),
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          data.image.isEmpty
                              ? Container(color: AppColor.surfaceContainer)
                              : Image.network(
                              _abs(data.image),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset('assets/images/placeholder.jpg',
                                  width: 80, height: 80, fit: BoxFit.cover)
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black54, Colors.transparent],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _courseTitle(data),
                          const SizedBox(height: 8),
                          _badgesRow(data),
                          const SizedBox(height: 12),
                          _descriptionBlock(data),
                        ],
                      ),
                    ),
                  ),

                  // تب‌های جزئیات دوره با ترنزیشن نرم
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _detailTabs(data),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
  }

  /// بازخوردِ افزودن دوره به سبد — همان الگوی صفحه‌ی محصول
  void _onCartState(BuildContext context, CartState cartState) {
    if (cartState is CartItemAdded) {
      showDialog(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppColor.card,
            shape: AppShapes.border(AppShapes.rLg),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColor.success, size: 60),
                const SizedBox(height: 16),
                Text(
                  cartState.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColor.ink,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SoftButton(
                        label: 'ادامه',
                        height: 44,
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GradientButton(
                        label: 'رفتن به سبد',
                        height: 44,
                        fontSize: 13,
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pushNamed('/cart');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    // بارگذاریِ پس‌زمینه‌ی سبد برای کاربر مهمان خطا نیست؛ پیش‌تر همین
    // حالت روی هر صفحه‌ی محصول/دوره یک اسنک‌بار قرمز «نیاز به ورود دارید»
    // می‌انداخت، بی‌آنکه کاربر کاری کرده باشد.
    if (cartState is CartError && cartState is! CartRequiresLogin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cartState.message,
              style: const TextStyle(fontFamily: 'Estedad')),
          backgroundColor: AppColor.danger,
        ),
      );
    }
  }
}

class _AnimatedSlideFade extends StatelessWidget {
  final Widget child;
  final int delayMs;
  const _AnimatedSlideFade({required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 350),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
/// ناحیه‌ی قابل‌ضربه‌ی کارت واریانت. برای واریانت غیرفعال هیچ ضربه‌ای
/// نمی‌گیرد و نشانگر ماوس هم عوض نمی‌شود، تا آشکار باشد که قابل انتخاب نیست.
class _VariantTapTarget extends StatelessWidget {
  const _VariantTapTarget({
    required this.child,
    required this.enabled,
    required this.onTap,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

/// نشانگر انتخاب زیر هر کارت واریانت: «انتخاب شد» یا دعوت به انتخاب.
class _VariantSelectionMark extends StatelessWidget {
  const _VariantSelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
      decoration: ShapeDecoration(
        color: selected
            ? AppColor.goldEnd.withOpacity(0.16)
            : Colors.transparent,
        shape: AppShapes.border(
          AppShapes.rLg,
          side: BorderSide(
            color: selected ? AppColor.goldEnd : AppColor.outlineVariantDark,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: selected ? AppColor.goldEnd : AppColor.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            selected ? 'انتخاب شد' : 'انتخاب این زمان',
            style: TextStyle(
              fontFamily: 'Estedad',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? AppColor.goldEnd : AppColor.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}


/// اسکلتونِ صفحه‌ی جزئیات دوره: همان چیدمانِ صفحه‌ی بارگذاری‌شده — کاورِ
/// بالا، عنوان، ردیفِ بج‌ها، بلوکِ «درباره‌ی دوره» و تب‌ها — با شیمر.
///
/// نکته: ShaderMaskِ [Shimmer] روی هر پیکسلِ مات کشیده می‌شود، پس کارت‌ها
/// پس‌زمینه نمی‌گیرند؛ وگرنه با استخوان‌ها یکی می‌شدند و ساختار گم می‌شد.
class _CourseDetailSkeleton extends StatelessWidget {
  const _CourseDetailSkeleton({required this.desktop});

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: desktop ? _desktop() : _mobile(),
      ),
    );
  }

  // ---- موبایل: کاورِ ۲۴۰ پیکسلی، عنوان و بج‌ها، توضیحات، تب‌ها ----
  Widget _mobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        // جای SliverAppBarِ کشیده: تصویر پشتِ نوارِ بالا هم ادامه دارد، پس
        // یک بلوکِ یک‌دستِ ۲۴۰ پیکسلی همان قاب را نشان می‌دهد
        Bone(height: 240, radius: 0),
        Padding(
          padding: EdgeInsets.all(16),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone(width: 220, height: 20, radius: 6),
                SizedBox(height: 14),
                _BadgeBones(),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: _AboutBones(),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 26, 16, 0),
          child: _TabBones(),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  // ---- دسکتاپ: سرصفحه، کاورِ راست و پنلِ اطلاعاتِ چپ، توضیحات، تب‌ها ----
  Widget _desktop() {
    const double maxWidth = 1000;
    return const Column(
      children: [
        SizedBox(height: 20),
        CenteredContent(
          maxWidth: maxWidth,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                Bone.circle(size: 40),
                SizedBox(width: 12),
                Bone(width: 90, height: 16, radius: 6),
              ],
            ),
          ),
        ),
        SizedBox(height: 20),
        CenteredContent(
          maxWidth: maxWidth,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ~۵۵٪ عرض: کاورِ ۱۶:۱۰
                Expanded(
                  flex: 11,
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Bone(radius: AppShapes.rLg),
                  ),
                ),
                SizedBox(width: 24),
                Expanded(flex: 9, child: _DesktopInfoBones()), // ~۴۵٪ عرض
              ],
            ),
          ),
        ),
        SizedBox(height: 28),
        CenteredContent(
          maxWidth: maxWidth,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _AboutBones(),
          ),
        ),
        SizedBox(height: 28),
        CenteredContent(maxWidth: maxWidth, child: _TabBones()),
        SizedBox(height: 40),
      ],
    );
  }
}

/// ردیفِ بج‌های دوره (سطح، هفته، سکشن، مدت، ویدیو)
class _BadgeBones extends StatelessWidget {
  const _BadgeBones();

  @override
  Widget build(BuildContext context) => const Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Bone(width: 96, height: 30, radius: 15),
          Bone(width: 110, height: 30, radius: 15),
          Bone(width: 104, height: 30, radius: 15),
          Bone(width: 128, height: 30, radius: 15),
          Bone(width: 112, height: 30, radius: 15),
        ],
      );
}

/// بلوکِ «درباره‌ی دوره» و «پیش‌نیاز»
class _AboutBones extends StatelessWidget {
  const _AboutBones();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Bone(width: 110, height: 15, radius: 6),
          SizedBox(height: 14),
          Bone(height: 13, radius: 6),
          SizedBox(height: 9),
          Bone(height: 13, radius: 6),
          SizedBox(height: 9),
          Bone(width: 200, height: 13, radius: 6),
          SizedBox(height: 20),
          Bone(width: 70, height: 14, radius: 6),
          SizedBox(height: 12),
          Bone(width: 240, height: 13, radius: 6),
        ],
      ),
    );
  }
}

/// نوارِ تب‌ها (ارتفاع ۴۲) به‌همراه دو کارتِ محتوای زیرش
class _TabBones extends StatelessWidget {
  const _TabBones();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Bone(width: 128, height: 42, radius: 21),
              SizedBox(width: 8),
              Bone(width: 156, height: 42, radius: 21),
            ],
          ),
          SizedBox(height: 12),
          Bone(height: 84, radius: AppShapes.rLg),
          SizedBox(height: 12),
          Bone(height: 84, radius: AppShapes.rLg),
        ],
      ),
    );
  }
}

/// پنلِ اطلاعات کلیدی دسکتاپ: عنوان، بج‌ها، قیمت و دکمه‌ی خرید
class _DesktopInfoBones extends StatelessWidget {
  const _DesktopInfoBones();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Bone(width: 240, height: 20, radius: 6),
        SizedBox(height: 16),
        _BadgeBones(),
        SizedBox(height: 24),
        Bone(width: 160, height: 22, radius: 6),
        SizedBox(height: 24),
        Bone(height: 48, radius: 24),
      ],
    );
  }
}

/// جای یک ویدیو در درختِ دوره: محدوده (خودِ دوره یا c<id>)، هفته، و مسیرِ
/// زیرمجموعه‌هایی که باید باز شوند تا دیده شود.
class _Located {
  const _Located(this.section, this.weekNumber, this.scope, this.path,
      {this.courseTitle});

  final CourseWeekSectionItem section;
  final String weekNumber;
  final String scope;
  final List<int> path;

  /// عنوانِ زیرمجموعه، برای «ادامه‌ی تماشا»
  final String? courseTitle;
}

/// خطِ عمودیِ مسیرِ یادگیری بینِ دوره‌ها
class _RailLine extends StatelessWidget {
  const _RailLine();

  @override
  Widget build(BuildContext context) => Container(
        width: 2,
        decoration: BoxDecoration(
          color: AppColor.pitchGreen.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(1),
        ),
      );
}
