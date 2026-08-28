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
import 'package:marketky/services/course_service.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/views/widgets/modals/add_course_to_cart_modal.dart';
import 'package:marketky/bloc/cart/cart_bloc.dart';
import 'package:marketky/views/widgets/detail_tabs.dart';
import 'package:marketky/views/widgets/modals/video_player_dialog.dart';

class CourseDetailPage extends StatefulWidget {
  final int id;
  const CourseDetailPage({super.key, required this.id});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage>
    with SingleTickerProviderStateMixin {
  late Future<CourseDetailResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = CourseService.fetchCourseDetail(id: widget.id);
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

  void _onSectionTap(CourseWeekSectionItem section) {
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
    showVideoPlayerDialog(context, videoUrl: _abs(url!), title: section.title);
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

  Widget _weekCard(CourseDetailResponse data, int index) {
                        final week = data.detail.weeks[index];
                        return _AnimatedSlideFade(
                          delayMs: 50 * index,
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                              iconColor: AppColor.goldEnd,
                              collapsedIconColor: AppColor.onSurfaceVariant,
                              title: Text('هفته ${week.weekNumber}${week.weekName == null || week.weekName!.isEmpty ? '' : ' - ${week.weekName}'}',
                                  style: const TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface)),
                              // ویدیوهای هر هفته داخل یک کانتینر مجزا
                              children: [
                                Container(
                                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: ShapeDecoration(
            color: AppColor.obsidianBg,
            shape: AppShapes.border(AppShapes.rLg),
            shadows: AppColor.cardShadow,
          ),
                                  child: Column(
                                    children: week.sections
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final i = entry.key;
                                      final s = entry.value;
                                      return _AnimatedSlideFade(
                                        delayMs: 40 * i,
                                        child: Container(
                                          margin: EdgeInsets.only(
                                              bottom: i ==
                                                      week.sections.length - 1
                                                  ? 0
                                                  : 8),
                                          decoration: BoxDecoration(
                                            color: AppColor.surfaceContainer,
                                            border: Border.all(
                                                color: AppColor.outlineVariantDark),
                                          ),
                                          child: ListTile(
                                            dense: true,
                                            // ویدیوهای باز با انیمیشن در دیالوگ پخش می‌شوند
                                            onTap: () => _onSectionTap(s),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4),
                                            leading: Icon(
                                                s.isLocked
                                                    ? Icons.lock
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
                                            // اگر کاور ویدیو نبود یا لود نشد، عکس پیش‌فرض
                                            trailing: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: (s.videoThumbnail ?? '')
                                                      .isEmpty
                                                  ? _sectionFallbackThumb()
                                                  : Image.network(
                                                      _abs(s.videoThumbnail!),
                                                      width: 56,
                                                      height: 36,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (_, __, ___) =>
                                                              _sectionFallbackThumb(),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                            ),
                          ),
                        );
  }

  Widget _timeLocationCard(CourseDetailResponse data, int index) {
                        final item = data.detail.timeAndLocation[index];
                        return _AnimatedSlideFade(
                          delayMs: 60 * index,
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            decoration: ShapeDecoration(
            color: AppColor.surfaceContainer,
            shape: AppShapes.border(AppShapes.rLg),
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
                                        // ظرفیت بالا سمت راست، کنار عنوان مکان
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3),
                                              decoration: ShapeDecoration(
            color: AppColor.obsidianBg,
            shape: AppShapes.border(AppShapes.rLg),
            shadows: AppColor.cardShadow,
          ),
                                              child: Text(
                                                'ظرفیت: ${item.capacity}',
                                                style: const TextStyle(
                                                  fontFamily: 'Estedad',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColor.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                item.location,
                                                style: const TextStyle(
                                                    fontFamily: 'Estedad',
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColor.onSurface),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (item.isActive)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                color: AppColor.successDark.withOpacity(0.12),
                                                child: const Text('فعال',
                                                    style: TextStyle(
                                                        fontFamily: 'Estedad',
                                                        fontSize: 11,
                                                        color: AppColor.successDark)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(item.time,
                                            style: const TextStyle(
                                                fontFamily: 'Estedad', color: AppColor.onSurfaceVariant)),
                                        const SizedBox(height: 6),
                                        _timeLocationPrice(item),
                                        const SizedBox(height: 12),
                                        if (item.isActive)
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  backgroundColor: Colors.transparent,
                                                  // بدون این، شیت حداکثر نصف
                                                  // صفحه است و دکمه‌ی پایین
                                                  // بریده می‌شود.
                                                  isScrollControlled: true,
                                                  builder: (context) => AddCourseToCartModal(courseItem: item),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColor.goldEnd,
                                                shape: AppShapes.pill,
                                                padding: EdgeInsets.symmetric(vertical: 12),
                                                elevation: 0,
                                              ),
                                              child: Text(
                                                'افزودن به سبد',
                                                style: TextStyle(
                                                  fontFamily: 'Estedad',
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColor.onGold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
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
        _infoChip('سطح: ${data.courseDifficulty}',
            icon: Icons.military_tech_rounded, color: AppColor.levelExpert),
        _infoChip('تعداد هفته: ${data.weekCount}',
            icon: Icons.calendar_month_rounded, color: AppColor.categoryBadge),
        _infoChip('تعداد سکشن: ${data.sectionCount}',
            icon: Icons.view_list_rounded, color: AppColor.pitchGreen),
        _infoChip('مدت دوره: ${_formatDuration(data.courseDuration)}',
            icon: Icons.schedule_rounded, color: AppColor.warning),
        _infoChip('تعداد ویدیو: ${data.detail.videoCount}',
            icon: Icons.play_circle_fill_rounded, color: AppColor.danger),
      ],
    );
  }

  /// توضیحات دوره و پیش‌نیاز
  Widget _descriptionBlock(CourseDetailResponse data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }

  /// تب‌های برنامه‌ی هفتگی و زمان و مکان برگزاری
  Widget _detailTabs(CourseDetailResponse data) {
    return DetailTabs(
      tabs: [
        DetailTab(
          title: 'برنامه هفتگی',
          icon: Icons.calendar_month_rounded,
          builder: (context) => Column(
            children: List.generate(
              data.detail.weeks.length,
              (index) => _weekCard(data, index),
            ),
          ),
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
              if (snapshot.hasData &&
                  snapshot.data!.detail.timeAndLocation.isNotEmpty) {
                final firstCourse =
                    snapshot.data!.detail.timeAndLocation.first;
                return ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) =>
                          AddCourseToCartModal(courseItem: firstCourse),
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
                child: Icon(Icons.arrow_forward_rounded,
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
            _timeLocationPrice(items.first),
          ],
          const SizedBox(height: 20),
          _actionRow(),
        ],
      ),
    );
  }

  /// بدنه‌ی دسکتاپ: تصویر و اطلاعات کنار هم، سپس توضیحات و تب‌ها تمام‌عرض
  Widget _desktopBody(CourseDetailResponse data) {
    const double maxWidth = 1000;
    return ListView(
      physics: const BouncingScrollPhysics(),
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
          child: FutureBuilder<CourseDetailResponse>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator(color: AppColor.goldEnd));
              }
              if (snapshot.hasError || !snapshot.hasData) {
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
      
              final data = snapshot.data!;
              // دسکتاپ: تصویر و اطلاعات کلیدی کنار هم، بقیه‌ی بخش‌ها زیرشان
              if (AppBreakpoints.isDesktop(context)) {
                return _desktopBody(data);
              }
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    stretch: true,
                    expandedHeight: 240,
                    backgroundColor: AppColor.obsidianBg,
                    foregroundColor: AppColor.onSurface,
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
            },
          ),
        ),
        bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
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
              child: _actionRow(),
            );
          },
        ),
      ),
    );
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