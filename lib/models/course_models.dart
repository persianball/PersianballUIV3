// lib/models/course_models.dart
import 'dart:convert';

class CoursesResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Course> results;

  CoursesResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory CoursesResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['results'] as List<dynamic>? ?? [])
        .map((e) => Course.fromJson(e as Map<String, dynamic>))
        .toList();
    return CoursesResponse(
      count: json['count'] is int
          ? json['count'] as int
          : int.tryParse('${json['count']}') ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: list,
    );
  }
}

class MyCoursesResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<MyCourse> results;

  MyCoursesResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory MyCoursesResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['results'] as List<dynamic>? ?? [])
        .map((e) => MyCourse.fromJson(e as Map<String, dynamic>))
        .toList();
    return MyCoursesResponse(
      count: json['count'] is int
          ? json['count'] as int
          : int.tryParse('${json['count']}') ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: list,
    );
  }
}

class CourseCategory {
  final int id;
  final String nameFarsi;
  final String? image;
  CourseCategory({required this.id, required this.nameFarsi, this.image});
  factory CourseCategory.fromJson(Map<String, dynamic> json) => CourseCategory(
        id: json['id'] is int ? json['id'] : int.parse('${json['id']}'),
        nameFarsi: (json['name_farsi'] ?? '').toString(),
        image: json['image'] as String?,
      );
}

class MyCourse {
  final String courseTitle;
  final String courseThumbnail;
  final int courseVariantId;
  final String courseDescription;
  final int sectionCount;
  final int completionPercent;
  final String coach;
  final int weekCount;
  final int courseId;
  final String courseExtraFile;
  final MyCourseDetail courseDetail;

  MyCourse({
    required this.courseTitle,
    required this.courseThumbnail,
    required this.courseVariantId,
    required this.courseDescription,
    required this.sectionCount,
    required this.completionPercent,
    required this.coach,
    required this.weekCount,
    required this.courseId,
    required this.courseExtraFile,
    required this.courseDetail,
  });

  factory MyCourse.fromJson(Map<String, dynamic> json) {
    return MyCourse(
      courseTitle: json['course_title'] as String? ?? '',
      courseThumbnail: json['course_thumbnail'] as String? ?? '',
      courseVariantId: json['course_variant_id'] is int
          ? json['course_variant_id'] as int
          : int.tryParse('${json['course_variant_id']}') ?? 0,
      courseDescription: json['course_description'] as String? ?? '',
      sectionCount: json['section_count'] is int
          ? json['section_count'] as int
          : int.tryParse('${json['section_count']}') ?? 0,
      completionPercent: json['completion_percent'] is int
          ? json['completion_percent'] as int
          : int.tryParse('${json['completion_percent']}') ?? 0,
      coach: json['coach'] as String? ?? '',
      weekCount: json['week_count'] is int
          ? json['week_count'] as int
          : int.tryParse('${json['week_count']}') ?? 0,
      courseId: json['course_id'] is int
          ? json['course_id'] as int
          : int.tryParse('${json['course_id']}') ?? 0,
      courseExtraFile: json['course_extra_file'] as String? ?? '',
      courseDetail: MyCourseDetail.fromJson(json['course_detail'] as Map<String, dynamic>),
    );
  }
}

class MyCourseDetail {
  final int id;
  final int sectionCount;
  final int weekCount;
  final String courseTitle;
  final String image;
  final String courseDescription;
  final String courseDifficulty;
  final int courseDuration;
  final MyCourseDetailInner detail;
  final List<MyCourseVariant> variants;
  final int discountPercentage;
  final int coursePrice;
  final List<String> images;
  final String? video;
  final String? videoThumbnail;
  final MyCourseCategory? category;

  MyCourseDetail({
    required this.id,
    required this.sectionCount,
    required this.weekCount,
    required this.courseTitle,
    required this.image,
    required this.courseDescription,
    required this.courseDifficulty,
    required this.courseDuration,
    required this.detail,
    required this.variants,
    required this.discountPercentage,
    required this.coursePrice,
    required this.images,
    required this.video,
    required this.videoThumbnail,
    required this.category,
  });

