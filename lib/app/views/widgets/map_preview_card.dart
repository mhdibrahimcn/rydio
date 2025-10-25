import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rydio/app/services/map_service.dart';
import 'package:rydio/app/utils/app_colors.dart';
import 'package:rydio/app/utils/app_text_styles.dart';

class MapPreviewCard extends StatelessWidget {
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final String? originName;
  final String? destName;

  const MapPreviewCard({
    super.key,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
    this.originName,
    this.destName,
  });

  @override
  Widget build(BuildContext context) {
    final distance = MapService.calculateDistance(
      lat1: originLat,
      lng1: originLng,
      lat2: destLat,
      lng2: destLng,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              // Map Image
              _buildMapImage(),

              // Route Info
              _buildRouteInfo(distance),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapImage() {
    final mapUrl = MapService.getStaticMapUrl(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
      width: Get.width.toInt() - 32,
      height: 200,
    );

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        color: AppColors.backgroundSecondary,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Image.network(
          mapUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildMapPlaceholder();
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildMapPlaceholder();
          },
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundSecondary,
            AppColors.backgroundSecondary.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 8),
          Text(
            'Route Preview',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(double distance) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Distance
          Expanded(
            child: _buildInfoItem(
              icon: Icons.straighten,
              label: 'Distance',
              value: '${distance.toStringAsFixed(1)} km',
            ),
          ),

          // Estimated Time
          Expanded(
            child: _buildInfoItem(
              icon: Icons.access_time,
              label: 'Est. Time',
              value:
                  '${MapService.calculateEstimatedTime(distance: distance)} min',
            ),
          ),

          // Route Type
          Expanded(
            child: _buildInfoItem(
              icon: Icons.route,
              label: 'Route',
              value: 'Fastest',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accentCyan, size: 20),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
