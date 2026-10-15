// انتخاب واریانت دوره: پیش‌تر دکمه‌ی خرید همیشه اولین واریانتِ فعال را
// می‌فرستاد، پس دوره‌های چندزمانه فقط یک گزینه‌ی قابل‌خرید داشتند.
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/models/course_detail_model.dart';

CourseTimeAndLocationItem _v(int id, {required bool active}) =>
    CourseTimeAndLocationItem.fromJson({
      'id': id,
      'is_active': active,
      'price': 1000,
      'location': 'سالن $id',
      'time': 'شنبه',
      'course_name': 'دوره',
      'capacity': 10,
    });

void main() {
  test('واریانتِ انتخاب‌شده برگردانده می‌شود، نه صرفاً اولی', () {
    final all = [_v(1, active: true), _v(2, active: true), _v(3, active: true)];
    expect(pickCourseVariant(all, 3)?.id, 3);
    expect(pickCourseVariant(all, 2)?.id, 2);
  });

  test('بدون انتخاب، اولین واریانتِ فعال', () {
    final all = [_v(1, active: false), _v(2, active: true)];
    expect(pickCourseVariant(all, null)?.id, 2);
  });

  test('واریانت غیرفعال قابل انتخاب نیست', () {
    final all = [_v(1, active: true), _v(2, active: false)];
    expect(pickCourseVariant(all, 2)?.id, 1);
  });

  test('وقتی هیچ واریانت فعالی نیست، خرید ممکن نیست', () {
    expect(pickCourseVariant([_v(1, active: false)], 1), isNull);
    expect(pickCourseVariant(const [], null), isNull);
  });
}
