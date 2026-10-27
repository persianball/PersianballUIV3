import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:persian_ball/views/widgets/app_logo.dart';
import 'package:persian_ball/constant/app_color.dart';
import 'package:persian_ball/views/widgets/motion.dart';
import 'package:persian_ball/views/screens/home_page.dart';
import 'package:persian_ball/views/screens/profile_page.dart';
import 'package:persian_ball/views/screens/courses_page.dart';
import 'package:persian_ball/views/screens/catalog_page.dart';
import 'package:persian_ball/constant/app_breakpoints.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persian_ball/bloc/cart/cart_bloc.dart';
import 'package:persian_ball/views/widgets/auth_background.dart';
import 'package:persian_ball/services/user_message_service.dart';

class PageSwitcher extends StatefulWidget {
  @override
  _PageSwitcherState createState() => _PageSwitcherState();
}

class _PageSwitcherState extends State<PageSwitcher> {
  /// ایندکس صفحه (منطقی): ۰ = خانه ... ۳ = پروفایل
  int _selectedIndex = 0;

  /// کنترلر نوار پایین با ایندکس *نمایشی* کار می‌کند، نه ایندکس صفحه.
  late final NotchBottomBarController _barController =
      NotchBottomBarController(index: _barIndex(_selectedIndex));

  static const List<_NavTab> _tabs = [
    _NavTab(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'خانه'),
    _NavTab(
        icon: Icons.sports_soccer_outlined,
        activeIcon: Icons.sports_soccer,
        label: 'دوره‌ها'),
    _NavTab(
        icon: Icons.shopping_bag_outlined,
        activeIcon: Icons.shopping_bag,
        label: 'فروشگاه'),
    _NavTab(
        icon: Icons.person_outline, activeIcon: Icons.person, label: 'پروفایل'),
  ];

  /// AnimatedNotchBottomBar آیتم‌ها را با `Positioned(left:)` می‌چیند، یعنی
  /// همیشه چپ‌به‌راست است و `Directionality` روی آن اثری ندارد. برای اینکه
  /// «خانه» سمت راست بنشیند، ترتیب نمایشی را وارونه می‌کنیم و بین ایندکس
  /// نمایشی و ایندکس صفحه نگاشت می‌زنیم.
  static int _barIndex(int pageIndex) => _tabs.length - 1 - pageIndex;
  static int _pageIndex(int barIndex) => _tabs.length - 1 - barIndex;

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  void _onBarTapped(int barIndex) => _selectPage(_pageIndex(barIndex));

  void _selectPage(int pageIndex) {
    if (pageIndex == _selectedIndex) return;
    setState(() => _selectedIndex = pageIndex);
    // نوار پایین موبایل هم باید هم‌گام بماند تا با تغییر اندازه‌ی پنجره
    // (دسکتاپ → موبایل) تب فعال درست نمایش داده شود.
    _barController.index = _barIndex(pageIndex);
  }

