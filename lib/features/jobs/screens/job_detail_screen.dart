import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/job_provider.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../chat/repositories/chat_repository.dart';
import '../../../shared/models/models.dart';
import '../../booking/repositories/booking_repository.dart';
import 'accept_job_sheet.dart';
import '../../../core/services/notification_service.dart';

class JobDetailScreen extends ConsumerWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobDetailProvider(jobId));
    final currentUserAsync = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Job Details'),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: jobAsync.when(
        data: (job) {
          if (job == null) return const Center(child: Text('Job not found'));
          final distanceAsync = ref.watch(jobDistanceProvider(job));
          final isOwner = currentUserAsync.value?.uid == job.clientId;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : AppDimensions.paddingLG,
              vertical: AppDimensions.paddingXL,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingLG),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                            ),
                            child: Text(
                              job.category,
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              String label;
                              Color color;
                              if (job.status == 'open') {
                                label = 'OPEN';
                                color = AppColors.success;
                              } else if (job.status == 'in_progress') {
                                label = 'HIRED';
                                color = AppColors.primary;
                              } else if (job.status == 'completed') {
                                label = 'COMPLETED';
                                color = AppColors.textTertiary;
                              } else {
                                label = job.status.replaceAll('_', ' ').toUpperCase();
                                color = AppColors.warning;
                              }
                              
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                                ),
                                child: Text(
                                  label,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingMD),
                      Text(
                        job.title,
                        style: AppTextStyles.headingLarge.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingSM),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: 6),
                          Text(
                            'Posted ${DateFormat.yMMMd().format(job.createdAt)}',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppDimensions.paddingXL),

                // Client Details
                const Text('Posted By', style: AppTextStyles.headingMedium),
                const SizedBox(height: AppDimensions.paddingSM),
                ref.watch(jobClientProvider(job.clientId)).when(
                  data: (client) {
                    if (client == null) return const Text('Client details unavailable');
                    return Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingLG),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1.0),
                      ),
                      child: Row(
                        children: [
                          AppAvatar(
                            imageUrl: client.profilePhoto,
                            name: client.name,
                            size: 48,
                          ),
                          const SizedBox(width: AppDimensions.paddingMD),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  client.name,
                                  style: AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (client.isVerified)
                                  Row(
                                    children: [
                                      const Icon(Icons.verified, color: AppColors.success, size: 16),
                                      const SizedBox(width: 4),
                                      Text('Verified Client', style: AppTextStyles.caption.copyWith(color: AppColors.success)),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const LoadingShimmer(type: ShimmerType.card),
                  error: (_, __) => const Text('Error loading client details'),
                ),

                const SizedBox(height: AppDimensions.paddingXL),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingLG),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description_outlined, color: isDark ? Colors.white70 : AppColors.primary, size: 24),
                          const SizedBox(width: 10),
                          const Text('Problem Description', style: AppTextStyles.headingMedium),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingMD),
                      Text(
                        job.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingXL),

                if (job.imageUrls.isNotEmpty) ...[
                  const Text('Photos', style: AppTextStyles.headingMedium),
                  const SizedBox(height: AppDimensions.paddingSM),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: job.imageUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.paddingMD),
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                          child: Image.network(
                            job.imageUrls[index],
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 120,
                                height: 120,
                                color: AppColors.surface,
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                ],

                const SizedBox(height: AppDimensions.paddingXL),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingLG),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: isDark ? Colors.white70 : AppColors.primary, size: 24),
                          const SizedBox(width: 10),
                          const Text('Location', style: AppTextStyles.headingMedium),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingMD),
                      distanceAsync.when(
                        data: (distance) {
                          if (distance == null) return const Text('Location unavailable');
                          return Row(
                            children: [
                              const Icon(Icons.directions_run_rounded, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                '${distance.toStringAsFixed(1)} km away from you',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (_, __) => const Text('Error loading distance'),
                      ),
                      const SizedBox(height: AppDimensions.paddingLG),
                      // Map View
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(job.latitude, job.longitude),
                              zoom: 14.0,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('job_location'),
                                position: LatLng(job.latitude, job.longitude),
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                              ),
                            },
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            myLocationButtonEnabled: false,
                            liteModeEnabled: true, // Optimizes the map
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Proposals List (Only if Owner and Job is Open)
                if (isOwner && job.status == 'open') ...[
                  const SizedBox(height: AppDimensions.paddingXL),
                  _buildProposalsList(context, ref, job.id),
                ],
                // Accepted Provider (Only if Owner and Job is NOT Open)
                if (isOwner && job.status != 'open') ...[
                  const SizedBox(height: AppDimensions.paddingXL),
                  _buildAcceptedProvider(context, ref, job.id),
                ],

                const SizedBox(height: 48),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(jobDetailProvider(jobId)),
        ),
      ),
      bottomNavigationBar: (jobAsync.value != null && currentUserAsync.value?.role == UserRole.provider && currentUserAsync.value?.uid != jobAsync.value?.clientId && jobAsync.value!.status == 'open') ? Container(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG, vertical: AppDimensions.paddingMD),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Builder(
            builder: (context) {
              final user = currentUserAsync.value!;
              final job = jobAsync.value!;
              final clientAsync = ref.watch(jobClientProvider(job.clientId));

              return Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: AppButton(
                      label: 'Chat',
                      variant: ButtonVariant.secondary,
                      onPressed: () async {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          final chatRepo = ref.read(chatRepositoryProvider);
                          final chatId = await chatRepo.getOrCreateChat(
                            job.clientId,
                            user.uid,
                            job.id, // Using job ID as booking ID for job-based chats
                          );
                          
                          // Pop loading dialog
                          if (context.mounted) Navigator.pop(context);
                          
                          // Navigate to chat
                          if (context.mounted) context.push('/chat/$chatId');
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to start chat: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMD),
                  Expanded(
                    flex: 1,
                    child: AppButton(
                      label: 'Send Proposal',
                      onPressed: () {
                        final client = clientAsync.value;
                        if (client == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Loading client details, please wait.')),
                          );
                          return;
                        }
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => AcceptJobSheet(
                            job: job,
                            provider: user,
                            client: client,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          ),
        ),
      ) : null,
    );
  }

  Widget _buildProposalsList(BuildContext context, WidgetRef ref, String jobId) {
    final proposalsAsync = ref.watch(jobProposalsProvider(jobId));

    return proposalsAsync.when(
      data: (proposals) {
        if (proposals.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_rounded,
            title: 'No Proposals Yet',
            subtitle: 'Providers have not submitted any proposals for this job yet.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Received Proposals (${proposals.length})', style: AppTextStyles.headingMedium),
            const SizedBox(height: AppDimensions.paddingMD),
            ...proposals.map((booking) => _ProposalCard(booking: booking, jobId: jobId)),
          ],
        );
      },
      loading: () => const LoadingShimmer(type: ShimmerType.list),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(jobProposalsProvider(jobId))),
    );
  }

  Widget _buildAcceptedProvider(BuildContext context, WidgetRef ref, String jobId) {
    final acceptedAsync = ref.watch(jobAcceptedBookingProvider(jobId));

    return acceptedAsync.when(
      data: (booking) {
        if (booking == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hired Provider', style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppDimensions.paddingMD),
            _ProposalCard(booking: booking, jobId: jobId, isAccepted: true),
          ],
        );
      },
      loading: () => const LoadingShimmer(type: ShimmerType.list),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(jobAcceptedBookingProvider(jobId))),
    );
  }
}

