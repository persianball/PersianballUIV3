// lib/views/widgets/super_course_strip.dart
//
// ردیفِ «مسیرهای آموزشی» (سوپرکورس‌ها) بالای لیستِ دوره‌ها.
import 'package:flutter/material.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:persian_ball/models/super_course.dart';
import 'package:persian_ball/views/screens/super_course_page.dart'
    show superCourseMediaUrl;
import 'package:persian_ball/views/widgets/app_network_image.dart';

class SuperCourseStrip extends StatelessWidget {
  const SuperCourseStrip({
    super.key,
    required this.items,
    this.horizontalPadding = 16,
  });

  final List<SuperCourse> items;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
              horizontalPadding, 16, horizontalPadding, 10),
          child: const Row(
            children: [
              Icon(Icons.route_rounded, size: 20, color: AppColor.pitchGreen),
              SizedBox(width: 6),
              Text('مسیرهای آموزشی',
                  style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColor.ink)),
            ],
          ),
        ),
        SizedBox(
          height: 206,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _card(context, items[i]),
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, SuperCourse sc) {
    final cover = superCourseMediaUrl(sc.cover);
    return SizedBox(
      width: 240,
      child: Material(
        color: AppColor.card,
        shape: AppShapes.border(AppShapes.rLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              Navigator.of(context).pushNamed(sc.route, arguments: sc),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 135,
                child: AppNetworkImage(
                  url: cover.isEmpty ? null : cover,
                  fit: BoxFit.cover,
                  fallbackAsset: 'assets/images/course_not_found.jpg',
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Text(sc.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColor.ink)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Text(
                    sc.courses.isEmpty
                        ? 'مسیر آموزشی'
                        : '${sc.courses.length} دوره به ترتیب',
                    style: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 12,
                        color: AppColor.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
