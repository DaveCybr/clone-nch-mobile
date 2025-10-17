import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nch_mobile/v2/app/data/services/version_service.dart';

class UpdateDialogService {
  final VersionService _versionService = Get.find<VersionService>();

  /// Cek versi dan tampilkan dialog update jika diperlukan
  Future<void> checkAndShowUpdateDialog() async {
    final result = await _versionService.checkVersion();

    if (result.needsUpdate) {
      _showUpdateDialog(result);
    } else {
      // Tidak ada update, bisa tampilkan log atau abaikan
      debugPrint('✅ Aplikasi sudah versi terbaru');
    }
  }

  /// Tampilkan dialog update
  void _showUpdateDialog(VersionCheckResult result) {
    Get.dialog(
      barrierDismissible: !result.forceUpdate,
      WillPopScope(
        onWillPop: () async => !result.forceUpdate,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '🔔 Pembaruan Tersedia',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                result.updateMessage ??
                    'Versi terbaru (${result.latestVersion}) tersedia di Play Store.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Versi saat ini: ${result.currentVersion}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            // Tombol Update
            ElevatedButton.icon(
              onPressed: () {
                _versionService.openPlayStore();
              },
              icon: const Icon(Icons.system_update),
              label: const Text('Perbarui Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            if (!result.forceUpdate) ...[
              const SizedBox(width: 10),
              // Tombol Lewati
              TextButton(
                onPressed: () {
                  Get.back(); // Tutup dialog
                },
                child: const Text('Nanti Saja'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
