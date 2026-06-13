import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/theme.dart';

enum ShimmerType { card, list, profile, dashboard, map }

class LoadingShimmer extends StatelessWidget {
  final ShimmerType type;

  const LoadingShimmer({super.key, this.type = ShimmerType.list});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceAlt,
      highlightColor: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        child: _buildLayout(),
      ),
    );
  }

  Widget _buildLayout() {
    switch (type) {
      case ShimmerType.card:
        return Column(
          children: List.generate(2, (_) => _cardSkeleton()),
        );
      case ShimmerType.profile:
        return Column(
          children: [
            const SizedBox(height: AppDimensions.paddingXL),
            _circle(72),
            const SizedBox(height: AppDimensions.paddingMD),
            _rect(140, 18),
            const SizedBox(height: AppDimensions.paddingSM),
            _rect(100, 14),
            const SizedBox(height: AppDimensions.paddingXL),
            ...[1, 2, 3].map((_) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.paddingMD),
              child: _rect(double.infinity, 48),
            )),
          ],
        );
      case ShimmerType.dashboard:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI cards row
            Row(
              children: [
                Expanded(child: _rect(double.infinity, 80)),
                const SizedBox(width: AppDimensions.padding12),
                Expanded(child: _rect(double.infinity, 80)),
              ],
            ),
            const SizedBox(height: AppDimensions.padding12),
            Row(
              children: [
                Expanded(child: _rect(double.infinity, 80)),
                const SizedBox(width: AppDimensions.padding12),
                Expanded(child: _rect(double.infinity, 80)),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingLG),
            _rect(120, 16),
            const SizedBox(height: AppDimensions.padding12),
            ...[1, 2, 3].map((_) => _listItem()),
          ],
        );
      case ShimmerType.list:
        return Column(
          children: List.generate(4, (_) => _listItem()),
        );
      case ShimmerType.map:
        return _rect(double.infinity, double.infinity);
    }
  }

  Widget _cardSkeleton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingMD),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
        child: Column(
          children: [
            _rect(double.infinity, 120),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.padding12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _rect(80, 12),
                  const SizedBox(height: AppDimensions.paddingSM),
                  _rect(double.infinity, 14),
                  const SizedBox(height: AppDimensions.paddingSM),
                  _rect(100, 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingMD),
      child: Row(
        children: [
          _circle(44),
          const SizedBox(width: AppDimensions.padding12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rect(double.infinity, 14),
                const SizedBox(height: AppDimensions.paddingSM),
                _rect(120, 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rect(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
      ),
    );
  }

  Widget _circle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
      ),
    );
  }
}
