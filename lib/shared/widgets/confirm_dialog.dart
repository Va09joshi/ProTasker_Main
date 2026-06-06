import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import 'app_button.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool isDanger;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
      ),
      title: Text(
        title,
        style: AppTextStyles.headingLarge.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
      content: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingLG,
        AppDimensions.paddingSM,
        AppDimensions.paddingLG,
        AppDimensions.paddingLG,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Cancel',
                variant: ButtonVariant.ghost,
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
            const SizedBox(width: AppDimensions.padding12),
            Expanded(
              child: AppButton(
                label: confirmLabel,
                variant: isDanger ? ButtonVariant.danger : ButtonVariant.primary,
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
