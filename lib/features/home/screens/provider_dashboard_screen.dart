import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/provider_dashboard_providers.dart';
import '../../jobs/providers/job_provider.dart';
import '../../jobs/models/job_post.dart';
import '../../jobs/screens/job_feed_screen.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../../core/router/route_names.dart';

import '../../location/screens/map_picker_screen.dart';
import '../../../core/services/location_service.dart';
import '../../booking/screens/proof_upload_bottom_sheet.dart';
import '../../../core/services/notification_service.dart';

class ProviderDashboardScreen extends ConsumerStatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  ConsumerState<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends ConsumerState<ProviderDashboardScreen> {
  bool _hasCheckedLocation = false;

  Future<void> _updateBookingStatus(BuildContext context, BookingModel booking, BookingStatus status, {String? reason}) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (reason != null) updates['notes'] = reason;
      
      await FirebaseFirestore.instance.collection('bookings').doc(booking.id).update(updates);
      
      // Notifications
      String? notifTitle;
      String? notifBody;
      
      if (status == BookingStatus.accepted) {
        notifTitle = 'Booking Accepted! 🎉';
        notifBody = 'Your booking request for ${booking.serviceTitle} has been accepted.';
      } else if (status == BookingStatus.rejected) {
        notifTitle = 'Booking Declined';
        notifBody = 'Your booking request for ${booking.serviceTitle} was declined.';
      } else if (status == BookingStatus.onTheWay) {
        notifTitle = 'Provider On The Way 🚗';
        notifBody = 'The provider is on their way for ${booking.serviceTitle}.';
      } else if (status == BookingStatus.inProgress) {
        notifTitle = 'Job Started 🛠️';
        notifBody = 'The provider has started working on ${booking.serviceTitle}.';
      }

