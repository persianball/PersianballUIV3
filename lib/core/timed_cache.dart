// lib/core/timed_cache.dart
//
// کشِ کوتاه‌مدتِ درون‌حافظه برای پاسخ‌های «جزییات».
//
// سرور برای هر درخواست حدودِ یک ثانیه (روی اینترنتِ همراه بیشتر) طول می‌کشد.
// بدونِ کش، هر بار باز کردنِ یک محصول یا دوره، حتی همانی که چند ثانیه پیش
// دیده شده، دوباره اسکلتِ بارگذاری نشان می‌داد و جابه‌جایی بین صفحه‌ها کند
// حس می‌شد. اینجا پاسخِ موفق چند دقیقه نگه داشته می‌شود؛ خطا هیچ‌وقت کش
// نمی‌شود و «کشیدن برای تازه‌سازی» با refresh کش را دور می‌زند.
class TimedCache<K, V> {
  TimedCache({this.ttl = const Duration(minutes: 3), this.maxEntries = 40});

  final Duration ttl;
  final int maxEntries;

  final Map<K, (V, DateTime)> _values = {};
  final Map<K, Future<V>> _inFlight = {};

  /// مقدارِ تازه، اگر هست؛ بدونِ هیچ درخواستی.
  V? peek(K key) {
    final hit = _values[key];
    if (hit == null) return null;
    if (DateTime.now().difference(hit.$2) > ttl) {
      _values.remove(key);
      return null;
    }
    return hit.$1;
  }

  /// از کش، یا با [load]. درخواست‌های همزمانِ یک کلید یکی می‌شوند.
  Future<V> get(K key, Future<V> Function() load, {bool refresh = false}) {
    if (!refresh) {
      final hit = peek(key);
      if (hit != null) return Future<V>.value(hit);
      final pending = _inFlight[key];
      if (pending != null) return pending;
    }
    final future = load().then((value) {
      _values.remove(key);
      _values[key] = (value, DateTime.now());
      while (_values.length > maxEntries) {
        _values.remove(_values.keys.first);
      }
      return value;
    });
    _inFlight[key] = future;
    // خطا به فراخوان می‌رسد؛ اینجا فقط ثبتِ «در جریان» پاک می‌شود.
    future.whenComplete(() {
      if (identical(_inFlight[key], future)) _inFlight.remove(key);
    }).ignore();
    return future;
  }

  void clear() {
    _values.clear();
    _inFlight.clear();
  }
}
