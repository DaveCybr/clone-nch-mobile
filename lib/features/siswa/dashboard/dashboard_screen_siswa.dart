import 'package:flutter/material.dart';
import 'package:nch_mobile/features/login/controllers/auth_controller.dart';
import 'package:nch_mobile/features/login/models/auth_model.dart';
import 'package:nch_mobile/features/siswa/dashboard/widgets/dashboard_header.dart';
import 'package:nch_mobile/features/siswa/dashboard/widgets/announcement_banner.dart';
import 'package:nch_mobile/features/siswa/dashboard/widgets/menu_grid.dart';
import 'package:nch_mobile/features/siswa/dashboard/widgets/artikel_section.dart';

class DashboardScreenSiswa extends StatefulWidget {
  const DashboardScreenSiswa({super.key});

  @override
  State<DashboardScreenSiswa> createState() => _DashboardScreenSiswaState();
}

class _DashboardScreenSiswaState extends State<DashboardScreenSiswa> {
  late PageController _bannerPageController;
  int _currentBannerIndex = 0;
  UserModel? _currentUser;
  final AuthController _authController = AuthController();

  final List<String> _bannerImages = [
    'assets/banner1.png',
    'assets/banner2.png',
    'assets/banner3.png',
  ];

  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController();
    _startBannerAutoScroll();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await _authController.fetchUserProfile();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  void _startBannerAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _bannerPageController.hasClients) {
        int nextPage = (_currentBannerIndex + 1) % _bannerImages.length;
        _bannerPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentBannerIndex = nextPage;
        });
        _startBannerAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _bannerPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header dengan banner
            DashboardHeaderSiswa(
              currentUser: _currentUser,
              pageController: _bannerPageController,
              bannerImages: _bannerImages,
              currentBannerIndex: _currentBannerIndex,
            ),

            const SizedBox(height: 20),

            // Announcement Banner
            const AnnouncementBannerSiswa(),

            const SizedBox(height: 20),

            // Menu Grid
            const MenuGridSiswa(),

            const SizedBox(height: 20),

            // Artikel Section
            const ArtikelSectionSiswa(),

            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle quick action for students
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fitur cepat untuk siswa'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        backgroundColor: const Color(0xFF0F7836),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