  @override
  Widget build(BuildContext context) {
    final bool desktop = AppBreakpoints.isDesktop(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      // پس‌زمینه‌ی تصویری پشت کلِ پوسته می‌نشیند، پس اسکافولد شفاف است
      child: AppBackground(
        backdrop: AppBackdrop.main,
        child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: !desktop,
        // دسکتاپ: نوار ناوبری بالایی مثل سایت‌های فروشگاهی؛
        // موبایل/تبلت: همان نوار پایین ناچ‌دار.
        appBar: desktop
            ? _DesktopNavBar(
                tabs: _tabs,
                selectedIndex: _selectedIndex,
                onSelect: _selectPage,
              )
            : null,
        body: FadeIndexedStack(
          index: _selectedIndex,
          children: [
            HomePage(),
            const CoursesPage(),
            const CatalogPage(),
            ProfilePage(),
          ],
        ),
        bottomNavigationBar: desktop
            ? null
            : AnimatedNotchBottomBar(
          notchBottomBarController: _barController,
          onTap: _onBarTapped,
          color: AppColor.card,
          notchColor: AppColor.pitchGreen,
          notchGradient: AppColor.greenGradient,
          showLabel: true,
          textDirection: TextDirection.rtl,
          itemLabelStyle: const TextStyle(
            fontFamily: 'Estedad',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColor.inkMuted,
          ),
          kIconSize: 22.0,
          kBottomRadius: 28.0,
          bottomBarHeight: 62.0,
          showShadow: true,
          shadowElevation: 12,
          elevation: 6,
          durationInMilliSeconds: 300,
          bottomBarItems: [
            for (final tab in _tabs.reversed)
              BottomBarItem(
                inActiveItem: Icon(tab.icon, color: AppColor.lineStrong),
                activeItem: Icon(tab.activeIcon, color: AppColor.onPitchGreen),
                itemLabel: tab.label,
              ),
          ],
        ),
      ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavTab(
      {required this.icon, required this.activeIcon, required this.label});
}

/// نوار ناوبری بالایی دسکتاپ: لوگو، لینک تب‌ها با نشانگر فعال، جست‌وجو،
/// سبد (با نشان تعداد) — الگوی استاندارد فروشگاه‌های دسکتاپ.
class _DesktopNavBar extends StatelessWidget implements PreferredSizeWidget {
  const _DesktopNavBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_NavTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  /// پروفایل آخرین تب است و به‌جای لینک، آیکن کنارِ سبد می‌شود.
  int get profileIndex => tabs.length - 1;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColor.card,
        border: Border(bottom: BorderSide(color: AppColor.line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: CenteredContent(
          child: Row(
            children: [
              // لوگو / نام فروشگاه
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onSelect(0),
                  child: Row(
                    children: [
                      // لوگو مستقیم روی نوارِ سفید؛ دایره‌ی سبزِ قبلی
                      // حذف شد چون نوارِ سبزِ لوگو روی آن محو می‌شد.
                      const AppLogo(size: 40),
                      const SizedBox(width: 10),
                      const Text(
                        'پرشین بال',
                        style: TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColor.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 36),

              // لینک‌های اصلی — پروفایل اینجا نمی‌آید و به‌شکل آیکن
              // کنارِ سبد در سمت دیگر نوار می‌نشیند (الگوی فروشگاه‌های وب).
              for (int i = 0; i < tabs.length; i++)
                if (i != profileIndex) ...[
                  _NavLink(
                    label: tabs[i].label,
                    icon: tabs[i].icon,
                    active: i == selectedIndex,
                    onTap: () => onSelect(i),
                  ),
                  const SizedBox(width: 6),
                ],
              const Spacer(),

              // جست‌وجو (فیلد جست‌وجو داخل تب فروشگاه است)
              _NavIconButton(
                icon: Icons.search_rounded,
                tooltip: 'جست‌وجو در فروشگاه',
                onTap: () => onSelect(2),
              ),
              const SizedBox(width: 8),

              // اعلان‌ها با نشانِ پیام‌های خوانده‌نشده. پیش‌تر زنگوله فقط در
              // هدرِ هومِ موبایل بود و در دسکتاپ راهی به اعلان‌ها نبود.
              ValueListenableBuilder<int>(
                valueListenable: UserMessageService.unreadNotifier,
                builder: (context, unread, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _NavIconButton(
                      icon: Icons.notifications_none_rounded,
                      tooltip: 'اعلان‌ها',
                      onTap: () async {
                        await Navigator.of(context).pushNamed('/notifications');
                        UserMessageService.refreshUnread();
                      },
                    ),
                    if (unread > 0)
                      Positioned(
                        top: -4,
                        left: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: const ShapeDecoration(
                            color: AppColor.danger,
                            shape: StadiumBorder(),
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // سبد خرید با نشان تعداد
              BlocBuilder<CartBloc, CartState>(
                builder: (context, state) {
                  final int count = state is CartLoaded &&
                          state.cart.results.isNotEmpty
                      ? state.cart.results[0].items.length
                      : 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _NavIconButton(
                        icon: Icons.shopping_bag_outlined,
                        tooltip: 'سبد خرید',
                        onTap: () => Navigator.of(context).pushNamed('/cart'),
                      ),
                      if (count > 0)
                        Positioned(
                          top: -4,
                          left: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: const ShapeDecoration(
                              color: AppColor.danger,
                              shape: StadiumBorder(),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                fontFamily: 'Estedad',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),

              // پروفایل
              _NavIconButton(
                icon: selectedIndex == profileIndex
                    ? Icons.person
                    : Icons.person_outline,
                tooltip: tabs[profileIndex].label,
                active: selectedIndex == profileIndex,
                onTap: () => onSelect(profileIndex),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final Color fg = widget.active
        ? AppColor.pitchGreen
        : (_hover ? AppColor.ink : AppColor.inkMuted);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: ShapeDecoration(
            color: widget.active
                ? AppColor.pitchGreenSoft
                : (_hover ? AppColor.cardMuted : Colors.transparent),
            shape: const StadiumBorder(),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 17, color: fg),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 13.5,
                  fontWeight:
                      widget.active ? FontWeight.w800 : FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIconButton extends StatefulWidget {
  const _NavIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool active;

  @override
  State<_NavIconButton> createState() => _NavIconButtonState();
}

class _NavIconButtonState extends State<_NavIconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final button = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 42,
          height: 42,
          decoration: ShapeDecoration(
            color: widget.active
                ? AppColor.pitchGreenSoft
                : (_hover ? AppColor.cardMuted : Colors.transparent),
            shape: const CircleBorder(),
          ),
          child: Icon(
            widget.icon,
            size: 21,
            color: widget.active ? AppColor.pitchGreen : AppColor.ink,
          ),
        ),
      ),
    );
    return widget.tooltip == null
        ? button
        : Tooltip(message: widget.tooltip!, child: button);
  }
}
