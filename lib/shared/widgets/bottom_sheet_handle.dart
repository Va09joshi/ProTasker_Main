import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: AppDimensions.padding12, bottom: AppDimensions.paddingSM),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        ),
      ),
    );
  }
}
