// ═══════════════════════════════════════════════════════════════
// SECURITY NAVIGATION WRAPPER
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:nch_mobile/v2/app/routes/app_routes.dart';
import 'package:nch_mobile/v2/core/widgets/common/base_navigation_wrapper.dart';

import '../../../app/modules/security/dashboard/views/security_dashboard_view.dart';
import '../../../app/modules/security/scan/views/scan_view.dart';
import '../../../app/modules/security/visitor/views/visitor_view.dart';
import '../../../app/modules/security/profile/views/security_profile_view.dart';

class SecurityNavigationWrapper extends BaseNavigationWrapper {
  const SecurityNavigationWrapper({Key? key}) : super(key: key);

  @override
  State<SecurityNavigationWrapper> createState() =>
      _SecurityNavigationWrapperState();
}

class _SecurityNavigationWrapperState
    extends BaseNavigationWrapperState<SecurityNavigationWrapper> {
  @override
  List<NavTab> get navTabs => [
    NavTab(
      route: Routes.SECURITY_DASHBOARD,
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      page: const SecurityDashboardView(),
    ),
    NavTab(
      route: Routes.SECURITY_SCAN,
      icon: Icons.qr_code_scanner_outlined,
      activeIcon: Icons.qr_code_scanner,
      label: 'Scan',
      page: const SecurityScanView(),
    ),
    NavTab(
      route: Routes.SECURITY_VISITORS,
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Pengunjung',
      page: const TodayVisitorsView(),
    ),
    NavTab(
      route: Routes.SECURITY_PROFILE,
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profil',
      page: const SecurityProfileView(),
    ),
  ];

  @override
  String get dashboardRoute => Routes.SECURITY_DASHBOARD;
}
