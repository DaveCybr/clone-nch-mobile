import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';

import 'v2/app/data/services/api_service.dart';
import 'v2/app/data/services/storage_service.dart';
import 'v2/app/data/services/version_service.dart';
import 'v2/app/data/widgets/update_dialog.dart'; // ✅ TAMBAHKAN INI
import 'v2/app/modules/auth/controllers/auth_controller.dart';
import 'v2/app/routes/app_pages.dart';
import 'v2/app/routes/app_routes.dart';
import 'v2/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Get Storage
    await GetStorage.init();

    // Initialize core services first
    await _initializeServices();

    // Set preferred orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('Error during app initialization: $e');
    print('StackTrace: $stackTrace');
    // Run app anyway with basic setup
    runApp(const MyApp());
  }
}

Future<void> _initializeServices() async {
  try {
    // Initialize storage service first
    Get.put(StorageService(), permanent: true);

    // Wait for storage service to be fully initialized
    final storageService = Get.find<StorageService>();
    await storageService.onInit();

    // Initialize API service
    Get.put(ApiService(), permanent: true);

    // Wait for API service to be initialized
    Get.find<ApiService>().onInit();

    // TAMBAHKAN: Initialize VersionService
    Get.put(VersionService(), permanent: true);
    Get.find<VersionService>().onInit();

    // Initialize auth controller last
    Get.put(AuthController(), permanent: true);

    print('All services initialized successfully');

    // ✅ CEK UPDATE SETELAH SEMUA SERVICE SIAP
    Future.delayed(Duration(seconds: 3), () {
      try {
        print('🔍 Starting automatic update check...');
        final updateService = UpdateDialogService();
        updateService.checkAndShowUpdateDialog();
      } catch (e) {
        print('❌ Error in automatic update check: $e');
      }
    });
  } catch (e) {
    print('Error initializing services: $e');
    // Still try to initialize basic services
    try {
      Get.put(StorageService(), permanent: true);
      Get.put(ApiService(), permanent: true);
      Get.put(VersionService(), permanent: true); // TAMBAHKAN INI
      Get.put(AuthController(), permanent: true);
    } catch (fallbackError) {
      print('Fallback initialization also failed: $fallbackError');
    }
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
        return GetMaterialApp.router(
          title: 'My NCH',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          getPages: AppPages.routes,
          routeInformationParser: GetInformationParser(),
          routerDelegate: Get.rootDelegate,
          locale: Get.deviceLocale ?? const Locale('id', 'ID'),
          fallbackLocale: const Locale('id', 'ID'),
          translations: AppTranslations(),
          defaultTransition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 300),
          unknownRoute: GetPage(
            name: '/notfound',
            page:
                () => Scaffold(
                  appBar: AppBar(title: const Text('Page Not Found')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text('Page not found'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Get.offAllNamed(Routes.LOGIN),
                          child: const Text('Go to Login'),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        );
      },
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
    'ar_SA': {
      'login': 'تسجيل الدخول',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'remember_me': 'تذكرني',
      'welcome': 'أهلا وسهلا',
      'loading': 'جاري التحميل...',
      'error': 'حدث خطأ',
      'success': 'نجح',
      'logout': 'تسجيل الخروج',
      'dashboard': 'لوحة التحكم',
    },
  };
}
