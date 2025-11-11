import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nch_mobile/v2/app/data/services/api_service.dart';
import 'package:nch_mobile/v2/app/data/services/firebase_service.dart';
import 'package:nch_mobile/v2/app/data/services/notification_service.dart';
import 'package:nch_mobile/v2/app/data/services/storage_service.dart';
import 'package:nch_mobile/v2/app/data/services/version_service.dart';
import 'package:nch_mobile/v2/app/data/widgets/update_dialog.dart';
import 'package:nch_mobile/v2/app/modules/auth/controllers/auth_controller.dart';

class InitService {
  Future<void> initializeServices() async {
    try {
      print('🚀 Starting service initialization...');

      // 1️⃣ StorageService (HARUS PERTAMA)
      print('1️⃣ Initializing StorageService...');
      Get.put(StorageService(), permanent: true);
      final storageService = Get.find<StorageService>();
      await storageService.onInit();
      print('✅ StorageService initialized');

      // 2️⃣ ApiService
      print('2️⃣ Initializing ApiService...');
      Get.put(ApiService(), permanent: true);
      Get.find<ApiService>().onInit();
      print('✅ ApiService initialized');

      // 3️⃣ VersionService
      print('3️⃣ Initializing VersionService...');
      Get.put(VersionService(), permanent: true);
      Get.find<VersionService>().onInit();
      print('✅ VersionService initialized');

      // 4️⃣ FirebaseService (CRITICAL - MUST BE BEFORE AuthController!)
      print('4️⃣ Initializing FirebaseService...');
      try {
        Get.put(FirebaseService(), permanent: true);
        await Get.find<FirebaseService>().onInit();
        print('✅ FirebaseService initialized');
      } catch (e, stackTrace) {
        print('⚠️ FirebaseService initialization failed: $e');
        print('   Stack: $stackTrace');
        throw Exception('FirebaseService initialization failed: $e');
      }

      // 5️⃣ NotificationService
      print('5️⃣ Initializing NotificationService...');
      try {
        Get.put(NotificationService(), permanent: true);
        await Get.find<NotificationService>().onInit();
        print('✅ NotificationService initialized');
      } catch (e) {
        print('⚠️ NotificationService initialization failed: $e');
      }

      // 6️⃣ AuthController (SETELAH semua service ready!)
      print('6️⃣ Initializing AuthController...');
      try {
        Get.put(AuthController(), permanent: true);
        print('✅ AuthController initialized');
      } catch (e, stackTrace) {
        print('❌ AuthController initialization failed: $e');
        print('   Stack: $stackTrace');
        throw Exception('AuthController initialization failed: $e');
      }

      print('🎉 All services initialized successfully!');

      // Auto update check
      Future.delayed(const Duration(seconds: 3), () {
        try {
          print('🔍 Starting automatic update check...');
          final updateService = UpdateDialogService();
          updateService.checkAndShowUpdateDialog();
        } catch (e) {
          print('⚠️ Error in automatic update check: $e');
        }
      });
    } catch (e, stackTrace) {
      print('❌ Error initializing services: $e');
      print('📋 StackTrace: $stackTrace');

      // ✅ FALLBACK: Pastikan minimal services terinstall
      try {
        print('🔄 Attempting fallback initialization...');

        if (!Get.isRegistered<StorageService>()) {
          Get.put(StorageService(), permanent: true);
          print('✅ StorageService initialized (fallback)');
        }

        if (!Get.isRegistered<ApiService>()) {
          Get.put(ApiService(), permanent: true);
          print('✅ ApiService initialized (fallback)');
        }

        if (!Get.isRegistered<VersionService>()) {
          Get.put(VersionService(), permanent: true);
          print('✅ VersionService initialized (fallback)');
        }

        if (!Get.isRegistered<FirebaseService>()) {
          try {
            Get.put(FirebaseService(), permanent: true);
            await Get.find<FirebaseService>().onInit();
            print('✅ FirebaseService initialized (fallback)');
          } catch (fbError) {
            print('❌ FirebaseService fallback also failed: $fbError');
          }
        }

        if (!Get.isRegistered<AuthController>()) {
          Get.put(AuthController(), permanent: true);
          print('✅ AuthController initialized (fallback)');
        }

        print('✅ Fallback initialization completed');
      } catch (fallbackError) {
        print('❌ Fallback initialization also failed: $fallbackError');
      }
    }
  }
}
