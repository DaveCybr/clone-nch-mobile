import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/login/screens/login_screen.dart';
import '../features/login/services/auth_service.dart';
import '../features/guru/dashboard/screens/dashboard_screen.dart';
import '../features/siswa/dashboard/screens/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    // Mengatur status bar menjadi transparan
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // Membuat animasi
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Memulai animasi
    _animationController.forward();

    // Cek status login setelah animasi selesai
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Tunggu minimal 2.5 detik untuk animasi splash screen
      await Future.delayed(const Duration(milliseconds: 2500));

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        print('🔍 Token found: ${token.substring(0, 20)}...');

        // Validasi token dengan mengambil user profile
        final loginService = LoginService.instance;
        final userProfile = await loginService.fetchUserProfile();

        if (userProfile != null) {
          print('✅ Token valid, user profile retrieved');

          // Tentukan role user dan redirect ke dashboard yang sesuai
          await _redirectToDashboard(prefs);
        } else {
          print('❌ Token invalid, redirecting to login');
          await _clearInvalidTokenAndRedirectToLogin(prefs);
        }
      } else {
        print('📝 No token found, redirecting to login');
        _redirectToLogin();
      }
    } catch (e) {
      print('⚠️ Error checking auth status: $e');
      // Jika terjadi error, redirect ke login untuk keamanan
      _redirectToLogin();
    }
  }

  Future<void> _redirectToDashboard(SharedPreferences prefs) async {
    try {
      // Cek apakah user adalah student
      final studentId = prefs.getString('student_id_uuid');
      if (studentId != null && studentId.isNotEmpty) {
        print('🎓 User is student, redirecting to student dashboard');
        _navigateToScreen(const DashboardScreenSiswa());
        return;
      }

      // Cek apakah user adalah employee/teacher
      final employeeId = prefs.getString('employee_id_uuid');
      if (employeeId != null && employeeId.isNotEmpty) {
        print('👨‍🏫 User is teacher, redirecting to teacher dashboard');
        _navigateToScreen(const DashboardScreenGuru());
        return;
      }

      // Jika tidak ada role yang terdeteksi, coba fetch user profile untuk mendapatkan role
      print('🔍 No role found in local storage, fetching user profile...');
      final loginService = LoginService.instance;
      final userProfile = await loginService.fetchUserProfile();

      if (userProfile != null) {
        // Default ke teacher dashboard jika tidak bisa menentukan role
        print('📝 Defaulting to teacher dashboard');
        _navigateToScreen(const DashboardScreenGuru());
      } else {
        print('❌ Cannot fetch user profile, redirecting to login');
        _redirectToLogin();
      }
    } catch (e) {
      print('⚠️ Error determining user role: $e');
      // Default ke login jika terjadi error
      _redirectToLogin();
    }
  }

  Future<void> _clearInvalidTokenAndRedirectToLogin(
    SharedPreferences prefs,
  ) async {
    // Hapus token yang tidak valid
    await prefs.remove('auth_token');
    await prefs.remove('employee_id');
    await prefs.remove('employee_id_uuid');
    await prefs.remove('student_id_uuid');

    _redirectToLogin();
  }

  void _redirectToLogin() {
    _navigateToScreen(const LoginScreen());
  }

  void _navigateToScreen(Widget screen) {
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _opacityAnimation,
              child: Image.asset('assets/logo.png', width: 200, height: 200),
            ),
            const SizedBox(height: 32),
            // Loading indicator
            const CircularProgressIndicator(
              color: Color(0xFF0F7836),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
