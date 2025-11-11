// lib/v2/core/widgets/common/base_navigation_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nch_mobile/v2/app/data/services/navigations_services.dart';
import '../../theme/app_colors.dart';

/// Base wrapper untuk semua role navigation
/// Handles bottom nav state management dan back button behavior
abstract class BaseNavigationWrapper extends StatefulWidget {
  const BaseNavigationWrapper({Key? key}) : super(key: key);
}

abstract class BaseNavigationWrapperState<T extends BaseNavigationWrapper>
    extends State<T>
    with WidgetsBindingObserver {
  int currentIndex = 0;

  /// Override ini di child class
  List<NavTab> get navTabs;
  String get dashboardRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncNavBar());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncNavBar();
    }
  }

  void _syncNavBar() {
    if (!mounted) return;
    final route = NavigationService.to.currentRoute;
    if (route == null) return;

    int newIndex = navTabs.indexWhere((tab) => tab.route == route);
    if (newIndex != -1 && currentIndex != newIndex) {
      if (mounted) setState(() => currentIndex = newIndex);
    }
  }

  Future<void> _onNavTap(int index) async {
    if (currentIndex == index) return;
    setState(() => currentIndex = index);
    await NavigationService.to.toBottomNavTab(navTabs[index].route);
  }

  Future<bool> _onWillPop() async {
    if (currentIndex == 0) {
      return await _showExitDialog() ?? false;
    }
    setState(() => currentIndex = 0);
    await NavigationService.to.toBottomNavTab(dashboardRoute);
    return false;
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text('Keluar Aplikasi', style: TextStyle(fontSize: 18.sp)),
            content: Text(
              'Apakah Anda yakin ingin keluar?',
              style: TextStyle(fontSize: 14.sp),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Keluar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: navTabs.map((tab) => tab.page).toList(),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primaryGreen,
            unselectedItemColor: AppColors.textHint,
            selectedFontSize: 12.sp,
            unselectedFontSize: 11.sp,
            onTap: _onNavTap,
            items:
                navTabs
                    .map(
                      (tab) => BottomNavigationBarItem(
                        icon: Icon(tab.icon),
                        activeIcon: Icon(tab.activeIcon),
                        label: tab.label,
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }
}

class NavTab {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget page;

  NavTab({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.page,
  });
}
