import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../../shared/widgets/status_timeline.dart';
import '../../../shared/widgets/review_card.dart';
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

  Future<void> _updateStatus(BuildContext context, BookingModel booking, BookingStatus newStatus, String currentUserId, {String? reason}) async {
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
      final recipientId = currentUserId == booking.clientId ? booking.providerId : booking.clientId;
      String title = 'Booking Update';
      String body = 'Your booking for ${booking.serviceTitle} was updated.';
      NotificationType type = NotificationType.system;

      if (newStatus == BookingStatus.accepted) {
        title = 'Booking Accepted';
        body = '${booking.providerName} accepted your booking.';
        type = NotificationType.bookingAccepted;
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

      final notifRef = db.collection('notifications').doc();
      final notification = NotificationModel(
        id: notifRef.id,
        userId: recipientId,
        title: title,
        body: body,
        type: type,
        payload: {'bookingId': booking.id},
        isRead: false,
        createdAt: DateTime.now(),
      );
      batch.set(notifRef, notification.toMap());

      await batch.commit();
      
      if (context.mounted) SnackbarHelper.info(context, 'Status updated to ${newStatus.name}');
    } catch (e) {
      if (context.mounted) SnackbarHelper.error(context, 'Failed to update: $e');
    }
  }

  void _showCancelSheet(BuildContext context, BookingModel booking, String currentUserId) {
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
                    _updateStatus(context, booking, BookingStatus.cancelled, currentUserId, reason: 'Client Cancelled: ${ctrl.text}');
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
        title: const Text('Booking Details'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: bookingAsync.when(
          data: (booking) {
            if (booking == null) return const Center(child: Text('Booking not found'));
            
            return currentUserAsync.when(
              data: (user) {
                if (user == null) return const Center(child: Text('User error'));
                
                final isClient = user.role == UserRole.client;
                
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : AppDimensions.paddingLG,
                    vertical: AppDimensions.paddingLG,
                  ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StatusTimeline(currentStatus: booking.status),
                    const SizedBox(height: AppDimensions.paddingXL),
                    
                    _buildServiceInfoCard(booking),
                    const SizedBox(height: AppDimensions.paddingMD),
                    
                    _buildPartyCard(booking, isClient, context, ref),
                    const SizedBox(height: AppDimensions.paddingMD),
                    
                    _buildPriceBreakdownCard(booking),
                    const SizedBox(height: AppDimensions.paddingMD),
                    
                    if (booking.proofImages.isNotEmpty) ...[
                      _buildProofImages(booking),
                      const SizedBox(height: AppDimensions.paddingMD),
                    ],
                    
                    if (booking.status == BookingStatus.completed && booking.clientReviewed) ...[
                      _buildReviewSection(ref, booking.id),
                      const SizedBox(height: AppDimensions.paddingMD),
                    ],
                    
                    const SizedBox(height: AppDimensions.paddingLG),
                    _buildActionButtons(context, booking, user),
                    const SizedBox(height: 100),
                  ],
                ),
              );
              },
              loading: () => const LoadingShimmer(type: ShimmerType.profile),
              error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(currentUserProvider)),
            );
          },
          loading: () => const LoadingShimmer(type: ShimmerType.profile),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(bookingDetailStreamProvider(bookingId))),
        ),
      ),
    );
  }

  Widget _buildServiceInfoCard(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(booking.serviceTitle, style: AppTextStyles.headingLarge)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
                child: Text(booking.serviceCategory.name, style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent)),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppDimensions.paddingSM),
              Text('${DateFormat.yMMMd().format(booking.scheduledAt)} • ${booking.timeSlot}', style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSM),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppDimensions.paddingSM),
              Expanded(child: Text('${booking.address.street}, ${booking.address.city}, ${booking.address.state} ${booking.address.pincode}', style: AppTextStyles.bodyMedium)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartyCard(BookingModel booking, bool isClient, BuildContext context, WidgetRef ref) {
    final avatar = isClient ? booking.providerPhoto : booking.clientPhoto;
    final name = isClient ? booking.providerName : booking.clientName;
    final phone = isClient ? booking.providerPhone : booking.clientPhone;
    final label = isClient ? 'Provider' : 'Client';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
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
                          const Icon(Icons.phone_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(phone, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.accent),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSM)),
                ),
                onPressed: () async {
                  final chatId = await ref.read(chatRepositoryProvider).getOrCreateChat(booking.clientId, booking.providerId, booking.id);
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
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
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
              Text('₹${booking.grossPrice.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Platform Fee', style: AppTextStyles.bodyMedium),
              Text('- ₹${booking.platformFee.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium),
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
                child: Text('Cash', style: AppTextStyles.labelSmall.copyWith(color: AppColors.success)),
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
              Text('₹${booking.netPrice.toStringAsFixed(2)}', style: AppTextStyles.headingLarge.copyWith(color: AppColors.success)),
            ],
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
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(bookingReviewProvider(bookingId))),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, BookingModel booking, UserModel user) {
    final isClient = user.role == UserRole.client;

    if (isClient) {
      if (booking.status == BookingStatus.pending || booking.status == BookingStatus.accepted) {
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Cancel Booking',
            variant: ButtonVariant.danger,
            onPressed: () => _showCancelSheet(context, booking, user.uid),
          ),
        );
      }
      if (booking.status == BookingStatus.completed && !booking.clientReviewed) {
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
                onPressed: () => _updateStatus(context, booking, BookingStatus.rejected, user.uid, reason: 'Declined by provider'),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMD),
            Expanded(
              child: AppButton(
                label: 'Accept',
                onPressed: () => _updateStatus(context, booking, BookingStatus.accepted, user.uid),
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
                onPressed: () => _updateStatus(context, booking, BookingStatus.onTheWay, user.uid),
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
            onPressed: () => _updateStatus(context, booking, BookingStatus.inProgress, user.uid),
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
}
