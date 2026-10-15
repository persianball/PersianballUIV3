// lib/models/course_detail_model.dart

class CourseWeekSectionItem {
  final String title;
  final bool isLocked;
  final String? videoUrl;
  final String? videoThumbnail;

  CourseWeekSectionItem({
    required this.title,
    required this.isLocked,
    this.videoUrl,
    this.videoThumbnail,
  });

  factory CourseWeekSectionItem.fromJson(Map<String, dynamic> json) {
    return CourseWeekSectionItem(
      title: (json['title'] ?? '').toString(),
      isLocked: json['is_locked'] == true,
      videoUrl: json['video_url'] as String?,
      videoThumbnail: json['video_thumbnail'] as String?,
    );
  }
}

class CourseWeek {
  final String weekNumber;
  final String? weekName;
  final List<CourseWeekSectionItem> sections;

  /// عنوانِ نمایشیِ هفته وقتی «هفته‌ی N» کافی نیست (مثلاً «Upper» در
  /// زیرمجموعه‌ای که از نامِ هفته‌ها ساخته شده). کلیدِ پیشرفت همچنان
  /// [weekNumber] است.
  final String? title;

  CourseWeek({
    required this.weekNumber,
    required this.weekName,
    required this.sections,
    this.title,
  });

  factory CourseWeek.fromJson(Map<String, dynamic> json) {
    final list = (json['sections'] as List<dynamic>? ?? [])
        .map((e) => CourseWeekSectionItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return CourseWeek(
      weekNumber: (json['week_number'] ?? '').toString(),
      weekName: json['week_name'] as String?,
      sections: list,
    );
  }
}

/// یک هفته‌ی دوره: چند «گروه» دارد و ویدیوها زیر هر گروه می‌نشینند.
///
/// بک‌اند لیستِ تختی از ورودی‌ها می‌دهد که هرکدام `week_number` دارند؛ چند
/// ورودی می‌توانند یک `week_number` مشترک داشته باشند و هر ورودی یک گروهِ
/// جدا داخل همان هفته است (نامش `week_name`). این کلاس آن‌ها را جمع می‌کند.
class CourseWeekGroup {
  final String weekNumber;
  final List<CourseWeek> groups;

  const CourseWeekGroup({required this.weekNumber, required this.groups});

  /// «هفته ۳»، یا عنوانِ خاصِ هفته اگر داشته باشد.
  String get title {
    final t = groups.isEmpty ? null : groups.first.title?.trim();
    return (t == null || t.isEmpty) ? 'هفته $weekNumber' : t;
  }

  /// همه‌ی ویدیوهای هفته، بدون توجه به گروه (برای شمارش و ایندکسِ پیوسته).
  List<CourseWeekSectionItem> get allSections =>
      [for (final g in groups) ...g.sections];

  /// وقتی هفته فقط یک گروه دارد، لایه‌ی گروه چیزی به کاربر اضافه نمی‌کند.
  bool get hasNamedGroups =>
      groups.length > 1 ||
      (groups.length == 1 && (groups.first.weekName ?? '').trim().isNotEmpty);

  /// گروه‌بندیِ لیستِ تختِ بک‌اند بر اساس `week_number`، با حفظ ترتیب.
  static List<CourseWeekGroup> groupByWeek(List<CourseWeek> weeks) {
    final order = <String>[];
    final byNumber = <String, List<CourseWeek>>{};
    for (final w in weeks) {
      if (!byNumber.containsKey(w.weekNumber)) {
        order.add(w.weekNumber);
        byNumber[w.weekNumber] = [];
      }
      byNumber[w.weekNumber]!.add(w);
    }
    return [
      for (final n in order)
        CourseWeekGroup(weekNumber: n, groups: byNumber[n]!),
    ];
  }
}

/// مربی/پشتیبانِ یک واریانت دوره. بک‌اند این را به‌صورت آبجکت می‌دهد
/// (`{id, full_name, avatar}`)، نه رشته.
class CourseCoach {
  final int id;
  final String fullName;
  final String? avatar;

