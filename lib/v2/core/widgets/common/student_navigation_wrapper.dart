// lib/v2/core/widgets/student/student_navigation_wrapper.dart

import 'package:flutter/material.dart';
import 'package:nch_mobile/v2/core/widgets/common/base_navigation_wrapper.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/modules/student/dashboard/views/student_dashboard_view.dart';
import '../../../app/modules/student/schedule/views/student_schedule_view.dart';
import '../../../app/modules/student/attendance/views/student_attendance_view.dart';
import '../../../app/modules/student/announcements/views/student_announcements_view.dart';
import '../../../app/modules/student/visit_schedule/views/visit_schedule_view.dart';
import '../../../app/modules/student/profile/views/profile_view.dart';

class StudentNavigationWrapper extends BaseNavigationWrapper {
  const StudentNavigationWrapper({Key? key}) : super(key: key);

  @override
  State<StudentNavigationWrapper> createState() =>
      _StudentNavigationWrapperState();
}

class _StudentNavigationWrapperState
    extends BaseNavigationWrapperState<StudentNavigationWrapper> {
  @override
  List<NavTab> get navTabs => [
    NavTab(
      route: Routes.STUDENT_DASHBOARD,
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      page: const StudentDashboardView(),
    ),
    NavTab(
      route: Routes.STUDENT_SCHEDULE,
      icon: Icons.schedule_outlined,
      activeIcon: Icons.schedule,
      label: 'Jadwal',
      page: const StudentScheduleView(),
    ),
    NavTab(
      route: Routes.STUDENT_ATTENDANCE,
      icon: Icons.fact_check_outlined,
      activeIcon: Icons.fact_check,
      label: 'Presensi',
      page: const StudentAttendanceView(),
    ),
    NavTab(
      route: Routes.STUDENT_ANNOUNCEMENTS,
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications,
      label: 'Pengumuman',
      page: const StudentAnnouncementsView(),
    ),
    NavTab(
      route: Routes.STUDENT_VISIT,
      icon: Icons.qr_code_outlined,
      activeIcon: Icons.qr_code,
      label: 'Kunjungan',
      page: const VisitScheduleView(),
    ),
    NavTab(
      route: Routes.STUDENT_PROFILE,
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profil',
      page: const StudentProfileView(),
    ),
  ];

  @override
  String get dashboardRoute => Routes.STUDENT_DASHBOARD;
}
