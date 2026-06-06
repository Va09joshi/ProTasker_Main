import 'package:flutter/material.dart';
import '../theme/theme.dart';

class SnackbarHelper {
  static void success(BuildContext context, String message) {
    _show(context, message, AppColors.success, Icons.check_circle_outline);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, AppColors.error, Icons.error_outline);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, AppColors.primary, Icons.info_outline);
  }

  static void warning(BuildContext context, String message) {
    _show(context, message, AppColors.warning, Icons.warning_amber_rounded);
  }

  static void _show(BuildContext context, String message, Color bgColor, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: AppColors.background),
            const SizedBox(width: AppDimensions.paddingMD),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.background),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
      ),
    );
  }
}
