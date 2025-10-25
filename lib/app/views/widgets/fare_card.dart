import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rydio/app/controllers/ui_controller.dart';
import 'package:rydio/app/models/fare_model.dart';
import 'package:rydio/app/utils/app_colors.dart';
import 'package:rydio/app/utils/app_text_styles.dart';

class FareCard extends StatelessWidget {
  final FareModel fare;
  final VoidCallback? onTap;

  const FareCard({super.key, required this.fare, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border:
              fare.isBestPrice
                  ? Border.all(color: AppColors.accentGreen, width: 2)
                  : Border.all(color: AppColors.glassBorder, width: 1),
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
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Service Icon
                  _buildServiceIcon(),
                  const SizedBox(width: 16),

                  // Service Info
                  Expanded(child: _buildServiceInfo()),

                  // Price and Action
                  _buildPriceAndAction(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: _getServiceGradient(),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getServiceColor().withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(fare.serviceIcon, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _buildServiceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(fare.serviceDisplayName, style: AppTextStyles.serviceName),
            if (fare.isBestPrice) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Best Price',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(fare.cabType, style: AppTextStyles.cabType),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.person, size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(
              '${fare.seats} seat${fare.seats > 1 ? 's' : ''}',
              style: AppTextStyles.labelSmall,
            ),
            const SizedBox(width: 12),
            Icon(Icons.access_time, size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text('${fare.eta} min', style: AppTextStyles.eta),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceAndAction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('₹${fare.price.toStringAsFixed(0)}', style: AppTextStyles.price),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            final uiController = Get.find<UIController>();
            uiController.launchDeepLink(fare);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _getServiceColor(),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: Text(
            'Book Now',
            style: AppTextStyles.buttonSmall.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }

  LinearGradient _getServiceGradient() {
    return switch (fare.serviceName) {
      ServiceName.uber => const LinearGradient(
        colors: [AppColors.uberBlack, Color(0xFF333333)],
      ),
      ServiceName.ola => const LinearGradient(
        colors: [AppColors.olaGreen, Color(0xFF00A693)],
      ),
      ServiceName.rapido => const LinearGradient(
        colors: [AppColors.rapidoYellow, Color(0xFFE6C200)],
      ),
    };
  }

  Color _getServiceColor() {
    return switch (fare.serviceName) {
      ServiceName.uber => AppColors.uberBlack,
      ServiceName.ola => AppColors.olaGreen,
      ServiceName.rapido => AppColors.rapidoYellow,
    };
  }
}
