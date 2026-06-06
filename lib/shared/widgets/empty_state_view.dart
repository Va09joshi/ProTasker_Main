import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/constants/app_images.dart';

class EmptyStateView extends StatelessWidget {
  final String message;
  final String? subMessage;
  final double imageHeight;

  const EmptyStateView({
    super.key,
    required this.message,
    this.subMessage,
    this.imageHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingXL, horizontal: AppDimensions.paddingLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppImages.emptyState,
              height: imageHeight,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppDimensions.paddingLG),
            Text(
              message,
              style: AppTextStyles.headingMedium.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            if (subMessage != null) ...[
              const SizedBox(height: AppDimensions.paddingXS),
              Text(
                subMessage!,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
