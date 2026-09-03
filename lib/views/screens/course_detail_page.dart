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

  /// آخرین داده‌ی موفق؛ هنگام «کشیدن برای تازه‌سازی» نگه داشته می‌شود تا
  /// محتوای صفحه با یک اسپینر تمام‌صفحه جایگزین نشود.
  CourseDetailResponse? _lastData;

  /// واریانتِ انتخاب‌شده (زمان/مکان برگزاری). پیش‌تر دکمه‌ی خرید همیشه
  /// اولین واریانتِ فعال را می‌فرستاد، پس دوره‌های چندزمانه عملاً فقط یک
  /// گزینه‌ی قابل‌خرید داشتند.
  int? _selectedVariantId;

  @override
  void initState() {
    super.initState();
    _future = CourseService.fetchCourseDetail(id: widget.id);
    // اولین واریانتِ فعال از ابتدا انتخاب می‌شود تا دکمه‌ی خرید هیچ‌وقت
    // بدون گزینه نماند.
    _future.then((data) {
      if (!mounted) return;
      _lastData = data;
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
                        final week = data.detail.weekGroups[index];
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
                              title: Text('هفته ${week.weekNumber}',
                                  style: const TextStyle(
                                      fontFamily: 'Estedad',
                                      fontWeight: FontWeight.w700,
                                      color: AppColor.onSurface)),
                              subtitle: Text(
                                  '${week.allSections.length} ویدیو',
                                  style: const TextStyle(
                                      fontFamily: 'Estedad',
                                      fontSize: 11,
                                      color: AppColor.onSurfaceVariant)),
                              // هر هفته یک یا چند «گروه» دارد و ویدیوها زیر
                              // هر گروه می‌نشینند.
                              children: [
                                for (final group in week.groups)
                                Container(
                                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: ShapeDecoration(
            color: AppColor.obsidianBg,
            shape: AppShapes.border(AppShapes.rLg),
            shadows: AppColor.cardShadow,
          ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                    if ((group.weekName ?? '').trim().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            4, 2, 4, 10),
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons.folder_open_rounded,
                                                size: 15,
                                                color: AppColor.pitchGreen),
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
                                                color:
                                                    AppColor.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ...group.sections
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
                                                      group.sections.length - 1
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
                                    }),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            ),
                          ),
                        );
  }

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
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                      Icons
                                                          .location_on_outlined,
                                                      size: 15,
                                                      color: AppColor
                                                          .pitchGreen),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      item.location == null
                                                          ? 'دوره‌ی آنلاین'
                                                          : 'مکان: ${item.location}',
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          fontFamily: 'Estedad',
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColor
                                                              .onSurface),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              color: item.isActive
                                                  ? AppColor.successDark.withOpacity(0.12)
                                                  : AppColor.outlineVariantDark.withOpacity(0.35),
                                              child: Text(
                                                  item.isActive ? 'فعال' : 'ثبت‌نام بسته',
                                                  style: TextStyle(
                                                      fontFamily: 'Estedad',
                                                      fontSize: 11,
                                                      color: item.isActive
                                                          ? AppColor.successDark
                                                          : AppColor.onSurfaceVariant)),
                                            ),
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
        DetailTab(
          title: 'برنامه هفتگی',
          icon: Icons.calendar_month_rounded,
          builder: (context) => Column(
            children: List.generate(
              data.detail.weekGroups.length,
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
                return const Center(child: CircularProgressIndicator(color: AppColor.goldEnd));
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
    if (cartState is CartError) {
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
