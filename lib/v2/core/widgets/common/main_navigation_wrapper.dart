import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../theme/app_colors.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({Key? key}) : super(key: key);

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  final RxInt _currentIndex = 0.obs;

  // Daftar route anak sesuai AppPages
  final List<String> _tabs = [
    Routes.getTeacherRoute(Routes.TEACHER_DASHBOARD),
    Routes.getTeacherRoute(Routes.TEACHER_SCHEDULE),
    Routes.getTeacherRoute(Routes.TEACHER_STUDENTS),
    Routes.getTeacherRoute(Routes.TEACHER_PROFILE),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetRouterOutlet(
        initialRoute: Routes.getTeacherRoute(Routes.TEACHER_DASHBOARD),
        anchorRoute: Routes.MAIN,
        key: Get.nestedKey(1),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: _currentIndex.value,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            _currentIndex.value = index;
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
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: "Siswa",
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
