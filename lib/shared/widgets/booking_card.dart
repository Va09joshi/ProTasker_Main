import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme.dart';
import '../models/models.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final UserRole viewerRole;
  final VoidCallback onTap;
  final Widget? actionArea;

  const BookingCard({
    super.key,
    required this.booking,
    required this.viewerRole,
    required this.onTap,
    this.actionArea,
  });

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.proposal:
        return AppColors.statusPending;
      case BookingStatus.accepted:
      case BookingStatus.onTheWay:
        return AppColors.statusAccepted;
      case BookingStatus.inProgress:
        return AppColors.statusActive;
      case BookingStatus.completed:
        return AppColors.statusCompleted;
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  String _formatStatus(BookingStatus status) {
    switch (status) {
      case BookingStatus.onTheWay:
        return 'On the Way';
      case BookingStatus.inProgress:
        return 'In Progress';
      default:
        return status.name[0].toUpperCase() + status.name.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClientView = viewerRole == UserRole.client;
    final otherPartyName = isClientView ? booking.providerName : booking.clientName;

    String? otherPartyPhoto;
    try {
      otherPartyPhoto = isClientView ? (booking as dynamic).providerPhoto : booking.clientPhoto;
    } catch (_) {
      otherPartyPhoto = null;
    }

    final statusColor = _getStatusColor(booking.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.padding12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Status color strip
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppDimensions.radiusMD)),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMD),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: category + status
                      Row(
                        children: [
                          if (booking.isEmergency)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.flash_on_rounded, size: 10, color: AppColors.warning),
                                  const SizedBox(width: 2),
                                  Text(
                                    'EMERGENCY',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            booking.serviceCategory.name.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                            ),
                            child: Text(
                              _formatStatus(booking.status),
                              style: AppTextStyles.caption.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.padding12),

                      // Service + Provider row
                      Row(
                        children: [
                          // Avatar
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceAlt,
                              border: Border.all(color: AppColors.border, width: 1),
                            ),
                            child: ClipOval(
                              child: otherPartyPhoto != null && otherPartyPhoto.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: otherPartyPhoto,
                                      fit: BoxFit.cover,
                                      width: 44,
                                      height: 44,
                                      placeholder: (_, __) => const Icon(Icons.person_outline, color: AppColors.textTertiary, size: 20),
                                      errorWidget: (_, __, ___) => const Icon(Icons.person_outline, color: AppColors.textTertiary, size: 20),
                                    )
                                  : const Icon(Icons.person_outline, color: AppColors.textTertiary, size: 20),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.padding12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.serviceTitle,
                                  style: AppTextStyles.labelLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  otherPartyName,
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${booking.netPrice.toStringAsFixed(0)}',
                            style: AppTextStyles.headingMedium.copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),

                      // Date + time
                      const SizedBox(height: AppDimensions.padding12),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: AppDimensions.iconSM, color: AppColors.textTertiary),
                          const SizedBox(width: AppDimensions.paddingXS),
                          Text(
                            DateFormat('MMM dd, yyyy').format(booking.scheduledAt),
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: AppDimensions.paddingMD),
                          Icon(Icons.access_time_outlined, size: AppDimensions.iconSM, color: AppColors.textTertiary),
                          const SizedBox(width: AppDimensions.paddingXS),
                          Text(
                            booking.timeSlot,
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),

                      // Action area
                      if (actionArea != null) ...[
                        const SizedBox(height: AppDimensions.padding12),
                        const Divider(),
                        const SizedBox(height: AppDimensions.paddingSM),
                        actionArea!,
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
