import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/views/screens/home_page.dart';
import 'package:marketky/views/screens/profile_page.dart';
import 'package:marketky/views/screens/courses_page.dart';
import 'package:marketky/views/screens/catalog_page.dart';

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

  void _onBarTapped(int barIndex) {
    final pageIndex = _pageIndex(barIndex);
    if (pageIndex == _selectedIndex) return;
    setState(() {
      _selectedIndex = pageIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.milk,
        extendBody: true,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            HomePage(),
            const CoursesPage(),
            const CatalogPage(),
            ProfilePage(),
          ],
        ),
        bottomNavigationBar: AnimatedNotchBottomBar(
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