  const CourseCoach({required this.id, required this.fullName, this.avatar});

  static CourseCoach? fromJson(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final name = (raw['full_name'] ?? '').toString().trim();
      if (name.isEmpty) return null;
      return CourseCoach(
        id: raw['id'] is int ? raw['id'] : int.tryParse('${raw['id']}') ?? 0,
        fullName: name,
        avatar: raw['avatar'] as String?,
      );
    }
    // سازگاری با پاسخ‌های قدیمی که مربی را رشته می‌دادند
    final s = raw?.toString().trim() ?? '';
    if (s.isEmpty || s == 'null') return null;
    return CourseCoach(id: 0, fullName: s);
  }
}

/// هدیه‌ی همراهِ خرید یک واریانت دوره (`gift_product`).
class CourseGiftProduct {
  final int id;
  final String name;
  final String? image;
  final String? icon;

  const CourseGiftProduct({
    required this.id,
    required this.name,
    this.image,
    this.icon,
  });

  static CourseGiftProduct? fromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final name = (raw['product_name'] ?? '').toString().trim();
    if (name.isEmpty) return null;
    return CourseGiftProduct(
      id: raw['id'] is int ? raw['id'] : int.tryParse('${raw['id']}') ?? 0,
      name: name,
      image: raw['image'] as String?,
      icon: raw['icon'] as String?,
    );
  }
}

class CourseTimeAndLocationItem {
  final bool isActive;
  final String? image; // relative
  final int price;

  /// برای دوره‌های غیرحضوری null است.
  final String? location;
  final String? time;
  final CourseCoach? coach;
  final String courseName;
  final CourseGiftProduct? giftProduct;
  final int id;
  final bool shipmentRequired;
  final int discountPercentage;
  final int capacity;

  CourseTimeAndLocationItem({
    required this.isActive,
    required this.image,
    required this.price,
    required this.location,
    required this.time,
    required this.coach,
    required this.courseName,
    required this.giftProduct,
    required this.id,
    required this.shipmentRequired,
    required this.discountPercentage,
    required this.capacity,
  });

  /// دوره‌ی حضوری زمان یا مکان دارد؛ دوره‌های آنلاین هیچ‌کدام را ندارند.
  bool get hasSchedule => location != null || time != null;

