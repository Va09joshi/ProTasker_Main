import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/role_guard.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/provider_jobs_providers.dart';
import 'proof_upload_bottom_sheet.dart';
import '../../../core/utils/snackbar_helper.dart';

class ProviderJobsScreen extends ConsumerStatefulWidget {
  const ProviderJobsScreen({super.key});

  @override
  ConsumerState<ProviderJobsScreen> createState() => _ProviderJobsScreenState();
}

class _ProviderJobsScreenState extends ConsumerState<ProviderJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(
    BuildContext context,
    BookingModel booking,
    BookingStatus newStatus, {
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

      String title = 'Booking Update';
      String body = 'Your booking for ${booking.serviceTitle} was updated.';

      if (newStatus == BookingStatus.accepted) {
        title = 'Booking Accepted';
        body = '${booking.providerName} accepted your booking.';
      } else if (newStatus == BookingStatus.rejected) {
        title = 'Booking Declined';
        body = '${booking.providerName} declined your booking.';
      } else if (newStatus == BookingStatus.onTheWay) {
        title = 'Provider On The Way';
        body = '${booking.providerName} is on the way to your location.';
      } else if (newStatus == BookingStatus.inProgress) {
        title = 'Job Started';
        body = '${booking.providerName} has started the job.';
      }

      await batch.commit();

      await NotificationService.sendNotification(
        targetUid: booking.clientId,
        title: title,
        body: body,
      );

      if (mounted) {
        SnackbarHelper.info(context, 'Status updated to ${newStatus.name}');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.error(context, 'Failed to update: $e');
      }
    }
  }

  void _showDeclineSheet(BuildContext context, BookingModel booking) {
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
              const Text('Decline Booking', style: AppTextStyles.headingLarge),
              const SizedBox(height: AppDimensions.paddingMD),
              Wrap(
                spacing: 8,
                children: ['Too far', 'Unavailable', 'Emergency']
                    .map(
                      (r) => ActionChip(
                        label: Text(r, style: AppTextStyles.labelLarge),
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                          color: AppColors.border,
                          width: AppDimensions.cardBorderWidth,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusPill,
                          ),
                        ),
                        onPressed: () => ctrl.text = r,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppDimensions.paddingLG),
              AppTextField(
                controller: ctrl,
                label: 'Other reason...',
                maxLines: 2,
              ),
              const SizedBox(height: AppDimensions.paddingLG),
              AppButton(
                label: 'Confirm Decline',
                variant: ButtonVariant.danger,
                onPressed: () {
                  if (ctrl.text.isNotEmpty) {
                    _updateStatus(
                      context,
                      booking,
                      BookingStatus.rejected,
                      reason: ctrl.text,
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

  void _showProviderCancelSheet(BuildContext context, BookingModel booking) {
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
                      reason: 'Provider Cancelled: ${ctrl.text}',
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

  Widget? _buildActionArea(BookingModel booking) {
    if (booking.status == BookingStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Decline',
              variant: ButtonVariant.danger,
              onPressed: () => _showDeclineSheet(context, booking),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMD),
          Expanded(
            child: AppButton(
              label: 'Accept',
              onPressed: () =>
                  _updateStatus(context, booking, BookingStatus.accepted),
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
              onPressed: () => _showProviderCancelSheet(context, booking),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMD),
          Expanded(
            child: AppButton(
              label: 'On My Way',
              onPressed: () =>
                  _updateStatus(context, booking, BookingStatus.onTheWay),
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
          onPressed: () =>
              _updateStatus(context, booking, BookingStatus.inProgress),
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

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RoleGuard.provider(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Manage Jobs'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: AppTextStyles.labelLarge,
            unselectedLabelStyle: AppTextStyles.labelLarge,
            tabs: const [
              Tab(text: 'Requests'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildStreamTab(
                providerRequestsStreamProvider,
                'No new requests.',
                Icons.notifications_none_rounded,
              ),
              _buildStreamTab(
                providerUpcomingStreamProvider,
                'No upcoming jobs.',
                Icons.calendar_month_rounded,
              ),
              _buildStreamTab(
                providerActiveStreamProvider,
                'No active jobs right now.',
                Icons.work_outline_rounded,
              ),
              _buildHistoryTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreamTab(
    StreamProvider<List<BookingModel>> provider,
    String emptyMsg,
    IconData icon,
  ) {
    final asyncData = ref.watch(provider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(provider);
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      child: asyncData.when(
        data: (bookings) {
          if (bookings.isEmpty) return _buildEmptyState(emptyMsg, icon);
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 600
                  ? 32.0
                  : AppDimensions.paddingLG,
              vertical: AppDimensions.paddingLG,
            ),
            itemCount: bookings.length,
            itemBuilder: (ctx, i) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.paddingLG),
              child: BookingCard(
                booking: bookings[i],
                viewerRole: UserRole.provider,
                onTap: () => context.push('/booking/${bookings[i].id}'),
                actionArea: _buildActionArea(bookings[i]),
              ),
            ),
          );
        },
        loading: () => const LoadingShimmer(type: ShimmerType.list),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.refresh(provider),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    final asyncData = ref.watch(providerHistoryProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(providerHistoryProvider);
        await ref.read(providerHistoryProvider.future);
      },
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      child: asyncData.when(
        data: (bookings) {
          if (bookings.isEmpty)
            return _buildEmptyState('No history yet.', Icons.history_rounded);
          return NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                  scrollInfo.metrics.maxScrollExtent) {
                ref.read(providerHistoryProvider.notifier).loadMore();
              }
              return false;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width > 600
                    ? 32.0
                    : AppDimensions.paddingLG,
                vertical: AppDimensions.paddingLG,
              ),
              itemCount: bookings.length + (asyncData.isLoading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i >= bookings.length)
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppDimensions.paddingSM),
                      child: CircularProgressIndicator(),
                    ),
                  );
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.paddingLG,
                  ),
                  child: BookingCard(
                    booking: bookings[i],
                    viewerRole: UserRole.provider,
                    onTap: () => context.push('/booking/${bookings[i].id}'),
                    actionArea: _buildActionArea(bookings[i]),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const LoadingShimmer(type: ShimmerType.list),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.refresh(providerHistoryProvider),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        EmptyState(icon: icon, title: 'No Jobs', subtitle: msg),
      ],
    );
  }
}
