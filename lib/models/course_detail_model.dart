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

  CourseWeek({
    required this.weekNumber,
    required this.weekName,
    required this.sections,
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

class CourseDetailInner {
  final String preRequirement;
  final int videoCount;
  final int length;
  final List<CourseWeek> weeks;
  final List<CourseTimeAndLocationItem> timeAndLocation;

  /// هفته‌ها پس از گروه‌بندی بر اساس `week_number`.
  List<CourseWeekGroup> get weekGroups => CourseWeekGroup.groupByWeek(weeks);

  CourseDetailInner({
    required this.preRequirement,
    required this.videoCount,
    required this.length,
    required this.weeks,
    required this.timeAndLocation,
  });

  factory CourseDetailInner.fromJson(Map<String, dynamic> json) {
    final weeks = (json['sections'] as List<dynamic>? ?? [])
        .map((e) => CourseWeek.fromJson(e as Map<String, dynamic>))
        .toList();
    final times = (json['time_and_location'] as List<dynamic>? ?? [])
        .map((e) => CourseTimeAndLocationItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return CourseDetailInner(
      preRequirement: (json['pre_requirement'] ?? '').toString(),
      videoCount: json['video_count'] is int ? json['video_count'] : int.tryParse('${json['video_count']}') ?? 0,
      length: json['length'] is int ? json['length'] : int.tryParse('${json['length']}') ?? 0,
      weeks: weeks,
      timeAndLocation: times,
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


