import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';

import 'v2/app/data/services/api_service.dart';
import 'v2/app/data/services/storage_service.dart';
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

    // Initialize auth controller last
    Get.put(AuthController(), permanent: true);

    print('All services initialized successfully');
  } catch (e) {
    print('Error initializing services: $e');
    // Still try to initialize basic services
    try {
      Get.put(StorageService(), permanent: true);
      Get.put(ApiService(), permanent: true);
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
      designSize: const Size(375, 812), // iPhone 11 Pro size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'My NCH',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: Routes.SPLASH,
          getPages: AppPages.routes,
          locale: Get.deviceLocale ?? const Locale('id', 'ID'),
          fallbackLocale: const Locale('id', 'ID'),

          // Global translations
          translations: AppTranslations(),

          // Default transition
          defaultTransition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 300),

          // Error handling
          unknownRoute: GetPage(
            name: '/notfound',
            page:
                () => Scaffold(
<<<<<<< HEAD
                  appBar: AppBar(title: const Text('Page Not Found')),
=======
                  appBar: AppBar(title: Text('Page Not Found')),
>>>>>>> 49d3e7f6c546314a0079c5f85aecd72981ffaa46
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
<<<<<<< HEAD
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
=======
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Page not found'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Get.offAllNamed(Routes.LOGIN),
                          child: Text('Go to Login'),
>>>>>>> 49d3e7f6c546314a0079c5f85aecd72981ffaa46
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

// Enhanced translations
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
