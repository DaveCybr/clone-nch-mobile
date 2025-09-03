import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:nch_mobile/features/login/models/auth_model.dart';
import 'package:nch_mobile/features/login/controllers/auth_controller.dart';
import '../../../../partials/custom_bottom_navigation.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/announcement_banner.dart';
import '../widgets/menu_grid.dart';
import '../widgets/artikel_section.dart';

class _BottomRoundedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2, 
      size.height, 
      size.width, 
      size.height - 50
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class DashboardScreenWali extends StatefulWidget {
  const DashboardScreenWali({super.key});
  @override
  _DashboardScreenStateWali createState() => _DashboardScreenStateWali();
}

class _DashboardScreenStateWali extends State<DashboardScreenWali> {
  final List<String> bannerImages = [
    'assets/banner1.png',
    'assets/banner2.png',
    'assets/banner3.png',
  ];
  final PageController _pageController = PageController();
  int _currentBannerIndex = 0;
  int _selectedNavIndex = 0;
  bool _isAnnouncementVisible = true;
  UserModel? _currentUser;
  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), _autoChangeBanner);
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = await _authController.fetchUserProfile();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      print('Gagal mengambil data user: $e');
    }
  }

  void _autoChangeBanner() {
    if (!mounted) return;

    int nextPage = (_currentBannerIndex + 1) % bannerImages.length;
    
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    Future.delayed(const Duration(seconds: 3), _autoChangeBanner);
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        _showLogoutConfirmation();
        break;
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _authController.logout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F7836),
              ),
              child: const Text('Keluar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _onFabPressed() {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Tambah Konten'),
            backgroundColor: const Color(0xFF0F7836),
          ),
          body: const Center(
            child: Text('Halaman Tambah Konten Sedang Dikembangkan'),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
              currentUser: _currentUser,
              pageController: _pageController,
              bannerImages: bannerImages,
              currentBannerIndex: _currentBannerIndex,
            ),

            if (_isAnnouncementVisible)
              AnnouncementBanner(
                onClose: () {
                  setState(() {
                    _isAnnouncementVisible = false;
                  });
                },
              ),

            MenuGrid(context: context),
            const ArtikelSection(),
          ],
        ),
      ),
      
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _selectedNavIndex,
        onTap: _onNavItemTapped,
      ),

      floatingActionButton: CustomFloatingActionButton(
        onPressed: _onFabPressed,
      ),
      
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
} 