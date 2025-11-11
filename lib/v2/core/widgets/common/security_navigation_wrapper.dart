// lib/v2/core/widgets/common/security_navigation_wrapper.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../theme/app_colors.dart';

class SecurityNavigationWrapper extends StatefulWidget {
  const SecurityNavigationWrapper({Key? key}) : super(key: key);

  @override
  State<SecurityNavigationWrapper> createState() =>
      _SecurityNavigationWrapperState();
}

class _SecurityNavigationWrapperState extends State<SecurityNavigationWrapper> {
  int _currentIndex = 0;

  final List<String> _tabs = [
    Routes.getSecurityRoute(Routes.SECURITY_DASHBOARD),
    Routes.getSecurityRoute(Routes.SECURITY_SCAN),
    Routes.getSecurityRoute(Routes.SECURITY_TODAY_VISITORS),
    Routes.getSecurityRoute(Routes.SECURITY_PROFILE),
  ];

  @override
  void initState() {
    super.initState();

    // Update navbar setiap kali ada perubahan route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.rootDelegate.addListener(_updateNavBar);
    });
  }

  @override
  void dispose() {
    Get.rootDelegate.removeListener(_updateNavBar);
    super.dispose();
  }

  void _updateNavBar() {
    final currentRoute = Get.rootDelegate.currentConfiguration?.location ?? '';

    for (int i = 0; i < _tabs.length; i++) {
      if (currentRoute.contains(_tabs[i])) {
        if (_currentIndex != i) {
          setState(() {
            _currentIndex = i;
          });
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetRouterOutlet(
        initialRoute: Routes.getSecurityRoute(Routes.SECURITY_DASHBOARD),
        anchorRoute: Routes.SECURITY,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          Get.rootDelegate.toNamed(_tabs[index]);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_outlined),
            activeIcon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Pengunjung',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
