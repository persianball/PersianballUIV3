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
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    // ترتیب آیتم‌ها با ترتیب طرح یکی است: اولین آیتم لیست در RTL راست‌ترین
    // است، پس «خانه» راست و «پروفایل» چپ می‌نشیند - دقیقاً مطابق طرح.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.obsidianBg,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            HomePage(),
            const CoursesPage(),
            const CatalogPage(),
            ProfilePage(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.obsidianBg,
              border: Border(
                top: BorderSide(color: AppColor.outlineVariantDark, width: 1),
              ),
            ),
            child: BottomNavigationBar(
              onTap: _onItemTapped,
              currentIndex: _selectedIndex,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              backgroundColor: AppColor.obsidianBg,
              elevation: 0,
              selectedItemColor: AppColor.goldEnd,
              unselectedItemColor: AppColor.outlineDark,
              selectedLabelStyle: const TextStyle(
                fontFamily: 'Estedad',
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Estedad',
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
              items: [
                for (int i = 0; i < _tabs.length; i++)
                  BottomNavigationBarItem(
                    icon: Icon(
                        i == _selectedIndex
                            ? _tabs[i].activeIcon
                            : _tabs[i].icon),
                    label: _tabs[i].label,
                  ),
              ],
            ),
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

  const _NavTab({required this.icon, required this.activeIcon, required this.label});
}
