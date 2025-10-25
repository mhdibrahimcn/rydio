import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/location_controller.dart';
import '../controllers/fare_controller.dart';
import '../controllers/ui_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/constants.dart';
import 'widgets/location_input_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final locationController = Get.find<LocationController>();
    final fareController = Get.find<FareController>();
    final uiController = Get.find<UIController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Current Location Chip
                      _buildCurrentLocationChip(locationController),

                      const SizedBox(height: 24),

                      // Location Input Cards
                      _buildLocationInputs(locationController, uiController),

                      const SizedBox(height: 32),

                      // Compare Fares Button
                      _buildCompareButton(locationController, fareController),

                      const SizedBox(height: 32),

                      // Quick Actions
                      _buildQuickActions(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // App Logo/Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppConstants.appName,
              style: AppTextStyles.headline4.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Spacer(),

          // Settings Icon
          IconButton(
            onPressed: () {
              // TODO: Open settings
            },
            icon: Icon(Icons.settings, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationChip(LocationController controller) {
    return Obx(() {
      if (controller.pickupLocation.value == null) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: AppColors.accentGreen.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.my_location, color: AppColors.accentGreen, size: 16),
            const SizedBox(width: 8),
            Text(
              controller.pickupLocation.value!.name,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.accentGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLocationInputs(
    LocationController controller,
    UIController uiController,
  ) {
    return Column(
      children: [
        // Pickup Location
        Obx(
          () => LocationInputCard(
            location: controller.pickupLocation.value,
            label: 'Pickup Location',
            indicatorColor: AppColors.pickupColor,
            isLoading: controller.isLoadingCurrentLocation.value,
            onTap: () => uiController.showLocationSearch(isPickup: true),
          ),
        ),

        // Swap Button
        _buildSwapButton(controller),

        // Drop Location
        Obx(
          () => LocationInputCard(
            location: controller.dropLocation.value,
            label: 'Drop Location',
            indicatorColor: AppColors.dropColor,
            onTap: () => uiController.showLocationSearch(isPickup: false),
          ),
        ),
      ],
    );
  }

  Widget _buildSwapButton(LocationController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: IconButton(
        onPressed: controller.swapLocations,
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Icon(
            Icons.swap_vert,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildCompareButton(
    LocationController locationController,
    FareController fareController,
  ) {
    return Obx(() {
      final canSearch = locationController.canSearchFares;
      final isLoading = fareController.isLoading.value;

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: AppConstants.buttonHeight,
        child: ElevatedButton(
          onPressed:
              canSearch && !isLoading ? fareController.fetchAllFares : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canSearch ? null : AppColors.textTertiary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ).copyWith(
            backgroundColor:
                canSearch
                    ? WidgetStateProperty.all(Colors.transparent)
                    : WidgetStateProperty.all(AppColors.textTertiary),
          ),
          child: Container(
            decoration:
                canSearch
                    ? const BoxDecoration(
                      gradient: AppColors.buttonGradient,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    )
                    : null,
            child: Center(
              child:
                  isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Text(
                        'Compare Fares',
                        style: AppTextStyles.buttonLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: AppTextStyles.headline4),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.history,
                  title: 'Recent',
                  subtitle: 'View history',
                  onTap: () {
                    // TODO: Open history
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.favorite,
                  title: 'Favorites',
                  subtitle: 'Saved places',
                  onTap: () {
                    // TODO: Open favorites
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accentCyan, size: 24),
            const SizedBox(height: 8),
            Text(title, style: AppTextStyles.labelLarge),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
