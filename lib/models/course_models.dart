// lib/models/course_models.dart

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
      count: json['count'] is int ? json['count'] as int : int.tryParse('${json['count']}') ?? 0,
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
    return Course(
      id: json['id'] is int ? json['id'] : int.parse('${json['id']}'),
      image: (json['image'] ?? '').toString(),
      coursePrice: json['course_price'] is int
          ? json['course_price']
          : int.tryParse('${json['course_price']}') ?? 0,
      discountPercentage: json['discount_percentage'] is int
          ? json['discount_percentage']
          : int.tryParse('${json['discount_percentage']}') ?? 0,
      category: CourseCategory.fromJson(json['category'] as Map<String, dynamic>),
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
          : (json['video'] is int ? json['video'] : int.tryParse('${json['video']}')),
      videoThumbnail: json['video_thumbnail'] as String?,
      courseExtraFile: json['course_extra_file'] as String?,
      images: (json['images'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      similarCourses: (json['simillar_courses'] as List<dynamic>? ?? [])
          .map((e) => int.tryParse('$e') ?? 0)
          .toList(),
      suggestedSupportCoaches: (json['suggested_support_coaches'] as List<dynamic>? ?? [])
          .map((e) => int.tryParse('$e') ?? 0)
          .toList(),
    );
  }
}