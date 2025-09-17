// lib/views/screens/course_detail_page.dart
import 'package:flutter/material.dart';
import 'package:marketky/constant/urls.dart';
import 'package:marketky/models/course_detail_model.dart';
import 'package:marketky/services/course_service.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<CourseDetailResponse>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
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
                      Text('خطا در بارگذاری جزییات دوره'),
                      const SizedBox(height: 8),
                      Text('${snapshot.error}'),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => setState(() => _future = CourseService.fetchCourseDetail(id: widget.id)),
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  stretch: true,
                  expandedHeight: 240,
                  title: const Text('جزییات دوره'),
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        data.image.isEmpty
                            ? Container(color: Colors.grey[200])
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
                        Text(data.courseTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text('سطح: ${data.courseDifficulty}')),
                            Chip(label: Text('تعداد هفته: ${data.weekCount}')),
                            Chip(label: Text('تعداد سکشن: ${data.sectionCount}')),
                            Chip(label: Text('مدت دوره: ${_formatDuration(data.courseDuration)}')),
                            Chip(label: Text('تعداد ویدیو: ${data.detail.videoCount}')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            data.courseDescription,
                            key: ValueKey(data.id),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('پیش‌نیاز', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(data.detail.preRequirement),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: const Text('برنامه هفتگی', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final week = data.detail.weeks[index];
                      return _AnimatedSlideFade(
                        delayMs: 50 * index,
                        child: Card(
                          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: ExpansionTile(
                            title: Text('هفته ${week.weekNumber}${week.weekName == null || week.weekName!.isEmpty ? '' : ' - ${week.weekName}'}'),
                            children: week.sections.asMap().entries.map((entry) {
                              final i = entry.key;
                              final s = entry.value;
                              return _AnimatedSlideFade(
                                delayMs: 40 * i,
                                child: ListTile(
                                  leading: Icon(s.isLocked ? Icons.lock : Icons.play_circle_fill, color: s.isLocked ? Colors.grey : Colors.green),
                                  title: Text(s.title),
                                  subtitle: (s.videoUrl != null && s.videoUrl!.isNotEmpty)
                                      ? Text(s.videoUrl!)
                                      : null,
                                  trailing: s.videoThumbnail != null && s.videoThumbnail!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.network(_abs(s.videoThumbnail!), width: 56, height: 36, fit: BoxFit.cover),
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                    childCount: data.detail.weeks.length,
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: const Text('زمان و مکان برگزاری', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = data.detail.timeAndLocation[index];
                      return _AnimatedSlideFade(
                        delayMs: 60 * index,
                        child: Card(
                          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: item.image == null || item.image!.isEmpty
                                      ? Container(width: 80, height: 80, color: Colors.grey[200])
                                      : Image.network(_abs(item.image!), width: 80, height: 80, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Image.asset('assets/images/placeholder.jpg',width: 80, height: 80, fit: BoxFit.cover)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(item.location, style: const TextStyle(fontWeight: FontWeight.w700)),
                                          const SizedBox(width: 8),
                                          if (item.isActive) const Chip(label: Text('فعال')),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(item.time),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text('${thousandSeparator(item.price)} تومان', style: const TextStyle(fontWeight: FontWeight.w800)),
                                          const SizedBox(width: 8),
                                          if (item.discountPercentage > 0)
                                            Chip(label: Text('%${item.discountPercentage} تخفیف')),
                                          const Spacer(),
                                          Chip(label: Text('ظرفیت: ${item.capacity}')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: data.detail.timeAndLocation.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
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