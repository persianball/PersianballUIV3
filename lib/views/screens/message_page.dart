// lib/views/screens/message_page.dart
//
// صندوق پیام‌های کاربر از /v1/user/message/.
//
// نسخه‌ی قبلی داده‌ی ساختگیِ MessageService (لوگوی فروشگاه، چت دوطرفه) را
// نشان می‌داد. سرور فقط یک لیستِ خواندنیِ پیام دارد، پس این صفحه همان را
// نشان می‌دهد: عنوان، متن، تاریخ و نشانِ خوانده‌نشده.
import 'package:flutter/material.dart';

import 'package:marketky/constant/app_breakpoints.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/services/user_message_service.dart';
import 'package:marketky/views/screens/message_detail_page.dart';
import 'package:marketky/views/widgets/message_tile_widget.dart';
import 'package:marketky/views/widgets/motion.dart';
import 'package:marketky/views/widgets/shimmer.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final List<UserMessage> _messages = [];
  String? _nextUrl;

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetch();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    // بجِ نوار بالای خانه بعد از دیدن صندوق باید با واقعیت یکی شود.
    UserMessageService.refreshUnread();
    super.dispose();
  }

  Future<void> _fetch({bool loadMore = false}) async {
    if (!mounted) return;
    setState(() {
      if (loadMore) {
        _loadingMore = true;
      } else {
        _loading = _messages.isEmpty;
        _error = null;
      }
    });
    try {
      final res =
          await UserMessageService.fetch(nextUrl: loadMore ? _nextUrl : null);
      if (!mounted) return;
      setState(() {
        if (!loadMore) _messages.clear();
        _messages.addAll(res.results);
        _nextUrl = res.next;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
      _syncUnreadBadge();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        // خطای صفحه‌ی بعد نباید چیزی را که نشان داده‌ایم پاک کند.
        if (_messages.isEmpty) {
          _error = e.toString().replaceFirst('Exception: ', '');
        }
      });
    }
  }

  void _onScroll() {
    if (_nextUrl == null || _loadingMore || _loading) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
      _fetch(loadMore: true);
    }
  }

  int get _unread => _messages.where((m) => !m.isRead).length;

  /// باز کردنِ پیام و ثبتِ «خوانده شد».
  ///
  /// ردیف بلافاصله بی‌نشان می‌شود و PATCH در پس‌زمینه می‌رود؛ اگر سرور
  /// نپذیرفت همان ردیف دوباره خوانده‌نشده می‌شود، تا کاربر بجی نبیند که
  /// با واقعیتِ سرور نمی‌خواند.
  Future<void> _open(int index) async {
    final message = _messages[index];
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MessageDetailPage(data: message)),
    );

    final id = message.id;
    if (message.isRead || id == null) return;

    setState(() => _messages[index] = message.copyWithSeen(DateTime.now()));
    _syncUnreadBadge();

    final ok = await UserMessageService.markSeen(id);
    if (!mounted || ok) return;
    final at = _messages.indexWhere((m) => m.id == id);
    if (at != -1) {
      setState(() => _messages[at] = message);
      _syncUnreadBadge();
    }
  }

  void _syncUnreadBadge() =>
      UserMessageService.unreadNotifier.value = _unread;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.obsidianBg,
      appBar: AppBar(
        backgroundColor: AppColor.obsidianBg,
        foregroundColor: AppColor.onSurface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('پیام‌ها',
                style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColor.onSurface)),
            if (!_loading && _error == null && _messages.isNotEmpty)
              Text(
                  _unread == 0
                      ? 'همه خوانده شده‌اند'
                      : '$_unread پیام خوانده‌نشده',
                  style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColor.onSurfaceVariant)),
          ],
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _body(),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return KeyedSubtree(
        key: const ValueKey('skeleton'),
        child: _centerOnDesktop(const _MessagesSkeleton()),
      );
    }
    if (_error != null) {
      return KeyedSubtree(
        key: const ValueKey('error'),
        child: _ErrorView(message: _error!, onRetry: () => _fetch()),
      );
    }
    if (_messages.isEmpty) {
      return KeyedSubtree(
        key: const ValueKey('empty'),
        child: _EmptyView(onRetry: () => _fetch()),
      );
    }
    return KeyedSubtree(
      key: const ValueKey('list'),
      child: RefreshIndicator(
        color: AppColor.pitchGreen,
        onRefresh: () async {
          _nextUrl = null;
          await _fetch();
        },
        child: _centerOnDesktop(
          ListView.builder(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
            itemCount: _messages.length + (_loadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length) return _loadMoreFooter();
              return FadeSlideIn(
                delay: Duration(milliseconds: 45 * (index % 6)),
                child: MessageTileWidget(
                  data: _messages[index],
                  onTap: () => _open(index),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _loadMoreFooter() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColor.pitchGreen),
          ),
        ),
      );

  /// دسکتاپ: لیست وسط‌چین با حداکثر عرض ۹۰۰؛ موبایل بی‌اثر.
  Widget _centerOnDesktop(Widget child) {
    if (!AppBreakpoints.isDesktop(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: child,
      ),
    );
  }
}

// ---------- حالت‌های خالی/خطا/بارگذاری ----------

class _MessagesSkeleton extends StatelessWidget {
  const _MessagesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          for (int i = 0; i < 6; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: ShapeDecoration(
                  color: AppColor.surfaceContainer,
                  shape: AppShapes.border(AppShapes.rLg),
                  shadows: AppColor.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(children: [
                      Bone(width: 38, height: 38, radius: 999),
                      SizedBox(width: 10),
                      Expanded(child: Bone(height: 14)),
                      SizedBox(width: 10),
                      Bone(width: 60, height: 12),
                    ]),
                    SizedBox(height: 12),
                    Bone(height: 12),
                    SizedBox(height: 8),
                    Bone(width: 180, height: 12),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_read_outlined,
                size: 52, color: AppColor.lineStrong),
            const SizedBox(height: 14),
            const Text('پیامی ندارید',
                style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColor.onSurface)),
            const SizedBox(height: 8),
            const Text('اطلاعیه‌ها و پیام‌های پشتیبانی اینجا نمایش داده می‌شوند.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 12,
                    color: AppColor.onSurfaceVariant)),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColor.pitchGreen,
                side: const BorderSide(color: AppColor.pitchGreen),
                shape: AppShapes.pill,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              label: const Text('بارگذاری مجدد',
                  style: TextStyle(
                      fontFamily: 'Estedad', fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final bool needsLogin = message.contains('ورود');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                needsLogin
                    ? Icons.lock_outline_rounded
                    : Icons.wifi_off_rounded,
                size: 44,
                color: AppColor.lineStrong),
            const SizedBox(height: 14),
            Text(
                needsLogin
                    ? 'برای دیدن پیام‌ها وارد حساب کاربری شوید'
                    : message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 14,
                    color: AppColor.onSurfaceVariant)),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.pitchGreen,
                  foregroundColor: Colors.white,
                  shape: AppShapes.pill,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12)),
              child: const Text('تلاش مجدد',
                  style: TextStyle(
                      fontFamily: 'Estedad', fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
