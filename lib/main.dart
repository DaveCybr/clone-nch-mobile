// lib/main.dart - UPDATED

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nch_mobile/v2/app/data/services/navigations_services.dart';

import 'v2/app/data/services/init.dart';
import 'v2/app/routes/app_pages.dart';
import 'v2/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure System UI
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    // 1. Initialize GetStorage
    print('📦 Initializing GetStorage...');
    await GetStorage.init();
    print('✅ GetStorage initialized');

    // 2. Initialize Firebase
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp();
    print('✅ Firebase initialized');

    // 5. ✅ Initialize NavigationService FIRST
    print('🗺️ Initializing NavigationService...');
    await Get.putAsync(() async => NavigationService());
    print('✅ NavigationService initialized');

    // 6. Initialize other services
    await InitService().initializeServices();

    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('❌ Error during initialization: $e');
    print('📋 StackTrace: $stackTrace');
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'My NCH',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,

          // ✅ Use simple routing (tidak pakai nested routing)
          initialRoute: AppPages.INITIAL,
          getPages: AppPages.routes,

          locale: Get.deviceLocale ?? const Locale('id', 'ID'),
          fallbackLocale: const Locale('id', 'ID'),
          translations: AppTranslations(),

          defaultTransition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 250),

          // ✅ Unknown route handler
          unknownRoute: GetPage(
            name: '/notfound',
            page: () => const NotFoundPage(),
          ),

          // ✅ Navigation observer untuk debugging
          navigatorObservers: [GetObserver()],
        );
      },
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              const Text(
                'Halaman Tidak Ditemukan',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Halaman yang Anda cari tidak tersedia',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // ✅ Use NavigationService
                  NavigationService.to.toLogin();
                },
                icon: const Icon(Icons.home),
                label: const Text('Kembali ke Login'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'id_ID': {
      'login': 'Masuk',
      'email': 'Email',
      'password': 'Password',
      'remember_me': 'Ingat saya',
      'welcome': 'Selamat Datang',
      'loading': 'Memuat...',
      'error': 'Terjadi Kesalahan',
      'success': 'Berhasil',
      'logout': 'Keluar',
      'dashboard': 'Dashboard',
    },
    'en_US': {
      'login': 'Login',
      'email': 'Email',
      'password': 'Password',
      'remember_me': 'Remember me',
      'welcome': 'Welcome',
      'loading': 'Loading...',
      'error': 'An Error Occurred',
      'success': 'Success',
      'logout': 'Logout',
      'dashboard': 'Dashboard',
    },
  };
}

// ✅ Custom Navigator Observer untuk debugging
class GetObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('🔵 PUSH: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('🔴 POP: ${route.settings.name}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('🟡 REMOVE: ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    print(
      '🟢 REPLACE: ${oldRoute?.settings.name} -> ${newRoute?.settings.name}',
    );
  }
}
