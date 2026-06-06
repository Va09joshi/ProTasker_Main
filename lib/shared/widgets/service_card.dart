import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/theme.dart';
import '../models/models.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: AppDimensions.padding12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusMD)),
              child: CachedNetworkImage(
                imageUrl: service.images.isNotEmpty ? service.images.first : '',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 120,
                  color: AppColors.surfaceAlt,
                  child: const Center(child: Icon(Icons.image_outlined, color: AppColors.textTertiary)),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 120,
                  color: AppColors.surfaceAlt,
                  child: const Center(child: Icon(Icons.image_not_supported_outlined, color: AppColors.textTertiary)),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppDimensions.padding12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                        ),
                        child: Text(
                          service.category.name.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                          const SizedBox(width: 2),
                          Text(
                            service.rating.toStringAsFixed(1),
                            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingSM),

                  // Title
                  Text(
                    service.title,
                    style: AppTextStyles.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.spacing2),

                  // Provider name
                  Text(
                    service.providerName,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.paddingSM),

                  // Price
                  Text(
                    '\$${service.basePrice.toStringAsFixed(0)}',
                    style: AppTextStyles.headingMedium.copyWith(color: AppColors.accent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
