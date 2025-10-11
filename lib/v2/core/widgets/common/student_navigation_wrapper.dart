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
  final RxInt _currentIndex = 0.obs;

  final List<String> _tabs = [
    Routes.STUDENT_DASHBOARD,
    Routes.STUDENT_SCHEDULE,
    Routes.STUDENT_ATTENDANCE,
    Routes.STUDENT_PROFILE,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetRouterOutlet(
        initialRoute: Routes.STUDENT_DASHBOARD,
        anchorRoute: Routes.STUDENT,
      ),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: _currentIndex.value,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            _currentIndex.value = index;
            debugPrint("Navigate to: ${_tabs[index]}");
            Get.rootDelegate.toNamed(_tabs[index]);
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
      ),
    );
  }
}