  factory CourseTimeAndLocationItem.fromJson(Map<String, dynamic> json) {
    return CourseTimeAndLocationItem(
      isActive: json['is_active'] == true,
      image: json['image'] as String?,
      price: json['price'] is int ? json['price'] : int.tryParse('${json['price']}') ?? 0,
      location: (json['location'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['location'] as String).trim(),
      time: (json['time'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['time'] as String).trim(),
      coach: CourseCoach.fromJson(json['coach']),
      courseName: (json['course_name'] ?? '').toString(),
      giftProduct: CourseGiftProduct.fromJson(json['gift_product']),
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      shipmentRequired: json['shipment_required'] == true,
      discountPercentage: json['discount_percentage'] is int
          ? json['discount_percentage']
          : int.tryParse('${json['discount_percentage']}') ?? 0,
      capacity: json['capacity'] is int ? json['capacity'] : int.tryParse('${json['capacity']}') ?? 0,
    );
  }
}

int _asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;

/// یک دوره‌ی زیرمجموعه داخلِ یک دوره‌ی «مجموعه‌ای».
///
/// دوره می‌تواند از چند دوره‌ی دیگر تشکیل شود و هر کدام برنامه‌ی هفتگیِ
/// خودش را دارد (همان شکلِ `detail.sections` در دوره‌ی معمولی). زیرمجموعه
/// خودش هم می‌تواند زیرمجموعه داشته باشد؛ رابط کاربری برای یک سطح طراحی
/// شده ولی سطوحِ عمیق‌تر را هم با تورفتگی نشان می‌دهد.
///
/// قراردادِ پیشنهادی با بک‌اند (داخلِ `detail`):
///   "sub_courses": [{ "id", "order", "course_title", "image",
///     "course_description", "course_difficulty", "course_duration",
///     "week_count", "video_count", "sections": [...], "sub_courses": [...] }]
class SubCourse {
  final int id;
  final int order;
  final String title;
  final String image;
  final String description;
  final String difficulty;

  /// همان واحدِ `course_duration` دوره‌ی اصلی (ثانیه)
  final int duration;
  final int weekCount;
  final int videoCount;
  final List<CourseWeek> weeks;
  final List<SubCourse> subCourses;

  const SubCourse({
    required this.id,
    required this.order,
    required this.title,
    required this.image,
    required this.description,
    required this.difficulty,
    required this.duration,
    required this.weekCount,
    required this.videoCount,
    required this.weeks,
    required this.subCourses,
  });

  List<CourseWeekGroup> get weekGroups => CourseWeekGroup.groupByWeek(weeks);

  /// تعداد ویدیوها از خودِ برنامه شمرده می‌شود؛ اگر بک‌اند برنامه را
  /// نفرستاده باشد (مثلاً در لیست)، عددِ اعلام‌شده‌اش.
  int get totalVideos {
    final own = weeks.fold<int>(0, (n, w) => n + w.sections.length);
    final nested = subCourses.fold<int>(0, (n, c) => n + c.totalVideos);
    return (own == 0 && nested == 0) ? videoCount : own + nested;
  }

  int get totalWeeks {
    final own = weekGroups.length;
    final nested = subCourses.fold<int>(0, (n, c) => n + c.totalWeeks);
    return (own == 0 && nested == 0) ? weekCount : own + nested;
  }

  /// همه‌ی ویدیوهایش قفل است (هنوز خریداری نشده)
  bool get isFullyLocked {
    final all = [for (final w in weeks) ...w.sections];
    final nestedLocked = subCourses.every((c) => c.isFullyLocked);
    return (all.isNotEmpty || subCourses.isNotEmpty) &&
        all.every((s) => s.isLocked) &&
        nestedLocked;
  }

  /// سه لایه از روی نامِ هفته‌ها.
  ///
  /// بک‌اند دوره‌ی مجموعه‌ای را (فعلاً) بدونِ `sub_courses` می‌فرستد و هر
  /// ورودیِ `sections` نامی به شکلِ «۴-دوره دریبلینگ سرعت – پا عوض کردن –
  /// هفته اول» دارد: «زیردوره – هفته/بخش». ورودی‌های پشتِ‌سرِ‌همی که
  /// زیردوره‌ی یکسان دارند یک [SubCourse] می‌شوند. ورودیِ تک (مثل «۱۶-انواع
  /// دریبل») خودش یک زیردوره با یک هفته است.
  ///
  /// اگر چیزی گروه نشد (دوره‌ی معمولی با «هفته اول، هفته دوم…») یا همه
  /// یک گروه شدند، null: دوره همان شکلِ ساده نمایش داده می‌شود.
  static List<SubCourse>? deriveFromWeekNames(List<CourseWeek> weeks) {
    if (weeks.length < 2) return null;
    final parsed = [for (final w in weeks) _splitWeekName(w.weekName)];

    // گروه‌بندیِ ورودی‌های پشتِ‌سرِ‌هم با سرِ یکسان
    final runs = <List<int>>[];
    for (int i = 0; i < weeks.length; i++) {
      final head = parsed[i].head;
      final prev = runs.isEmpty ? null : runs.last;
      if (prev != null &&
          head != null &&
          parsed[prev.last].head == head) {
        prev.add(i);
      } else {
        runs.add([i]);
      }
    }
    if (runs.length < 2 || runs.length == weeks.length) return null;

    final result = <SubCourse>[];
    for (int r = 0; r < runs.length; r++) {
      final run = runs[r];
      final single = run.length == 1;
      final first = parsed[run.first];
      final title = single ? first.full : first.head!;
      final subWeeks = <CourseWeek>[];
      for (int k = 0; k < run.length; k++) {
        final w = weeks[run[k]];
        final tail = single ? null : parsed[run[k]].tail;
        // «هفته اول/دوم…» از روی ترتیب شماره می‌خورد، نه از متن؛ متنِ
        // بک‌اند گاهی تکراری/اشتباه است. بخش‌های بی‌نامِ هفته (Upper،
        // «قواعد و راز…») نامِ خودشان را نگه می‌دارند.
        final isWeekLabel = tail == null || tail.startsWith('هفته');
        subWeeks.add(CourseWeek(
          weekNumber: w.weekNumber,
          weekName: null,
          sections: w.sections,
          title: isWeekLabel ? 'هفته ${k + 1}' : tail,
        ));
      }
      result.add(SubCourse(
        id: r + 1,
        order: r,
        title: title,
        image: '',
        description: '',
        difficulty: '',
        duration: 0,
        weekCount: subWeeks.length,
        videoCount: subWeeks.fold(0, (n, w) => n + w.sections.length),
        weeks: subWeeks,
        subCourses: const [],
      ));
    }
    return result;
  }

  static final RegExp _leadingNumber = RegExp(r'^\s*[0-9۰-۹]+\s*[-–—.)]\s*');
  static final RegExp _dash = RegExp(r'\s*[-–—]\s*');

  /// «۴-دوره X – هفته اول» → full «دوره X – هفته اول»، head «دوره X»،
  /// tail «هفته اول». بدونِ خط‌تیره، head و tail null.
  static ({String full, String? head, String? tail}) _splitWeekName(
      String? raw) {
    var full = (raw ?? '').trim().replaceFirst(_leadingNumber, '');
    full = full.replaceAll(RegExp(r'\s+'), ' ').trim();
    final matches = _dash.allMatches(full).toList();
    if (matches.isEmpty) return (full: full, head: null, tail: null);
    final m = matches.last;
    final head = full.substring(0, m.start).trim();
    final tail = full.substring(m.end).trim();
    if (head.isEmpty || tail.isEmpty) {
      return (full: full, head: null, tail: null);
    }
    // خط‌تیره‌های داخلِ خودِ نام (– در «سرعت – پا عوض کردن») یکسان می‌شوند
    return (
      full: full,
      head: head.replaceAll(_dash, ' – '),
      tail: tail,
    );
  }

  static List<SubCourse> listFrom(dynamic raw) {
    if (raw is! List) return const [];
    final list = <SubCourse>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) list.add(SubCourse.fromJson(e));
    }
    // ترتیبِ آموزشی مهم است؛ اگر order نیامده بود، ترتیبِ خودِ پاسخ می‌ماند
    // (sort پایدار است و همه صفر می‌شوند).
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  factory SubCourse.fromJson(Map<String, dynamic> json) {
    return SubCourse(
      id: _asInt(json['id']),
      order: _asInt(json['order']),
      title: (json['course_title'] ?? json['title'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      description: (json['course_description'] ?? '').toString(),
      difficulty: (json['course_difficulty'] ?? '').toString(),
      duration: _asInt(json['course_duration']),
      weekCount: _asInt(json['week_count']),
      videoCount: _asInt(json['video_count']),
      weeks: [
        for (final e in (json['sections'] as List? ?? const []))
          if (e is Map<String, dynamic>) CourseWeek.fromJson(e),
      ],
      subCourses: SubCourse.listFrom(json['sub_courses']),
    );
  }
}

class CourseDetailInner {
  final String preRequirement;
  final int videoCount;
  final int length;
  final List<CourseWeek> weeks;
  final List<CourseTimeAndLocationItem> timeAndLocation;

  /// دوره‌های تشکیل‌دهنده؛ خالی یعنی دوره‌ی معمولی.
  final List<SubCourse> subCourses;

  /// هفته‌ها پس از گروه‌بندی بر اساس `week_number`.
  List<CourseWeekGroup> get weekGroups => CourseWeekGroup.groupByWeek(weeks);

  /// دوره‌ای که از چند دوره‌ی دیگر تشکیل شده
  bool get isBundle => subCourses.isNotEmpty;

  int get bundleVideoCount =>
      subCourses.fold<int>(0, (n, c) => n + c.totalVideos) +
      weeks.fold<int>(0, (n, w) => n + w.sections.length);

  int get bundleWeekCount =>
      subCourses.fold<int>(0, (n, c) => n + c.totalWeeks) + weekGroups.length;

  CourseDetailInner({
    required this.preRequirement,
    required this.videoCount,
    required this.length,
    required this.weeks,
    required this.timeAndLocation,
    this.subCourses = const [],
  });

  factory CourseDetailInner.fromJson(Map<String, dynamic> json) {
    final weeks = (json['sections'] as List<dynamic>? ?? [])
        .map((e) => CourseWeek.fromJson(e as Map<String, dynamic>))
        .toList();
    final times = (json['time_and_location'] as List<dynamic>? ?? [])
        .map((e) => CourseTimeAndLocationItem.fromJson(e as Map<String, dynamic>))
        .toList();
    // زیرمجموعه‌ها: اگر بک‌اند `sub_courses` فرستاد همان، وگرنه از نامِ
    // هفته‌ها (و آن‌وقت هفته‌ها فقط داخلِ زیرمجموعه‌ها نمایش داده می‌شوند).
    var subs = SubCourse.listFrom(json['sub_courses']);
    var ownWeeks = weeks;
    if (subs.isEmpty) {
      final derived = SubCourse.deriveFromWeekNames(weeks);
      if (derived != null) {
        subs = derived;
        ownWeeks = const [];
      }
    }
    return CourseDetailInner(
      preRequirement: (json['pre_requirement'] ?? '').toString(),
      videoCount: json['video_count'] is int ? json['video_count'] : int.tryParse('${json['video_count']}') ?? 0,
      length: json['length'] is int ? json['length'] : int.tryParse('${json['length']}') ?? 0,
      weeks: ownWeeks,
      timeAndLocation: times,
      subCourses: subs,
    );
  }
}

class CourseDetailResponse {
  final int id;
  final int sectionCount;
  final int weekCount;
  final String courseTitle;
  final String image;
  final String courseDescription;
  final String courseDifficulty;
  final int courseDuration;
  final CourseDetailInner detail;

  CourseDetailResponse({
    required this.id,
    required this.sectionCount,
    required this.weekCount,
    required this.courseTitle,
    required this.image,
    required this.courseDescription,
    required this.courseDifficulty,
    required this.courseDuration,
    required this.detail,
  });

  factory CourseDetailResponse.fromJson(Map<String, dynamic> json) {
    return CourseDetailResponse(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      sectionCount: json['section_count'] is int ? json['section_count'] : int.tryParse('${json['section_count']}') ?? 0,
      weekCount: json['week_count'] is int ? json['week_count'] : int.tryParse('${json['week_count']}') ?? 0,
      courseTitle: (json['course_title'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      courseDescription: (json['course_description'] ?? '').toString(),
      courseDifficulty: (json['course_difficulty'] ?? '').toString(),
      courseDuration: json['course_duration'] is int ? json['course_duration'] : int.tryParse('${json['course_duration']}') ?? 0,
      detail: CourseDetailInner.fromJson(json['detail'] as Map<String, dynamic>),
    );
  }
}



/// انتخابِ واریانتِ خرید یک دوره (زمان/مکان برگزاری).
///
/// قاعده: فقط واریانتِ `is_active` قابل خرید است. اگر انتخابِ کاربر معتبر
/// نبود (پاک شده، غیرفعال شده، یا هنوز چیزی انتخاب نشده) اولین واریانتِ
/// فعال برگردانده می‌شود، و اگر هیچ فعالی نبود null.
CourseTimeAndLocationItem? pickCourseVariant(
  List<CourseTimeAndLocationItem> all,
  int? selectedId,
) {
  final active = all.where((v) => v.isActive).toList();
  if (active.isEmpty) return null;
  for (final v in active) {
    if (v.id == selectedId) return v;
  }
  return active.first;
}
