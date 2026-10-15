// «·» (نقطه‌ی وسط) در فارسی عیناً شبیهِ رقمِ صفر «۰» است. وقتی کنارِ عدد
// می‌نشست، «۱۶۲ · ویدیو» به‌صورتِ «۱۶۲۰ ویدیو» و «۱۴۰۴ · ۱۴:۱۸» به‌صورتِ
// «۱۴۰۴۰ ۱۴:۱۸» خوانده می‌شد. این تست جلوی برگشتنش به متن‌های رابط را
// می‌گیرد (کامنت‌ها مستثنا هستند).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('هیچ متنِ رابطی «·» ندارد', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = lines[i].split('//').first; // drop trailing comments
        if (code.trim().isEmpty) continue;
        if (code.contains('·')) offenders.add('${f.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty,
        reason: 'به‌جای «·» از «،» استفاده کنید: ${offenders.join(', ')}');
  });
}
