// ═══════════════════════════════════════════════════════════════
// TEACHER NAVIGATION WRAPPER
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:nch_mobile/v2/core/widgets/common/base_navigation_wrapper.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/modules/teacher/dashboard/views/teacher_dashboard_view.dart';
import '../../../app/modules/teacher/schedule/views/schedule_view.dart';
import '../../../app/modules/teacher/student/views/student_data_view.dart';
import '../../../app/modules/teacher/profile/views/profile_view.dart';

class TeacherNavigationWrapper extends BaseNavigationWrapper {
  const TeacherNavigationWrapper({Key? key}) : super(key: key);

  @override
  State<TeacherNavigationWrapper> createState() =>
      _TeacherNavigationWrapperState();
}

class _TeacherNavigationWrapperState
    extends BaseNavigationWrapperState<TeacherNavigationWrapper> {
  @override
  List<NavTab> get navTabs => [
    NavTab(
      route: Routes.TEACHER_DASHBOARD,
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      page: const TeacherDashboardView(),
    ),
    NavTab(
      route: Routes.TEACHER_SCHEDULE,
      icon: Icons.schedule_outlined,
      activeIcon: Icons.schedule,
      label: 'Jadwal',
      page: const ScheduleView(),
    ),
    NavTab(
      route: Routes.TEACHER_STUDENTS,
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Siswa',
      page: const StudentDataView(),
    ),
    NavTab(
      route: Routes.TEACHER_PROFILE,
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profil',
      page: const ProfileView(),
    ),
  ];

  @override
  String get dashboardRoute => Routes.TEACHER_DASHBOARD;
}
