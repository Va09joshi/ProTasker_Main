import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/theme.dart';

enum ButtonVariant { primary, secondary, danger, ghost, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final bool fullWidth;
  final IconData? icon;
  final Widget? iconWidget;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.fullWidth = true,
    this.icon,
    this.iconWidget,
  });

  Widget _buildContent({Color? loaderColor}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: loaderColor ?? Colors.white,
              ),
            )
          : Row(
              key: const ValueKey('content'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconWidget != null) ...[
                  iconWidget!,
                  const SizedBox(width: AppDimensions.paddingSM),
                ] else if (icon != null) ...[
                  Icon(icon, size: AppDimensions.iconMD),
                  const SizedBox(width: AppDimensions.paddingSM),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: GoogleFonts.lexendDeca(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Widget button;

    switch (variant) {
      case ButtonVariant.primary:
        button = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLG,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
          ),
          onPressed: isLoading ? null : onPressed,
          child: _buildContent(),
        );
      case ButtonVariant.secondary:
        button = OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 1.0,
            ),
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLG,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
          ),
          onPressed: isLoading ? null : onPressed,
          child: _buildContent(
            loaderColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        );
      case ButtonVariant.danger:
        button = OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger, width: 1.0),
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLG,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
          ),
          onPressed: isLoading ? null : onPressed,
          child: _buildContent(loaderColor: AppColors.danger),
        );
      case ButtonVariant.ghost:
        button = TextButton(
          style: TextButton.styleFrom(
            foregroundColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLG,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
          ),
          onPressed: isLoading ? null : onPressed,
          child: _buildContent(
            loaderColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        );
      case ButtonVariant.text:
        button = TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
          ),
          onPressed: isLoading ? null : onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppDimensions.iconMD),
                const SizedBox(width: AppDimensions.paddingSM),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: GoogleFonts.lexendDeca(
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
