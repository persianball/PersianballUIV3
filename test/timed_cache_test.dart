import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/core/timed_cache.dart';

void main() {
  test('بازدیدِ دوباره از حافظه می‌آید و درخواست‌های همزمان یکی می‌شوند',
      () async {
    final cache = TimedCache<int, String>();
    int loads = 0;
    Future<String> load() async {
      loads++;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      return 'v$loads';
    }

    final both = await Future.wait([cache.get(1, load), cache.get(1, load)]);
    expect(both, ['v1', 'v1']);
    expect(await cache.get(1, load), 'v1');
    expect(cache.peek(1), 'v1');
    expect(loads, 1);

    expect(await cache.get(1, load, refresh: true), 'v2');
    expect(loads, 2);
  });

  test('خطا کش نمی‌شود و مقدارِ کهنه دور ریخته می‌شود', () async {
    final cache = TimedCache<int, String>(ttl: const Duration(milliseconds: 20));
    int calls = 0;
    Future<String> flaky() async {
      calls++;
      if (calls == 1) throw Exception('x');
      return 'ok';
    }

    await expectLater(cache.get(1, flaky), throwsException);
    expect(cache.peek(1), isNull);
    expect(await cache.get(1, flaky), 'ok');
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(cache.peek(1), isNull);
  });
}
