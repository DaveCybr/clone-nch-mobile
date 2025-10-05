import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({Key? key}) : super(key: key);

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  final RxInt _currentIndex = 0.obs;

  // Daftar route anak sesuai AppPages
  final List<String> _tabs = [
    Routes.TEACHER_DASHBOARD,
    Routes.TEACHER_SCHEDULE,
    Routes.TEACHER_STUDENTS,
    Routes.TEACHER_PROFILE,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetRouterOutlet(
        initialRoute: Routes.TEACHER_DASHBOARD,
        anchorRoute: Routes.MAIN,
      ),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: _currentIndex.value, // wajib pakai .value
          type: BottomNavigationBarType.fixed,
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
