// lib/models/super_course.dart
//
// سوپرکورس = لایه‌ی اولِ ساختارِ سه‌لایه‌ی آموزش:
//   سوپرکورس (مسیرِ آموزشی) → دوره‌ها → هفته‌ها و ویدیوها
//
//   GET /v2/product/super-course/                → {count, next, previous, results}
//   GET /v2/product/super-course/<id|english>/   → یک سوپرکورس
//   GET /v2/product/course/<id>/                 → دوره (لایه‌ی دوم و سوم)
//
// شمای OpenAPI: {id, name_farsi, name_english, description, image,
// video_thumbnail, sorting_order, created_at, courses}. فیلدِ `courses` یک
// SerializerMethodField است و در اسکیما فقط «string» آمده؛ شکلِ واقعی‌اش
// هنوز دیده نشده (سرور تا این لحظه هیچ سوپرکورسی ندارد). پس هر سه شکل
// پذیرفته می‌شود: لیستِ شناسه، لیستِ آبجکتِ دوره (شکلِ لیست یا جزئیات)، یا
// همین‌ها به‌صورتِ رشته‌ی JSON.
import 'dart:convert';

int _int(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}'.trim()) ?? 0;

String _str(dynamic v) => v == null ? '' : '$v'.trim();

/// یک دوره داخلِ سوپرکورس.
class SuperCourseItem {
  final int id;
  final int order;
  final String title;
  final String image;
  final String difficulty;
  final int price;
  final int discountPercentage;
  final int weekCount;
  final int videoCount;

  const SuperCourseItem({
    required this.id,
    this.order = 0,
    this.title = '',
    this.image = '',
    this.difficulty = '',
    this.price = 0,
    this.discountPercentage = 0,
    this.weekCount = 0,
    this.videoCount = 0,
  });

  /// فقط شناسه آمده و باید از /v2/product/course/<id>/ کامل شود.
  bool get needsDetails => title.isEmpty;

  int get finalPrice => discountPercentage > 0
      ? price - (price * discountPercentage) ~/ 100
      : price;

  /// شکلِ لیستِ دوره‌ها (name_farsi، difficulty، course_price) و شکلِ
  /// جزئیاتِ دوره (course_title، course_difficulty، section_count) هر دو.
  factory SuperCourseItem.fromJson(Map<String, dynamic> j, {int order = 0}) {
    final course = j['course'];
    final id = course is Map<String, dynamic>
        ? _int(course['id'])
        : _int(j['course_id'] ?? (course is! Map ? course : null) ?? j['id']);
    final src = course is Map<String, dynamic> ? course : j;
    return SuperCourseItem(
      id: id,
      order: j.containsKey('sorting_order') || j.containsKey('order')
          ? _int(j['sorting_order'] ?? j['order'])
          : order,
      title: _str(src['name_farsi'] ?? src['course_title'] ?? src['title']),
      image: _str(src['image']),
      difficulty: _str(src['difficulty'] ?? src['course_difficulty']),
      price: _int(src['course_price'] ?? src['price']),
      discountPercentage: _int(src['discount_percentage']),
      weekCount: _int(src['week_count']),
      videoCount: _int(src['section_count'] ?? src['video_count']),
    );
  }

  SuperCourseItem filledWith({
    required String title,
    required String image,
    required String difficulty,
    required int weekCount,
    required int videoCount,
  }) =>
      SuperCourseItem(
        id: id,
        order: order,
        title: title,
        image: this.image.isNotEmpty ? this.image : image,
        difficulty: this.difficulty.isNotEmpty ? this.difficulty : difficulty,
        price: price,
        discountPercentage: discountPercentage,
        weekCount: this.weekCount > 0 ? this.weekCount : weekCount,
        videoCount: this.videoCount > 0 ? this.videoCount : videoCount,
      );

