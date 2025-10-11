// lib/v2/core/widgets/common/parent_navigation_wrapper.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';

class ParentNavigationWrapper extends StatefulWidget {
  const ParentNavigationWrapper({Key? key}) : super(key: key);

  @override
  State<ParentNavigationWrapper> createState() =>
      _ParentNavigationWrapperState();
}

class _ParentNavigationWrapperState extends State<ParentNavigationWrapper> {
  final RxInt _currentIndex = 0.obs;

  final List<String> _tabs = [
    Routes.PARENT_DASHBOARD,
    Routes.PARENT_CHILD_PROGRESS,
    Routes.PARENT_ANNOUNCEMENTS,
    Routes.PARENT_PROFILE,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetRouterOutlet(
        initialRoute: Routes.PARENT_DASHBOARD,
        anchorRoute: Routes.MAIN,
      ),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: _currentIndex.value,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            _currentIndex.value = index;
            Get.rootDelegate.toNamed(_tabs[index]);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.child_care_outlined),
              activeIcon: Icon(Icons.child_care),
              label: "Anak",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined),
              activeIcon: Icon(Icons.campaign),
              label: "Pengumuman",
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