      if (notifTitle != null && notifBody != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': booking.clientId,
          'title': notifTitle,
          'body': notifBody,
          'type': 'booking',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'relatedId': booking.id,
        });

        await NotificationService.sendNotification(
          targetUid: booking.clientId,
          title: notifTitle,
          body: notifBody,
        );
      }
      
      if (context.mounted) SnackbarHelper.info(context, 'Booking ${status.name}');
    } catch (e) {
      if (context.mounted) SnackbarHelper.error(context, 'Error: $e');
    }
  }

  void _showDeclineReasonSheet(BuildContext context, BookingModel booking) {
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
              const Text('Decline Request', style: AppTextStyles.headingLarge),
              const SizedBox(height: AppDimensions.paddingMD),
              AppTextField(
                controller: ctrl,
                label: 'Reason for declining',
                maxLines: 3,
              ),
              const SizedBox(height: AppDimensions.paddingLG),
              AppButton(
                label: 'Confirm Decline',
                variant: ButtonVariant.danger,
                onPressed: () {
                  if (ctrl.text.isNotEmpty) {
                    _updateBookingStatus(context, booking, BookingStatus.rejected, reason: ctrl.text);
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

  Future<void> _openMaps(Address address) async {
    final query = Uri.encodeComponent('${address.street}, ${address.city}, ${address.state} ${address.pincode}');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _toggleOnlineStatus(BuildContext context, String uid, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isOnline': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (context.mounted) SnackbarHelper.error(context, 'Failed to update status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(providerStatsProvider);
            ref.invalidate(providerPendingRequestsProvider);
            ref.invalidate(providerActiveJobProvider);
            ref.invalidate(providerUpcomingJobsProvider);
          },
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 60,
                collapsedHeight: 60,
                floating: true,
                pinned: true,
                backgroundColor: AppColors.background,
                surfaceTintColor: Colors.transparent,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                scrolledUnderElevation: 0,
                title: Text('Dashboard', style: AppTextStyles.displayMedium.copyWith(color: AppColors.textPrimary)),
                actions: [
                  userAsync.when(
                    data: (user) {
                      if (user == null) return const SizedBox.shrink();
                      
                      if (!_hasCheckedLocation) {
                        _hasCheckedLocation = true;
                        if (user.address.lat == 0.0 && user.address.lng == 0.0) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _fetchDeviceLocation(context, user.uid);
                          });
                        }
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: AppDimensions.paddingLG),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.padding12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: user.isOnline ? AppColors.success : AppColors.textTertiary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.paddingSM),
                              Text(
                                user.isOnline ? 'Online' : 'Offline', 
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: user.isOnline ? AppColors.textPrimary : AppColors.textSecondary,
                                )
                              ),
                              const SizedBox(width: AppDimensions.paddingSM),
                              SizedBox(
                                height: 20,
                                child: Switch(
                                  value: user.isOnline,
                                  onChanged: (val) => _toggleOnlineStatus(context, user.uid, user.isOnline),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : AppDimensions.paddingLG,
                    vertical: AppDimensions.paddingMD,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      userAsync.when(
                        data: (user) {
                          if (user == null) return const SizedBox.shrink();
                          final firstName = user.name.split(' ').first;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppDimensions.paddingLG),
                            child: Text('Welcome back, $firstName', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      _buildStatsGrid(ref),
                      const SizedBox(height: AppDimensions.paddingXL),
                      _buildJobBoardBanner(context, ref),
                      const SizedBox(height: AppDimensions.paddingXL),
                      _buildActiveJob(context, ref),
                      const SizedBox(height: AppDimensions.paddingXL),
                      _buildPendingRequests(context, ref),
                      const SizedBox(height: AppDimensions.paddingXL),
                      _buildUpcomingJobs(ref),
                      const SizedBox(height: AppDimensions.paddingLG),
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

  Widget _buildStatsGrid(WidgetRef ref) {
    final statsAsync = ref.watch(providerStatsProvider);

    return statsAsync.when(
      data: (stats) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Overview', style: AppTextStyles.headingLarge),
            const SizedBox(height: AppDimensions.paddingMD),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Today',
                    '₹${stats.todayEarnings.toStringAsFixed(0)}',
                    'assets/images/money-bag.png',
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: AppDimensions.padding12),
                Expanded(
                  child: _buildStatCard(
                    'Jobs',
                    '${stats.weekJobs}',
                    'assets/images/business-bag.png',
                    AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.padding12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Rating',
                    stats.avgRating.toStringAsFixed(1),
                    'assets/images/star-rating.png',
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppDimensions.padding12),
                Expanded(
                  child: _buildStatCard(
                    'Completion',
                    '${stats.completionRate.toStringAsFixed(0)}%',
                    'assets/images/checked.png',
                    AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const LoadingShimmer(type: ShimmerType.dashboard),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(providerStatsProvider)),
    );
  }

  Widget _buildStatCard(String label, String value, String imagePath, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingSM),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Image.asset(imagePath, width: 28, height: 28),
          ),
          const SizedBox(height: AppDimensions.paddingLG),
          Text(value, style: AppTextStyles.displayMedium),
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildJobBoardBanner(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobFeedProvider);
    return jobsAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) {
          return _buildEmptyJobBanner(context);
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Available Jobs', style: AppTextStyles.headingLarge),
                TextButton(
                  onPressed: () => context.pushNamed(RouteNames.jobFeed),
                  child: Text('See All', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingSM),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: jobs.length > 5 ? 5 : jobs.length,
                clipBehavior: Clip.none,
                separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.paddingMD),
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return _buildMiniJobCard(context, ref, job);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const LoadingShimmer(type: ShimmerType.dashboard),
      error: (_, __) => _buildEmptyJobBanner(context),
    );
  }

  Widget _buildEmptyJobBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(RouteNames.jobFeed),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Open Job Board',
                    style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find tasks requested by clients nearby.',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniJobCard(BuildContext context, WidgetRef ref, JobPost job) {
    final distanceAsync = ref.watch(jobDistanceProvider(job));
    final clientAsync = ref.watch(jobClientProvider(job.clientId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => context.push('/job/${job.id}'),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: Text(job.category, style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                ),
                Text(
                  job.budget != null ? '₹${job.budget!.toStringAsFixed(0)}' : 'Negotiable',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMD),
            Text(
              job.title,
              style: AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              job.description,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                clientAsync.when(
                  data: (client) {
                    if (client == null) return const SizedBox.shrink();
                    return AppAvatar(imageUrl: client.profilePhoto, name: client.name, size: 24);
                  },
                  loading: () => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (_, __) => const Icon(Icons.person, size: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: clientAsync.when(
                    data: (client) => Text(
                      client?.name ?? 'Unknown',
                      style: AppTextStyles.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                distanceAsync.when(
                  data: (distance) => Text(
                    distance != null ? '${distance.toStringAsFixed(1)} km' : 'Nearby',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                  ),
                  loading: () => const SizedBox(width: 20, height: 10, child: LinearProgressIndicator()),
                  error: (_, __) => Text('Nearby', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequests(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(providerPendingRequestsProvider);

    return pendingAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Requests', style: AppTextStyles.headingLarge),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  ),
                  child: Text(
                    '${bookings.length}',
                    style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMD),
            ...bookings.map((b) => Dismissible(
              key: Key(b.id),
              direction: DismissDirection.horizontal,
              background: Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(bottom: AppDimensions.padding12),
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
              ),
              secondaryBackground: Container(
                alignment: Alignment.centerRight,
                margin: const EdgeInsets.only(bottom: AppDimensions.padding12),
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  await _updateBookingStatus(context, b, BookingStatus.accepted);
                  return true;
                } else {
                  _showDeclineReasonSheet(context, b);
                  return false; 
                }
              },
              child: BookingCard(
                booking: b,
                viewerRole: UserRole.provider,
                onTap: () {},
                actionArea: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Decline',
                        variant: ButtonVariant.ghost,
                        onPressed: () => _showDeclineReasonSheet(context, b),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.padding12),
                    Expanded(
                      child: AppButton(
                        label: 'Accept',
                        onPressed: () => _updateBookingStatus(context, b, BookingStatus.accepted),
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        );
      },
      loading: () => const LoadingShimmer(type: ShimmerType.list),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(providerPendingRequestsProvider)),
    );
  }

  Widget _buildActiveJob(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(providerActiveJobProvider);

    return activeAsync.when(
      data: (booking) {
        if (booking == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Active Job', style: AppTextStyles.headingLarge),
            const SizedBox(height: AppDimensions.paddingMD),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLG),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                border: Border.all(color: AppColors.accent),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingSM),
                      StatusBadge(status: booking.status),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingMD),
                  Row(
                    children: [
                      AppAvatar(name: booking.clientName, imageUrl: booking.clientPhoto, size: 36),
                      const SizedBox(width: AppDimensions.padding12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.clientName, style: AppTextStyles.labelLarge),
                          const SizedBox(height: 2),
                          Text('Client', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingMD),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.padding12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: AppDimensions.paddingSM),
                        Expanded(child: Text('${booking.address.street}, ${booking.address.city}', style: AppTextStyles.bodyMedium)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingLG),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Navigate',
                          icon: Icons.navigation_rounded,
                          variant: ButtonVariant.ghost,
                          onPressed: () => _openMaps(booking.address),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.padding12),
                      if (booking.status == BookingStatus.accepted)
                        Expanded(
                          child: AppButton(
                            label: 'On My Way',
                            onPressed: () => _updateBookingStatus(context, booking, BookingStatus.onTheWay),
                          ),
                        )
                      else if (booking.status == BookingStatus.onTheWay)
                        Expanded(
                          child: AppButton(
                            label: 'Start Job',
                            onPressed: () => _showOTPDialog(context, booking),
                          ),
                        )
                      else if (booking.status == BookingStatus.inProgress)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(0, AppDimensions.touchTarget),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSM)),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 20),
                            label: const Text('Complete', style: AppTextStyles.labelLarge),
                            onPressed: () => _openProofSheet(context, booking),
                          ),
                        )
                      else
                        Expanded(
                          child: AppButton(
                            label: 'View',
                            onPressed: () => context.push('/booking/${booking.id}'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(providerActiveJobProvider)),
    );
  }

  Widget _buildUpcomingJobs(WidgetRef ref) {
    final upcomingAsync = ref.watch(providerUpcomingJobsProvider);

    return upcomingAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upcoming', style: AppTextStyles.headingLarge),
            const SizedBox(height: AppDimensions.paddingMD),
            ...bookings.map((b) => BookingCard(
              booking: b,
              viewerRole: UserRole.provider,
              onTap: () {},
            )),
          ],
        );
      },
      loading: () => const LoadingShimmer(type: ShimmerType.list),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(providerUpcomingJobsProvider)),
    );
  }

  Future<void> _fetchDeviceLocation(BuildContext context, String uid) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: AppDimensions.paddingLG),
            const Text('Fetching location...'),
          ],
        ),
      ),
    );

    try {
      final pos = await LocationService.getCurrentLocation();
      if (mounted) Navigator.pop(context); // Close loading dialog

      if (pos != null) {
        final pm = await LocationService.getPlacemarkFromCoordinates(pos.latitude, pos.longitude);
        if (pm != null && pm.locality != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'address.city': pm.locality,
            'address.lat': pos.latitude,
            'address.lng': pos.longitude,
          });
            SnackbarHelper.success(context, 'Location updated to ${pm.locality}');
        } else {
          if (mounted) _promptForLocation(context, uid);
        }
      } else {
        if (mounted) _promptForLocation(context, uid);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _promptForLocation(context, uid);
      }
    }
  }

  void _promptForLocation(BuildContext context, String uid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBorder
                : AppColors.border,
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
              child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: AppDimensions.paddingMD),
            const Text('Set Your Location', style: AppTextStyles.headingLarge),
          ],
        ),
        content: const Text(
          'Please select your location on the map to find clients near you.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Later',
                  variant: ButtonVariant.ghost,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMD),
              Expanded(
                child: AppButton(
                  label: 'Choose on Map',
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final result = await context.pushNamed<dynamic>(RouteNames.mapPicker);
                    if (result != null && result is MapPickerResult) {
                      final pm = result.placemark;
                      if (pm.locality != null) {
                         FirebaseFirestore.instance.collection('users').doc(uid).update({
                          'address.city': pm.locality,
                          'address.lat': result.latitude,
                          'address.lng': result.longitude,
                        });
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

  void _showOTPDialog(
    BuildContext context,
    BookingModel booking,
  ) {
    final displayOtp =
        booking.otp ?? (booking.id.hashCode.abs() % 9000 + 1000).toString();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _OTPVerificationDialog(
        expectedOtp: displayOtp,
        onVerified: () => _updateBookingStatus(
          context,
          booking,
          BookingStatus.inProgress,
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