  /// `courses` در هر شکلی → لیستِ مرتب بر اساسِ ترتیبِ آموزشی.
  static List<SuperCourseItem> listFrom(dynamic raw) {
    var value = raw;
    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return const [];
      try {
        value = jsonDecode(s);
      } catch (_) {
        // «12,13,14»
        value = s.split(RegExp(r'[,\s]+'));
      }
    }
    if (value is Map && value['results'] is List) value = value['results'];
    if (value is! List) return const [];

    final items = <SuperCourseItem>[];
    for (var i = 0; i < value.length; i++) {
      final e = value[i];
      final item = e is Map<String, dynamic>
          ? SuperCourseItem.fromJson(e, order: i)
          : SuperCourseItem(id: _int(e), order: i);
      if (item.id > 0 && !items.any((x) => x.id == item.id)) items.add(item);
    }
    // sort پایدار است: بدونِ ترتیبِ صریح، ترتیبِ خودِ پاسخ می‌ماند.
    items.sort((a, b) => a.order.compareTo(b.order));
    return items;
  }
}

class SuperCourse {
  final int id;
  final String nameFarsi;
  final String nameEnglish;
  final String description;
  final String image;
  final String videoThumbnail;
  final int sortingOrder;
  final List<SuperCourseItem> courses;

  const SuperCourse({
    required this.id,
    required this.nameFarsi,
    this.nameEnglish = '',
    this.description = '',
    this.image = '',
    this.videoThumbnail = '',
    this.sortingOrder = 0,
    this.courses = const [],
  });

  String get title => nameFarsi.isNotEmpty
      ? nameFarsi
      : (nameEnglish.isNotEmpty ? nameEnglish : 'مسیر آموزشی');

  /// آدرسِ صفحه: نامِ انگلیسی اگر قابلِ استفاده در لینک باشد، وگرنه شناسه.
  String get route {
    final slug = nameEnglish.trim();
    return RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(slug)
        ? '/super-course/$slug'
        : '/super-course/$id';
  }

  String get cover => image.isNotEmpty ? image : videoThumbnail;

  int get totalWeeks => courses.fold(0, (n, c) => n + c.weekCount);
  int get totalVideos => courses.fold(0, (n, c) => n + c.videoCount);

  factory SuperCourse.fromJson(Map<String, dynamic> j) => SuperCourse(
        id: _int(j['id']),
        nameFarsi: _str(j['name_farsi']),
        nameEnglish: _str(j['name_english']),
        description: _str(j['description']),
        image: _str(j['image']),
        videoThumbnail: _str(j['video_thumbnail']),
        sortingOrder: _int(j['sorting_order']),
        courses: SuperCourseItem.listFrom(j['courses']),
      );

  SuperCourse withCourses(List<SuperCourseItem> list) => SuperCourse(
        id: id,
        nameFarsi: nameFarsi,
        nameEnglish: nameEnglish,
        description: description,
        image: image,
        videoThumbnail: videoThumbnail,
        sortingOrder: sortingOrder,
        courses: list,
      );
}

/// سوپرکورس‌هایی که یک دوره عضوشان است (`super_courses` در جزئیاتِ دوره):
/// شناسه یا آبجکتِ خلاصه.
class SuperCourseRef {
  final int id;
  final String name;
  final String nameEnglish;

  const SuperCourseRef({required this.id, this.name = '', this.nameEnglish = ''});

  String get route {
    final slug = nameEnglish.trim();
    return RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(slug)
        ? '/super-course/$slug'
        : '/super-course/$id';
  }

  static List<SuperCourseRef> listFrom(dynamic raw) {
    if (raw is! List) return const [];
    final out = <SuperCourseRef>[];
    for (final e in raw) {
      final ref = e is Map<String, dynamic>
          ? SuperCourseRef(
              id: _int(e['id']),
              name: _str(e['name_farsi'] ?? e['name'] ?? e['title']),
              nameEnglish: _str(e['name_english']),
            )
          : SuperCourseRef(id: _int(e));
      if (ref.id > 0) out.add(ref);
    }
    return out;
  }
}