  factory MyCourseDetail.fromJson(Map<String, dynamic> json) {
    final variantsJson = json['variants'];
    final List<MyCourseVariant> parsedVariants;
    if (variantsJson is List) {
      parsedVariants = variantsJson
          .map((e) => MyCourseVariant.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (variantsJson is String) {

        final decoded = jsonDecode(variantsJson) as List<dynamic>;
        parsedVariants = decoded
            .map((e) => MyCourseVariant.fromJson(e as Map<String, dynamic>))
            .toList();

    } else {
      parsedVariants = [];
    }

    return MyCourseDetail(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      sectionCount: json['section_count'] is int
          ? json['section_count'] as int
          : int.tryParse('${json['section_count']}') ?? 0,
      weekCount: json['week_count'] is int
          ? json['week_count'] as int
          : int.tryParse('${json['week_count']}') ?? 0,
      courseTitle: (json['course_title'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      courseDescription: (json['course_description'] ?? '').toString(),
      courseDifficulty: (json['course_difficulty'] ?? '').toString(),
      courseDuration: json['course_duration'] is int
          ? json['course_duration'] as int
          : int.tryParse('${json['course_duration']}') ?? 0,
      detail: MyCourseDetailInner.fromJson(json['detail'] as Map<String, dynamic>),
      variants: parsedVariants,
      discountPercentage: json['discount_percentage'] is int
          ? json['discount_percentage'] as int
          : int.tryParse('${json['discount_percentage']}') ?? 0,
      coursePrice: json['course_price'] is int
          ? json['course_price'] as int
          : int.tryParse('${json['course_price']}') ?? 0,
      images: (json['images'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      video: json['video']?.toString(),
      videoThumbnail: json['video_thumbnail']?.toString(),
      category: json['category'] is Map<String, dynamic>
          ? MyCourseCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MyCourseDetailInner {
  final String preRequirement;
  final int videoCount;
  final int length;
  final List<MyCourseWeek> weeks;
  final List<MyCourseTimeAndLocationItem> timeAndLocation;

  MyCourseDetailInner({
    required this.preRequirement,
    required this.videoCount,
    required this.length,
    required this.weeks,
    required this.timeAndLocation,
  });

  factory MyCourseDetailInner.fromJson(Map<String, dynamic> json) {
    final sections = json['sections'] as List<dynamic>? ?? [];
    final weeks = sections
        .map((e) => MyCourseWeek.fromJson(e as Map<String, dynamic>))
        .toList();

    final times = json['time_and_location'] as List<dynamic>? ?? [];
    final timeItems = times
        .map((e) => MyCourseTimeAndLocationItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return MyCourseDetailInner(
      preRequirement: (json['pre_requirement'] ?? '').toString(),
      videoCount: json['video_count'] is int
          ? json['video_count'] as int
          : int.tryParse('${json['video_count']}') ?? 0,
      length: json['length'] is int
          ? json['length'] as int
          : int.tryParse('${json['length']}') ?? 0,
      weeks: weeks,
      timeAndLocation: timeItems,
    );
  }
}

class MyCourseWeek {
  final String weekNumber;
  final String? weekName;
  final List<MyCourseWeekSectionItem> sections;

  MyCourseWeek({
    required this.weekNumber,
    required this.weekName,
    required this.sections,
  });

  factory MyCourseWeek.fromJson(Map<String, dynamic> json) {
    return MyCourseWeek(
      weekNumber: (json['week_number'] ?? '').toString(),
      weekName: json['week_name']?.toString(),
      sections: (json['sections'] as List<dynamic>? ?? [])
          .map((e) => MyCourseWeekSectionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MyCourseWeekSectionItem {
  final String title;
  final bool isLocked;
  final String? videoUrl;
  final String? videoThumbnail;

  MyCourseWeekSectionItem({
    required this.title,
    required this.isLocked,
    this.videoUrl,
    this.videoThumbnail,
  });

  factory MyCourseWeekSectionItem.fromJson(Map<String, dynamic> json) {
    return MyCourseWeekSectionItem(
      title: (json['title'] ?? '').toString(),
      isLocked: json['is_locked'] == true,
      videoUrl: json['video_url']?.toString(),
      videoThumbnail: json['video_thumbnail']?.toString(),
    );
  }
}

class MyCourseVariant {
  final bool isActive;
  final String? image;
  final int price;
  final String? location;
  final String? time;
  final MyCourseCoach? coach;
  final String courseName;
  final String? giftProduct;
  final int id;
  final bool shipmentRequired;
  final int discountPercentage;
  final int capacity;

  MyCourseVariant({
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

  factory MyCourseVariant.fromJson(Map<String, dynamic> json) {
    return MyCourseVariant(
      isActive: json['is_active'] == true,
      image: json['image']?.toString(),
      price: json['price'] is int ? json['price'] as int : int.tryParse('${json['price']}') ?? 0,
      location: json['location']?.toString(),
      time: json['time']?.toString(),
      coach: json['coach'] is Map<String, dynamic>
          ? MyCourseCoach.fromJson(json['coach'] as Map<String, dynamic>)
          : null,
      courseName: (json['course_name'] ?? '').toString(),
      giftProduct: json['gift_product']?.toString(),
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      shipmentRequired: json['shipment_required'] == true,
      discountPercentage: json['discount_percentage'] is int
          ? json['discount_percentage'] as int
          : int.tryParse('${json['discount_percentage']}') ?? 0,
      capacity: json['capacity'] is int
          ? json['capacity'] as int
          : int.tryParse('${json['capacity']}') ?? 0,
    );
  }
}

class MyCourseCoach {
  final int id;
  final String fullName;
  final String? avatar;

  MyCourseCoach({
    required this.id,
    required this.fullName,
    this.avatar,
  });

  factory MyCourseCoach.fromJson(Map<String, dynamic> json) {
    return MyCourseCoach(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      fullName: (json['full_name'] ?? '').toString(),
      avatar: json['avatar']?.toString(),
    );
  }
}

class MyCourseTimeAndLocationItem {
  final bool isActive;
  final String? image;
  final int price;
  final String? location;
  final String? time;
  final MyCourseCoach? coach;
  final String courseName;
  final String? giftProduct;
  final int id;
  final bool shipmentRequired;
  final int discountPercentage;
  final int capacity;

  MyCourseTimeAndLocationItem({
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

  factory MyCourseTimeAndLocationItem.fromJson(Map<String, dynamic> json) {
    return MyCourseTimeAndLocationItem(
      isActive: json['is_active'] == true,
      image: json['image']?.toString(),
      price: json['price'] is int ? json['price'] as int : int.tryParse('${json['price']}') ?? 0,
      location: json['location']?.toString(),
      time: json['time']?.toString(),
      coach: json['coach'] is Map<String, dynamic>
          ? MyCourseCoach.fromJson(json['coach'] as Map<String, dynamic>)
          : null,
      courseName: (json['course_name'] ?? '').toString(),
      giftProduct: json['gift_product']?.toString(),
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      shipmentRequired: json['shipment_required'] == true,
      discountPercentage: json['discount_percentage'] is int
          ? json['discount_percentage'] as int
          : int.tryParse('${json['discount_percentage']}') ?? 0,
      capacity: json['capacity'] is int ? json['capacity'] as int : int.tryParse('${json['capacity']}') ?? 0,
    );
  }
}

class MyCourseCategory {
  final int id;
  final String nameFarsi;
  final String? image;

  MyCourseCategory({
    required this.id,
    required this.nameFarsi,
    this.image,
  });

  factory MyCourseCategory.fromJson(Map<String, dynamic> json) {
    return MyCourseCategory(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      nameFarsi: (json['name_farsi'] ?? '').toString(),
      image: json['image']?.toString(),
    );
  }
}

class Course {
  final int id;
  final String image; // relative path e.g. /media/images/.. .jpg
  final int coursePrice;
  final int discountPercentage;
  final CourseCategory category;
  final String nameFarsi;
  final String nameEnglish;
  final String description;
  final bool published;
  final String difficulty;
  final String preRequirement;
  final int sortingOrder;
  final String createdAt; // ISO string
  final int? video;
  final String? videoThumbnail;
  final String? courseExtraFile;
  final List<String> images; // ids or uuids coming as strings
  final List<int> similarCourses;
  final List<int> suggestedSupportCoaches;

  Course({
    required this.id,
    required this.image,
    required this.coursePrice,
    required this.discountPercentage,
    required this.category,
    required this.nameFarsi,
    required this.nameEnglish,
    required this.description,
    required this.published,
    required this.difficulty,
    required this.preRequirement,
    required this.sortingOrder,
    required this.createdAt,
    required this.video,
    required this.videoThumbnail,
    required this.courseExtraFile,
    required this.images,
    required this.similarCourses,
    required this.suggestedSupportCoaches,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    if (json.containsKey("course_id")) {}
    return Course(
      id: json['id'] is int ? json['id'] : int.parse('${json['id']}'),
      image: (json['image'] ?? '').toString(),
      coursePrice: json['course_price'] is int
          ? json['course_price']
          : int.tryParse('${json['course_price']}') ?? 0,
      discountPercentage: json['discount_percentage'] is int
          ? json['discount_percentage']
          : int.tryParse('${json['discount_percentage']}') ?? 0,
      category:
          CourseCategory.fromJson(json['category'] as Map<String, dynamic>),
      nameFarsi: (json['name_farsi'] ?? '').toString(),
      nameEnglish: (json['name_english'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      published: json['published'] == true,
      difficulty: (json['difficulty'] ?? '').toString(),
      preRequirement: (json['pre_requirement'] ?? '').toString(),
      sortingOrder: json['sorting_order'] is int
          ? json['sorting_order']
          : int.tryParse('${json['sorting_order']}') ?? 0,
      createdAt: (json['created_at'] ?? '').toString(),
      video: json['video'] == null
          ? null
          : (json['video'] is int
              ? json['video']
              : int.tryParse('${json['video']}')),
      videoThumbnail: json['video_thumbnail'] as String?,
      courseExtraFile: json['course_extra_file'] as String?,
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      similarCourses: (json['simillar_courses'] as List<dynamic>? ?? [])
          .map((e) => int.tryParse('$e') ?? 0)
          .toList(),
      suggestedSupportCoaches:
          (json['suggested_support_coaches'] as List<dynamic>? ?? [])
              .map((e) => int.tryParse('$e') ?? 0)
              .toList(),
    );
  }
}