class _ProposalCard extends ConsumerWidget {
  final BookingModel booking;
  final String jobId;
  final bool isAccepted;

  const _ProposalCard({required this.booking, required this.jobId, this.isAccepted = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMD),
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  context.push('/provider/${booking.providerId}');
                },
                child: AppAvatar(name: booking.providerName, imageUrl: booking.providerPhoto, size: 56),
              ),
              const SizedBox(width: AppDimensions.paddingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.providerName, style: AppTextStyles.labelLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Est. Price: ₹${booking.grossPrice.toStringAsFixed(2)}',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppDimensions.paddingMD),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${booking.scheduledAt.toLocal().toString().split(" ")[0]} at ${booking.timeSlot}',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingLG),
          if (!isAccepted) Row(
            children: [
              Expanded(
                flex: 1,
                child: AppButton(
                  label: 'Chat',
                  variant: ButtonVariant.secondary,
                  onPressed: () async {
                    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                    try {
                      final chatId = await ref.read(chatRepositoryProvider).getOrCreateChat(booking.clientId, booking.providerId, booking.serviceId);
                      if (context.mounted) Navigator.pop(context);
                      if (context.mounted) context.push('/chat/$chatId');
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMD),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: 'Accept Proposal',
                  onPressed: () async {
                    // Show confirmation
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Accept Proposal?'),
                        content: Text('Are you sure you want to hire ${booking.providerName} for ₹${booking.grossPrice}?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          AppButton(label: 'Accept', onPressed: () => Navigator.pop(ctx, true)),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                      try {
                        await ref.read(bookingRepositoryProvider).acceptProposal(booking.id, jobId, booking.clientId);
                        
                        await NotificationService.sendNotification(
                          targetUid: booking.providerId,
                          title: 'Proposal Accepted!',
                          body: 'The client has accepted your proposal. Please proceed to the location.',
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                                  const SizedBox(width: 12),
                                  Text('Hired!', style: AppTextStyles.headingLarge.copyWith(color: AppColors.success)),
                                ],
                              ),
                              content: const Text('You have successfully accepted the proposal. The provider has been notified and other proposals have been removed.'),
                              actions: [
                                AppButton(
                                  label: 'View Booking',
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    context.go('/client/bookings');
                                  },
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error accepting proposal: $e')));
                        }
                      }
                    }
                  },
                ),
              ),
            ],
          ) else Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Message Provider',
                  icon: Icons.chat_bubble_rounded,
                  onPressed: () async {
                    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                    try {
                      final chatId = await ref.read(chatRepositoryProvider).getOrCreateChat(booking.clientId, booking.providerId, booking.serviceId);
                      if (context.mounted) Navigator.pop(context);
                      if (context.mounted) context.push('/chat/$chatId');
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
