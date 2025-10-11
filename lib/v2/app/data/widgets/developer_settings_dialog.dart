import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

enum UrlOption { production, staging, custom }

class DeveloperSettingsDialog extends StatefulWidget {
  const DeveloperSettingsDialog({Key? key}) : super(key: key);

  @override
  State<DeveloperSettingsDialog> createState() =>
      _DeveloperSettingsDialogState();
}

class _DeveloperSettingsDialogState extends State<DeveloperSettingsDialog> {
  final TextEditingController _urlController = TextEditingController();
  final StorageService _storage = Get.find<StorageService>();
  final ApiService _api = Get.find<ApiService>();

  UrlOption _selectedOption = UrlOption.production;
  String _currentUrl = '';

  // URL Options
  final String _productionUrl = 'https://be.nurulchotib.com/api';
  final String _stagingUrl = 'https://nch-be-staging.jtinova.com/api';

  @override
  void initState() {
    super.initState();
    _loadCurrentUrl();
  }

  void _loadCurrentUrl() {
    final box = GetStorage();
    _currentUrl = box.read('base_url') ?? _productionUrl;

    // Determine selected option based on current URL
    if (_currentUrl == _productionUrl) {
      _selectedOption = UrlOption.production;
    } else if (_currentUrl == _stagingUrl) {
      _selectedOption = UrlOption.staging;
    } else {
      _selectedOption = UrlOption.custom;
      _urlController.text = _currentUrl;
    }
  }

  void _saveSettings() {
    String newUrl;

    switch (_selectedOption) {
      case UrlOption.production:
        newUrl = _productionUrl;
        break;
      case UrlOption.staging:
        newUrl = _stagingUrl;
        break;
      case UrlOption.custom:
        newUrl = _urlController.text.trim();

        if (newUrl.isEmpty) {
          Get.snackbar(
            'Error',
            'URL tidak boleh kosong',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        // Validasi URL
        if (!newUrl.startsWith('http://') && !newUrl.startsWith('https://')) {
          newUrl = 'https://$newUrl';
        }

        if (newUrl.endsWith('/')) {
          newUrl = newUrl.substring(0, newUrl.length - 1);
        }
        break;
    }

    // Save to storage
    final box = GetStorage();
    box.write('base_url', newUrl);

    // Update API service base URL
    _api.updateBaseUrl(newUrl);

    Get.back();

    Get.snackbar(
      'Success',
      'Base URL berhasil diubah ke:\n$newUrl',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void _resetSettings() {
    setState(() {
      _selectedOption = UrlOption.production;
      _urlController.clear();
    });

    final box = GetStorage();
    box.write('base_url', _productionUrl);
    _api.updateBaseUrl(_productionUrl);

    Get.snackbar(
      'Success',
      'Settings direset ke Production',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.settings, color: Colors.green.shade700, size: 32.sp),
                SizedBox(width: 12.w),
                Text(
                  'Developer Settings',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Current Base URL
            Text(
              'Current Base URL:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                _currentUrl,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade700,
                  fontFamily: 'monospace',
                ),
              ),
            ),

            SizedBox(height: 24.h),

            Text(
              'Select Environment:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: 12.h),

            // Production Option
            _buildUrlOption(
              option: UrlOption.production,
              title: 'Production',
              url: _productionUrl,
              icon: Icons.cloud,
              color: Colors.green,
            ),

            SizedBox(height: 12.h),

            // Staging Option
            _buildUrlOption(
              option: UrlOption.staging,
              title: 'Staging',
              url: _stagingUrl,
              icon: Icons.science,
              color: Colors.orange,
            ),

            SizedBox(height: 12.h),

            // Custom Option
            _buildUrlOption(
              option: UrlOption.custom,
              title: 'Custom URL',
              url: 'Enter your own URL',
              icon: Icons.edit,
              color: Colors.blue,
            ),

            // Custom URL Input
            if (_selectedOption == UrlOption.custom) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.blue.shade300, width: 2),
                ),
                child: TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    hintText: 'https://your-url.com',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14.sp,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                ),
              ),
            ],

            SizedBox(height: 24.h),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Cancel Button
                    TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 12.h,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlOption({
    required UrlOption option,
    required String title,
    required String url,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedOption == option;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOption = option;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? Icon(Icons.check, size: 16.sp, color: Colors.white)
                      : null,
            ),

            SizedBox(width: 12.w),

            // Icon
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade600,
              size: 20.sp,
            ),

            SizedBox(width: 12.w),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    url,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
