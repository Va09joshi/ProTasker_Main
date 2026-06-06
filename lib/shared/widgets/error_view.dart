import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import 'app_button.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 28, color: AppColors.error),
            ),
            const SizedBox(height: AppDimensions.paddingLG),
            Text(
              'Something went wrong',
              style: AppTextStyles.headingMedium,
            ),
            const SizedBox(height: AppDimensions.paddingSM),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.paddingLG),
              AppButton(
                label: 'Try Again',
                onPressed: onRetry,
                variant: ButtonVariant.secondary,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
