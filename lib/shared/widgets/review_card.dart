import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme.dart';
import '../models/models.dart';
import 'star_rating.dart';
import 'app_avatar.dart';

class ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.padding12),
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name + date + rating
          Row(
            children: [
              AppAvatar(
                name: review.reviewerName,
                imageUrl: review.reviewerPhoto,
                size: 36,
              ),
              const SizedBox(width: AppDimensions.padding12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewerName, style: AppTextStyles.labelLarge),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM dd, yyyy').format(review.createdAt),
                      style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              StarRating(rating: review.rating, size: 14),
            ],
          ),

          // Comment
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.padding12),
            Text(
              review.comment,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
