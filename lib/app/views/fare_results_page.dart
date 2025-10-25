import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/fare_controller.dart';
import '../controllers/location_controller.dart';
import '../controllers/ui_controller.dart';
import '../models/ride_option.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'widgets/fare_card.dart';
import 'widgets/map_preview_card.dart';

class FareResultsPage extends StatelessWidget {
  const FareResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final fareController = Get.find<FareController>();
    final locationController = Get.find<LocationController>();
    final uiController = Get.find<UIController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(fareController, uiController),

              // Content
              Expanded(
                child: Obx(() {
                  if (fareController.isLoading.value) {
                    return _buildLoadingState();
                  }

                  if (fareController.error.value.isNotEmpty) {
                    return _buildErrorState(fareController);
                  }

                  if (fareController.fares.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildResultsContent(
                    fareController,
                    locationController,
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(
    FareController fareController,
    UIController uiController,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => Get.back(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available Options', style: AppTextStyles.headline3),
                Obx(
                  () => Text(
                    '${fareController.fares.length} options found',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          // Refresh Button
          Obx(
            () => IconButton(
              onPressed:
                  fareController.isRefreshing.value
                      ? null
                      : fareController.refreshFares,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child:
                    fareController.isRefreshing.value
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.accentCyan,
                            ),
                          ),
                        )
                        : Icon(
                          Icons.refresh,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
          ),
          const SizedBox(height: 16),
          Text(
            'Finding the best fares...',
            style: AppTextStyles.headline4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(FareController fareController) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: AppTextStyles.headline4.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              fareController.error.value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fareController.retry,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No fares available',
              style: AppTextStyles.headline4.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting different locations',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsContent(
    FareController fareController,
    LocationController locationController,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Map Preview
          if (locationController.hasBothLocations)
            MapPreviewCard(
              originLat: locationController.pickupLocation.value!.latitude,
              originLng: locationController.pickupLocation.value!.longitude,
              destLat: locationController.dropLocation.value!.latitude,
              destLng: locationController.dropLocation.value!.longitude,
              originName: locationController.pickupLocation.value!.name,
              destName: locationController.dropLocation.value!.name,
            ),

          // Filter Tabs
          _buildFilterTabs(fareController),

          // Fare Cards
          _buildFareCards(fareController),

          const SizedBox(height: 100), // Space for potential bottom actions
        ],
      ),
    );
  }

  Widget _buildFilterTabs(FareController fareController) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: RideOption.values.length,
        itemBuilder: (context, index) {
          final option = RideOption.values[index];
          return Obx(() {
            final isSelected = fareController.selectedFilter.value == option;
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    fareController.setFilter(option);
                  }
                },
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(option.icon),
                    const SizedBox(width: 4),
                    Text(option.displayName),
                  ],
                ),
                selectedColor: AppColors.accentCyan.withOpacity(0.2),
                checkmarkColor: AppColors.accentCyan,
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  color:
                      isSelected
                          ? AppColors.accentCyan
                          : AppColors.textSecondary,
                ),
                backgroundColor: AppColors.backgroundSecondary,
                side: BorderSide(
                  color:
                      isSelected ? AppColors.accentCyan : AppColors.glassBorder,
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildFareCards(FareController fareController) {
    final uiController = Get.find<UIController>();

    return Obx(() {
      final filteredFares = fareController.filteredFares;

      if (filteredFares.isEmpty) {
        return _buildNoFilterResults();
      }

      return Column(
        children:
            filteredFares
                .map(
                  (fare) => FareCard(
                    fare: fare,
                    onTap: () => uiController.launchDeepLink(fare),
                  ),
                )
                .toList(),
      );
    });
  }

  Widget _buildNoFilterResults() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.filter_alt_off, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'No results for this filter',
            style: AppTextStyles.headline4.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different category',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
