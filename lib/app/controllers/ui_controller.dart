import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/fare_model.dart';
import '../controllers/location_controller.dart';
import '../views/location_search_page.dart';

class UIController extends GetxController {
  // UI State
  final RxBool isLoadingOverlay = false.obs;

  // Show loading overlay
  void showLoadingOverlay({String? message}) {
    isLoadingOverlay.value = true;
    if (message != null) {
      Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );
    }
  }

  // Hide loading overlay
  void hideLoadingOverlay() {
    isLoadingOverlay.value = false;
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  // Show error snackbar
  void showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  // Show success snackbar
  void showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  // Show info snackbar
  void showInfoSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  // Launch deep link to open cab apps
  Future<void> launchDeepLink(FareModel fare) async {
    if (fare.deepLinkUrl == null || fare.deepLinkUrl!.isEmpty) {
      showErrorSnackbar(
        'Booking Unavailable',
        'Deep link not available for ${fare.serviceDisplayName}',
      );
      return;
    }

    try {
      final uri = Uri.parse(fare.deepLinkUrl!);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        showSuccessSnackbar(
          'Opening ${fare.serviceDisplayName}',
          'Redirecting to ${fare.serviceDisplayName} app...',
        );
      } else {
        // Fallback to app store
        await _launchAppStore(fare.serviceName);
      }
    } catch (e) {
      showErrorSnackbar(
        'Launch Failed',
        'Failed to open ${fare.serviceDisplayName}: ${e.toString()}',
      );
    }
  }

  // Launch app store as fallback
  Future<void> _launchAppStore(ServiceName serviceName) async {
    String storeUrl;

    switch (serviceName) {
      case ServiceName.uber:
        storeUrl = 'https://play.google.com/store/apps/details?id=com.ubercab';
        break;
      case ServiceName.ola:
        storeUrl =
            'https://play.google.com/store/apps/details?id=com.olacabs.customer';
        break;
      case ServiceName.rapido:
        storeUrl =
            'https://play.google.com/store/apps/details?id=com.rapido.passenger';
        break;
    }

    try {
      final uri = Uri.parse(storeUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      showInfoSnackbar(
        'App Not Installed',
        'Redirecting to app store to install ${serviceName.toString().split('.').last}',
      );
    } catch (e) {
      showErrorSnackbar(
        'Store Launch Failed',
        'Failed to open app store: ${e.toString()}',
      );
    }
  }

  // Show location search bottom sheet
  void showLocationSearch({required bool isPickup}) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF1B263B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Search content will be added by the view
            Expanded(
              child: GetBuilder<LocationController>(
                builder: (controller) => LocationSearchPage(isPickup: isPickup),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // Navigate to page

  // Show confirmation dialog
  Future<bool> showConfirmationDialog({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    return await Get.dialog<bool>(
          Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1B263B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(result: false),
                          child: Text(cancelText),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Get.back(result: true),
                          child: Text(confirmText),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }
}
