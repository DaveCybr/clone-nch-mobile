import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nch_mobile/v2/app/data/services/init.dart';
import 'v2/app/data/services/firebase_service.dart';
import 'v2/app/routes/app_pages.dart';
import 'v2/app/routes/app_routes.dart';
import 'v2/core/theme/app_theme.dart';

// ✅ Background message handler (HARUS di top level)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic>? initialNotificationData;
  // ✅ CONFIGURE STATUS BAR GLOBALLY
  // 7. Set System UI - versi paling sederhana
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ✅ Jangan gunakan edgeToEdge sama sekali
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white, // Atau warna yang Anda mau
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
    print('✅ Firebase initialized successfully');

    // 3. Set background message handler
    FirebaseMessaging.onBackgroundMessage(
      FirebaseService().firebaseMessagingBackgroundHandler,
    );
    print('✅ Background message handler set');

    // 4. ✅ Check initial notification - SIMPAN data-nya
    initialNotificationData =
        await FirebaseService().checkInitialNotification();
    if (initialNotificationData != null) {
      print('💾 Initial notification data saved for later processing');
    }

    // 5. Initialize Services
    await InitService().initializeServices();

    // 6. ✅ Process initial notification SETELAH services ready
    if (initialNotificationData != null) {
      print('🚀 Processing initial notification after services ready...');
      FirebaseService().processInitialNotification(initialNotificationData);
    }

    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('❌ Error during app initialization: $e');
    print('📋 StackTrace: $stackTrace');

    // Tetap jalankan app meski ada error
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
