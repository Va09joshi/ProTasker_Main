import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/provider_dashboard_providers.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../../core/router/route_names.dart';

import '../../location/screens/map_picker_screen.dart';
import '../../../core/services/location_service.dart';

class ProviderDashboardScreen extends ConsumerStatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  ConsumerState<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends ConsumerState<ProviderDashboardScreen> {
  bool _hasCheckedLocation = false;

  Future<void> _updateBookingStatus(BuildContext context, String bookingId, BookingStatus status, {String? reason}) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (reason != null) updates['notes'] = reason;
      
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update(updates);
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
                    _updateBookingStatus(context, booking.id, BookingStatus.rejected, reason: ctrl.text);
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
                      _buildJobBoardBanner(context),
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
                    Icons.payments_rounded,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: AppDimensions.padding12),
                Expanded(
                  child: _buildStatCard(
                    'Jobs',
                    '${stats.weekJobs}',
                    Icons.work_rounded,
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
                    Icons.star_rounded,
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppDimensions.padding12),
                Expanded(
                  child: _buildStatCard(
                    'Completion',
                    '${stats.completionRate.toStringAsFixed(0)}%',
                    Icons.check_circle_rounded,
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

  Widget _buildStatCard(String label, String value, IconData icon, Color iconColor) {
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
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: AppDimensions.paddingLG),
          Text(value, style: AppTextStyles.displayMedium),
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildJobBoardBanner(BuildContext context) {
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
              padding: const EdgeInsets.all(AppDimensions.paddingSM),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.list_alt_rounded, color: AppColors.primary),
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
                  await _updateBookingStatus(context, b.id, BookingStatus.accepted);
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
                        onPressed: () => _updateBookingStatus(context, b.id, BookingStatus.accepted),
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
                      Text(booking.serviceTitle, style: AppTextStyles.headingLarge),
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
                          onPressed: () => _updateBookingStatus(context, booking.id, BookingStatus.completed),
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
}
