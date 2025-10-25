import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/location_controller.dart';
import '../models/location_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class LocationSearchPage extends StatefulWidget {
  final bool isPickup;

  const LocationSearchPage({super.key, required this.isPickup});

  @override
  State<LocationSearchPage> createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends State<LocationSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final LocationController _locationController = Get.find<LocationController>();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _locationController.searchLocation(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Header
        _buildSearchHeader(),

        // Search Results
        Expanded(child: _buildSearchResults()),
      ],
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundPrimary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: TextField(
              controller: _searchController,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search for a location',
                hintStyle: AppTextStyles.placeholder,
                prefixIcon: Icon(Icons.search, color: AppColors.textTertiary),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _locationController.searchResults.clear();
                          },
                          icon: Icon(
                            Icons.clear,
                            color: AppColors.textTertiary,
                          ),
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Current Location Button
          Obx(
            () =>
                _locationController.isLoadingCurrentLocation.value
                    ? _buildLoadingCurrentLocation()
                    : _buildCurrentLocationButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _locationController.getCurrentLocation(),
        icon: Icon(Icons.my_location, color: AppColors.accentGreen),
        label: Text(
          'Use Current Location',
          style: AppTextStyles.buttonMedium.copyWith(
            color: AppColors.accentGreen,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen.withOpacity(0.1),
          foregroundColor: AppColors.accentGreen,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.accentGreen.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCurrentLocation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Getting current location...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.accentGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Obx(() {
      if (_locationController.isSearching.value) {
        return _buildLoadingResults();
      }

      if (_searchController.text.isEmpty) {
        return _buildEmptyState();
      }

      if (_locationController.searchResults.isEmpty) {
        return _buildNoResultsState();
      }

      return _buildResultsList();
    });
  }

  Widget _buildLoadingResults() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) => _buildLoadingItem(),
    );
  }

  Widget _buildLoadingItem() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: 200,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Search for a location',
            style: AppTextStyles.headline4.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a place name or address',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: AppTextStyles.headline4.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      itemCount: _locationController.searchResults.length,
      itemBuilder: (context, index) {
        final location = _locationController.searchResults[index];
        return _buildLocationItem(location);
      },
    );
  }

  Widget _buildLocationItem(LocationModel location) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              () =>
                  _locationController.selectLocation(location, widget.isPickup),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                // Location Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        widget.isPickup
                            ? AppColors.pickupColor.withOpacity(0.1)
                            : AppColors.dropColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.isPickup ? Icons.my_location : Icons.location_on,
                    color:
                        widget.isPickup
                            ? AppColors.pickupColor
                            : AppColors.dropColor,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 12),

                // Location Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (location.address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          location.address,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textTertiary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
