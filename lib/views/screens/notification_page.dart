// lib/views/screens/notification_page.dart
//
// اعلان‌ها = صندوق پیامِ واقعیِ کاربر از /v1/user/messages/.
//
// نسخه‌ی قبلی سه اعلانِ ثابت نشان می‌داد و «خوانده‌شده» را فقط در حافظه‌ی
// مرورگر نگه می‌داشت. حالا همان پیام‌هایی که سرور برای کاربر ساخته نشان داده
// می‌شوند و «خوانده شد» با PATCHِ seen_at روی سرور ثبت می‌شود، پس روی همه‌ی
// دستگاه‌های کاربر یکی است.
import 'package:firebase_messaging/firebase_messaging.dart' show AuthorizationStatus;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:persian_ball/services/push_notification_service.dart';
import 'package:persian_ball/constant/app_breakpoints.dart';
import 'package:persian_ball/constant/app_shapes.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/services/auth_service.dart';
import 'package:persian_ball/services/user_message_service.dart';
import 'package:persian_ball/utils/jalali_date.dart';
import 'package:persian_ball/views/screens/message_detail_page.dart';
import 'package:persian_ball/views/widgets/motion.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final List<UserMessage> _items = [];
  final ScrollController _scroll = ScrollController();
  String? _nextUrl;

  bool _loading = true;
  bool _loadingMore = false;
  bool _needsLogin = false;
  bool _markingAll = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    // نشانِ زنگوله‌ی خانه بعد از دیدنِ اعلان‌ها باید با سرور یکی شود.
    UserMessageService.refreshUnread();
    super.dispose();
  }

  int get _unread => _items.where((m) => !m.isRead).length;

  Future<void> _load({bool more = false}) async {
    if (!more) {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _needsLogin = true;
          _loading = false;
        });
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _needsLogin = false;
      if (more) {
        _loadingMore = true;
      } else {
        _loading = _items.isEmpty;
        _error = null;
      }
    });
    try {
      final page =
          await UserMessageService.fetch(nextUrl: more ? _nextUrl : null);
      if (!mounted) return;
      setState(() {
        if (!more) _items.clear();
        final seen = {for (final m in _items) m.id};
        _items.addAll(page.results.where((m) => seen.add(m.id)));
        _nextUrl = page.next;
        _loading = false;
        _loadingMore = false;
      });
      _syncBadge();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (msg == 'نیاز به ورود') {
          _needsLogin = true;
        } else if (_items.isEmpty) {
          // خطای صفحه‌ی بعد نباید چیزی را که نشان داده‌ایم پاک کند.
          _error = msg;
        }
      });
    }
  }

  void _onScroll() {
    if (_nextUrl == null || _loading || _loadingMore) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
      _load(more: true);
    }
  }

  /// وقتی همه‌ی صفحه‌ها آمده‌اند شمارش همین‌جا دقیق است؛ وگرنه از سرور
  /// دوباره شمرده می‌شود.
  void _syncBadge() {
    if (_nextUrl == null) {
      UserMessageService.unreadNotifier.value = _unread;
    } else {
      UserMessageService.refreshUnread();
    }
  }

  /// باز کردن پیام و ثبتِ «خوانده شد»: ردیف همان لحظه بی‌نشان می‌شود و اگر
  /// سرور نپذیرفت برمی‌گردد.
  Future<void> _open(UserMessage m) async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MessageDetailPage(data: m)),
    );
    final id = m.id;
    if (m.isRead || id == null) return;
    _replace(id, m.copyWithSeen(DateTime.now()));
    if (!await UserMessageService.markSeen(id)) _replace(id, m);
  }

  void _replace(int id, UserMessage m) {
    if (!mounted) return;
    final at = _items.indexWhere((x) => x.id == id);
    if (at == -1) return;
    setState(() => _items[at] = m);
    _syncBadge();
  }

  Future<void> _markAll() async {
    final unread = [for (final m in _items) if (!m.isRead && m.id != null) m];
    if (unread.isEmpty) return;
    final now = DateTime.now();
    setState(() {
      _markingAll = true;
      for (var i = 0; i < _items.length; i++) {
        if (!_items[i].isRead) _items[i] = _items[i].copyWithSeen(now);
      }
    });
    _syncBadge();
    final failed =
        await UserMessageService.markAllSeen(unread.map((m) => m.id!));
    if (!mounted) return;
    setState(() => _markingAll = false);
    for (final m in unread) {
      if (failed.contains(m.id)) _replace(m.id!, m);
    }
    if (failed.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('بعضی پیام‌ها خوانده‌شده ثبت نشدند',
            style: TextStyle(fontFamily: 'Estedad')),
      ));
    }
  }

  Future<void> _login() async {
    final ok = await Navigator.of(context)
        .pushNamed<bool>('/login', arguments: {'popOnSuccess': true});
    if (ok == true && mounted) {
      setState(() => _loading = true);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.obsidianBg,
        appBar: AppBar(
          backgroundColor: AppColor.obsidianBg,
          foregroundColor: AppColor.onSurface,
          elevation: 0,
          title: const Text('اعلان‌ها',
              style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 16,
                  color: AppColor.onSurface)),
          actions: [
            if (!_needsLogin && _unread > 0)
              TextButton(
                onPressed: _markingAll ? null : _markAll,
                child: const Text('خواندن همه',
                    style: TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 12,
                        color: AppColor.goldEnd)),
              ),
          ],
        ),
        body: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColor.goldEnd));
    }
    if (_needsLogin) {
      return _message(
        icon: Icons.lock_outline,
        title: 'وارد حساب کاربری نشده‌اید',
        subtitle: 'برای دیدن اعلان‌ها ابتدا وارد حساب کاربری شوید',
        action: 'ورود به حساب کاربری',
        onAction: _login,
      );
    }
    if (_error != null) {
      return _message(
        icon: Icons.wifi_off_rounded,
        title: 'اعلان‌ها دریافت نشد',
        subtitle: _error!,
        action: 'تلاش دوباره',
        onAction: () {
          setState(() => _loading = true);
          _load();
        },
      );
    }
    return RefreshIndicator(
      color: AppColor.goldEnd,
      onRefresh: () async {
        _nextUrl = null;
        await _load();
      },
      child: _centerOnDesktop(ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (kIsWeb) _webPushBanner(),
          if (_items.isEmpty)
            _empty()
          else
            for (int i = 0; i < _items.length; i++)
              FadeSlideIn(
                delay: Duration(milliseconds: 45 * (i % 6)),
                child: _tile(_items[i]),
              ),
          if (_loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColor.goldEnd),
                ),
              ),
            ),
        ],
      )),
    );
  }

  /// وب: روشن کردنِ اعلان‌های مرورگر با کلیکِ کاربر (مرورگر درخواستِ
  /// بی‌مقدمه را رد می‌کند). اگر قبلاً رد شده، فقط راهنمایی.
  Widget _webPushBanner() => ValueListenableBuilder<AuthorizationStatus?>(
        valueListenable: PushNotificationService.webPermission,
        builder: (context, status, _) => ValueListenableBuilder<String?>(
        valueListenable: PushNotificationService.webPushError,
        builder: (context, error, _) {
          final active = status == AuthorizationStatus.authorized &&
              PushNotificationService.token != null &&
              error == null;
          if (active || (status == null && error == null)) {
            return const SizedBox.shrink();
          }
          final denied = status == AuthorizationStatus.denied;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: ShapeDecoration(
              color: AppColor.pitchGreenSoft,
              shape: AppShapes.border(AppShapes.rMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_outlined,
                    color: AppColor.pitchGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    denied
                        ? 'اعلان‌های این سایت در مرورگر مسدود است. از تنظیماتِ سایت در نوار آدرس آن را مجاز کنید.'
                        : error != null
                            // TODO(release): فعلاً متنِ کاملِ خطا برای دیباگ
                            ? 'اعلان‌ها روشن نشد:\n$error'
                            : 'با روشن کردنِ اعلان‌ها، خبرِ سفارش و پیام‌های تازه را حتی وقتی سایت بسته است دریافت می‌کنید.',
                    style: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 12,
                        height: 1.6,
                        color: AppColor.onSurface),
                  ),
                ),
                if (!denied) ...[
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      final err = await PushNotificationService.enableWebPush();
                      if (!mounted) return;
                      if (err == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('اعلان‌های مرورگر روشن شد',
                              style: TextStyle(fontFamily: 'Estedad')),
                        ));
                        return;
                      }
                      // TODO(release): فعلاً متنِ کاملِ خطا برای دیباگ.
                      await showDialog<void>(
                        context: context,
                        builder: (_) => Directionality(
                          textDirection: TextDirection.rtl,
                          child: AlertDialog(
                            title: const Text('اعلان‌ها روشن نشد',
                                style: TextStyle(fontFamily: 'Estedad')),
                            content: SelectableText(err,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(fontSize: 12)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('باشه',
                                    style: TextStyle(fontFamily: 'Estedad')),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColor.pitchGreen),
                    child: Text(error != null ? 'تلاش دوباره' : 'روشن کردن',
                        style: const TextStyle(fontFamily: 'Estedad')),
                  ),
                ],
              ],
            ),
          );
        },
        ),
      );

  /// دسکتاپ: لیست اعلان‌ها وسط‌چین با حداکثر عرض ۸۰۰؛ موبایل بی‌اثر.
  Widget _centerOnDesktop(Widget child) {
    if (!AppBreakpoints.isDesktop(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: child,
      ),
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String subtitle,
    required String action,
    required VoidCallback onAction,
  }) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColor.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColor.onSurface)),
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 12,
                      color: AppColor.onSurfaceVariant)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                    backgroundColor: AppColor.goldEnd),
                child: Text(action,
                    style: const TextStyle(fontFamily: 'Estedad')),
              ),
            ],
          ),
        ),
      );

  Widget _empty() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.notifications_none,
                size: 48, color: AppColor.onSurfaceVariant),
            SizedBox(height: 12),
            Text('اعلانی ندارید',
                style: TextStyle(
                    fontFamily: 'Estedad', color: AppColor.onSurface)),
          ],
        ),
      );

  /// متنِ زیرِ تیتر: باقیِ پیام بعد از خطِ اول، یا کلِ متن وقتی تیتر بریده شده.
  static String? _preview(UserMessage m) {
    if (!m.hasMoreThanTitle) return null;
    final lines = m.text.split('\n');
    final rest = lines.skip(1).join('\n').trim();
    return rest.isNotEmpty ? rest : m.text;
  }

  Widget _tile(UserMessage m) {
    final isRead = m.isRead;
    final preview = _preview(m);
    const color = AppColor.goldEnd;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: ShapeDecoration(
        color: AppColor.card,
        shape: AppShapes.border(AppShapes.rLg),
        shadows: AppColor.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _open(m),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: color.withOpacity(0.12)),
                  child: const Icon(Icons.notifications_none_rounded,
                      size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              m.displayTitle,
                              style: TextStyle(
                                fontFamily: 'Estedad',
                                fontSize: 13,
                                fontWeight:
                                    isRead ? FontWeight.w600 : FontWeight.w800,
                                color: AppColor.onSurface,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              key: const ValueKey('unread-dot'),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColor.goldEnd,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      if (preview != null) ...[
                        const SizedBox(height: 4),
                        Text(preview,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: 'Estedad',
                                fontSize: 12,
                                height: 1.6,
                                color: AppColor.onSurfaceVariant)),
                      ],
                      const SizedBox(height: 6),
                      Text(formatOrderDate(m.createdAt),
                          style: const TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 10,
                              color: AppColor.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
