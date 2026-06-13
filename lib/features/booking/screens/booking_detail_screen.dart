import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/theme.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../chat/repositories/chat_repository.dart';
import '../providers/booking_detail_provider.dart';
import 'proof_upload_bottom_sheet.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/widgets.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    BookingModel booking,
    BookingStatus newStatus,
    String currentUserId, {
    String? reason,
  }) async {
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final bookingRef = db.collection('bookings').doc(booking.id);
      final updates = <String, dynamic>{
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (reason != null) updates['notes'] = reason;

      batch.update(bookingRef, updates);

      // Send notification to the OTHER party
      final recipientId = currentUserId == booking.clientId
          ? booking.providerId
          : booking.clientId;
      String title = 'Booking Update';
      String body = 'Your booking for ${booking.serviceTitle} was updated.';

      if (newStatus == BookingStatus.accepted) {
        title = 'Booking Accepted';
        body = '${booking.providerName} accepted your booking.';
      } else if (newStatus == BookingStatus.rejected) {
        title = 'Booking Declined';
        body = '${booking.providerName} declined your booking.';
      } else if (newStatus == BookingStatus.cancelled) {
        title = 'Booking Cancelled';
        body = '${booking.clientName} cancelled the booking.';
      } else if (newStatus == BookingStatus.onTheWay) {
        title = 'Provider On The Way';
        body = '${booking.providerName} is on the way to your location.';
      } else if (newStatus == BookingStatus.inProgress) {
        title = 'Job Started';
        body = '${booking.providerName} has started the job.';
      }

      await batch.commit();

      await NotificationService.sendNotification(
        targetUid: recipientId,
        title: title,
        body: body,
      );

      if (context.mounted)
        SnackbarHelper.info(context, 'Status updated to ${newStatus.name}');
    } catch (e) {
      if (context.mounted)
        SnackbarHelper.error(context, 'Failed to update: $e');
    }
  }

  void _showCancelSheet(
    BuildContext context,
    BookingModel booking,
    String currentUserId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: AppDimensions.paddingLG,
            right: AppDimensions.paddingLG,
            top: AppDimensions.paddingLG,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BottomSheetHandle(),
              const SizedBox(height: AppDimensions.paddingMD),
              const Text('Cancel Booking', style: AppTextStyles.headingLarge),
              const SizedBox(height: AppDimensions.paddingMD),
              AppTextField(
                controller: ctrl,
                label: 'Reason for cancelling',
                maxLines: 2,
              ),
              const SizedBox(height: AppDimensions.paddingLG),
              AppButton(
                label: 'Confirm Cancel',
                variant: ButtonVariant.danger,
                onPressed: () {
                  if (ctrl.text.isNotEmpty) {
                    _updateStatus(
                      context,
                      booking,
                      BookingStatus.cancelled,
                      currentUserId,
                      reason: 'Client Cancelled: ${ctrl.text}',
                    );
                    Navigator.pop(ctx);
                  }
                },
              ),
              const SizedBox(height: AppDimensions.paddingLG),
            ],
          ),
        );
      },
    );
  }

  void _openProofSheet(BuildContext context, BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ProofUploadBottomSheet(booking: booking),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailStreamProvider(bookingId));
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Booking Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: bookingAsync.when(
          data: (booking) {
            if (booking == null)
              return const Center(child: Text('Booking not found'));

            return currentUserAsync.when(
              data: (user) {
                if (user == null)
                  return const Center(child: Text('User error'));

                final isClient = user.role == UserRole.client;

                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.background,
                        AppColors.primary.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width > 600
                        ? 32.0
                        : AppDimensions.paddingLG,
                    vertical: AppDimensions.paddingLG,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StatusTimeline(currentStatus: booking.status),
                      const SizedBox(height: AppDimensions.paddingXL),

                      _buildServiceInfoCard(booking),
                      const SizedBox(height: AppDimensions.paddingMD),

                      if (booking.status == BookingStatus.accepted ||
                          booking.status == BookingStatus.onTheWay) ...[
                        _buildOTPSecurityCard(booking, isClient, context),
                        const SizedBox(height: AppDimensions.paddingMD),
                      ],

                      _buildPartyCard(booking, isClient, context, ref),
                      const SizedBox(height: AppDimensions.paddingMD),

                      if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                        _buildWorkDescriptionCard(booking),
                        const SizedBox(height: AppDimensions.paddingMD),
                      ],

                      _buildPriceBreakdownCard(booking),
                      const SizedBox(height: AppDimensions.paddingMD),

                      if (booking.proofImages.isNotEmpty) ...[
                        _buildProofImages(booking),
                        const SizedBox(height: AppDimensions.paddingMD),
                      ],

                      if (booking.status == BookingStatus.completed &&
                          booking.clientReviewed) ...[
                        _buildReviewSection(ref, booking.id),
                        const SizedBox(height: AppDimensions.paddingMD),
                      ],

                      const SizedBox(height: AppDimensions.paddingLG),
                      _buildActionButtons(context, booking, user),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              );
            },
              loading: () => const LoadingShimmer(type: ShimmerType.profile),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.refresh(currentUserProvider),
              ),
            );
          },
          loading: () => const LoadingShimmer(type: ShimmerType.profile),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.refresh(bookingDetailStreamProvider(bookingId)),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceInfoCard(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.serviceTitle,
                  style: AppTextStyles.headingLarge,
                ),
              ),
              Row(
                children: [
                  if (booking.isEmergency)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                      ),
                      child: Text(
                        'EMERGENCY',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                    child: Text(
                      booking.serviceCategory.name,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.paddingSM),
              Text(
                '${DateFormat.yMMMd().format(booking.scheduledAt)} • ${booking.timeSlot}',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSM),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.paddingSM),
              Expanded(
                child: Text(
                  '${booking.address.street}, ${booking.address.city}, ${booking.address.state} ${booking.address.pincode}',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartyCard(
    BookingModel booking,
    bool isClient,
    BuildContext context,
    WidgetRef ref,
  ) {
    final avatar = isClient ? booking.providerPhoto : booking.clientPhoto;
    final name = isClient ? booking.providerName : booking.clientName;
    final phone = isClient ? booking.providerPhone : booking.clientPhone;
    final label = isClient ? 'Provider' : 'Client';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          Row(
            children: [
              AppAvatar(name: name, imageUrl: avatar, size: 48),
              const SizedBox(width: AppDimensions.paddingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.labelLarge),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _makePhoneCall(phone),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.phone_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.accent,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                ),
                onPressed: () async {
                  final chatId = await ref
                      .read(chatRepositoryProvider)
                      .getOrCreateChat(
                        booking.clientId,
                        booking.providerId,
                        booking.id,
                      );
                  if (context.mounted) context.push('/chat/$chatId');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdownCard(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Summary', style: AppTextStyles.headingLarge),
          const SizedBox(height: AppDimensions.paddingMD),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gross Amount', style: AppTextStyles.bodyMedium),
              Text(
                '₹${(booking.grossPrice - booking.priorityFee).toStringAsFixed(2)}',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          if (booking.isEmergency) ...[
            const SizedBox(height: AppDimensions.paddingSM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Emergency Priority Fee',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.warning),
                ),
                Text(
                  '+ ₹${booking.priorityFee.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.warning),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppDimensions.paddingSM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Platform Fee', style: AppTextStyles.bodyMedium),
              Text(
                '- ₹${booking.platformFee.toStringAsFixed(2)}',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Payment Method', style: AppTextStyles.bodyMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
                child: Text(
                  'Cash',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSM),
          const Divider(height: 24, color: AppColors.border),
          const SizedBox(height: AppDimensions.paddingSM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Net Paid', style: AppTextStyles.labelLarge),
              Text(
                '₹${booking.netPrice.toStringAsFixed(2)}',
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkDescriptionCard(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Work Description / Notes', style: AppTextStyles.headingLarge),
          const SizedBox(height: AppDimensions.paddingMD),
          Text(
            booking.notes!,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildProofImages(BookingModel booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Proof of Work', style: AppTextStyles.headingLarge),
        const SizedBox(height: AppDimensions.paddingMD),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppDimensions.paddingSM,
            mainAxisSpacing: AppDimensions.paddingSM,
          ),
          itemCount: booking.proofImages.length,
          itemBuilder: (context, index) => ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            child: CachedNetworkImage(
              imageUrl: booking.proofImages[index],
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection(WidgetRef ref, String bookingId) {
    final reviewAsync = ref.watch(bookingReviewProvider(bookingId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Client Review', style: AppTextStyles.headingLarge),
        const SizedBox(height: AppDimensions.paddingMD),
        reviewAsync.when(
          data: (review) {
            if (review == null) return const Text('Review hidden or deleted.');
            return ReviewCard(review: review);
          },
          loading: () => const LoadingShimmer(type: ShimmerType.card),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.refresh(bookingReviewProvider(bookingId)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    BookingModel booking,
    UserModel user,
  ) {
    final isClient = user.role == UserRole.client;

    if (isClient) {
      if (booking.status == BookingStatus.pending ||
          booking.status == BookingStatus.accepted) {
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Cancel Booking',
            variant: ButtonVariant.danger,
            onPressed: () => _showCancelSheet(context, booking, user.uid),
          ),
        );
      }
      if (booking.status == BookingStatus.completed &&
          !booking.clientReviewed) {
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Leave a Review',
            icon: Icons.star_outline_rounded,
            onPressed: () {
              context.push('/review/${booking.id}');
            },
          ),
        );
      }
    } else {
      if (booking.status == BookingStatus.pending) {
        return Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Decline',
                variant: ButtonVariant.danger,
                onPressed: () => _updateStatus(
                  context,
                  booking,
                  BookingStatus.rejected,
                  user.uid,
                  reason: 'Declined by provider',
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMD),
            Expanded(
              child: AppButton(
                label: 'Accept',
                onPressed: () => _updateStatus(
                  context,
                  booking,
                  BookingStatus.accepted,
                  user.uid,
                ),
              ),
            ),
          ],
        );
      }

      if (booking.status == BookingStatus.accepted) {
        return Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Cancel',
                variant: ButtonVariant.danger,
                onPressed: () => _showCancelSheet(context, booking, user.uid),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMD),
            Expanded(
              child: AppButton(
                label: 'On My Way',
                onPressed: () => _updateStatus(
                  context,
                  booking,
                  BookingStatus.onTheWay,
                  user.uid,
                ),
              ),
            ),
          ],
        );
      }

      if (booking.status == BookingStatus.onTheWay) {
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Start Job',
            onPressed: () => _showOTPDialog(context, booking, user.uid),
          ),
        );
      }

      if (booking.status == BookingStatus.inProgress) {
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Collect Cash & Complete',
            variant: ButtonVariant.primary,
            onPressed: () => _openProofSheet(context, booking),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildOTPSecurityCard(
    BookingModel booking,
    bool isClient,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayOtp =
        booking.otp ?? (booking.id.hashCode.abs() % 9000 + 1000).toString();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isClient
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.security_rounded,
                      color: AppColors.success,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'START PIN',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingMD),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBackground
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    displayOtp.split('').join('  '),
                    style: AppTextStyles.headingLarge.copyWith(
                      fontSize: 32,
                      letterSpacing: 4,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingMD),
                Text(
                  'Share this PIN with your provider when they arrive to start the job.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'VERIFICATION REQUIRED',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingSM),
                Text(
                  'Ask the client for the security PIN shown on their screen to start this job.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }

  void _showOTPDialog(
    BuildContext context,
    BookingModel booking,
    String currentUserId,
  ) {
    final displayOtp =
        booking.otp ?? (booking.id.hashCode.abs() % 9000 + 1000).toString();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _OTPVerificationDialog(
        expectedOtp: displayOtp,
        onVerified: () => _updateStatus(
          context,
          booking,
          BookingStatus.inProgress,
          currentUserId,
        ),
      ),
    );
  }
}

class _OTPVerificationDialog extends StatefulWidget {
  final String expectedOtp;
  final VoidCallback onVerified;

  const _OTPVerificationDialog({
    required this.expectedOtp,
    required this.onVerified,
  });

  @override
  State<_OTPVerificationDialog> createState() => _OTPVerificationDialogState();
}

class _OTPVerificationDialogState extends State<_OTPVerificationDialog> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _verifyOtp() {
    final enteredOtp = _controllers.map((c) => c.text).join();
    if (enteredOtp.length < 4) {
      setState(() {
        _errorMessage = 'Please enter all 4 digits';
      });
      return;
    }

    if (enteredOtp == widget.expectedOtp) {
      setState(() {
        _errorMessage = '';
        _isLoading = true;
      });
      Navigator.pop(context);
      widget.onVerified();
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN. Please try again.';
      });
      // Clear controllers and refocus on first
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        ),
      ),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingSM),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.security_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          Text(
            'Enter Start PIN',
            style: AppTextStyles.headingLarge.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ask the client for the 4-digit security PIN shown on their booking screen to verify arrival.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              return SizedBox(
                width: 50,
                height: 56,
                child: TextFormField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  autofocus: index == 0,
                  style: AppTextStyles.headingLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMD,
                      ),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMD,
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      if (index < 3) {
                        _focusNodes[index + 1].requestFocus();
                      } else {
                        _focusNodes[index].unfocus();
                        _verifyOtp();
                      }
                    } else {
                      if (index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    }
                  },
                ),
              );
            }),
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.paddingMD),
            Text(
              _errorMessage,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
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
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMD),
            Expanded(
              child: AppButton(
                label: 'Verify',
                onPressed: _verifyOtp,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
