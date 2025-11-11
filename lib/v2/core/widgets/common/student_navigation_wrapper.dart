// lib/v2/core/widgets/common/student_navigation_wrapper.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../theme/app_colors.dart';

class StudentNavigationWrapper extends StatefulWidget {
  const StudentNavigationWrapper({Key? key}) : super(key: key);

  @override
  State<StudentNavigationWrapper> createState() =>
      _StudentNavigationWrapperState();
}

class _StudentNavigationWrapperState extends State<StudentNavigationWrapper> {
  int _currentIndex = 0;

  final List<String> _tabs = [
    Routes.getStudentRoute(Routes.STUDENT_DASHBOARD),
    Routes.getStudentRoute(Routes.STUDENT_SCHEDULE),
    Routes.getStudentRoute(Routes.STUDENT_ATTENDANCE),
    Routes.getStudentRoute(Routes.STUDENT_PROFILE),
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
        initialRoute: Routes.getStudentRoute(Routes.STUDENT_DASHBOARD),
        anchorRoute: Routes.STUDENT,
        key: Get.nestedKey(1),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          Get.rootDelegate.toNamed(_tabs[index], arguments: {});
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_outlined),
            activeIcon: Icon(Icons.schedule),
            label: "Jadwal",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: "Absensi",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profil",
          ),
        ],
      ),
    );
  }
}
