import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/role_guard.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../../chat/repositories/chat_repository.dart';
import '../providers/booking_providers.dart';

class ClientBookingsScreen extends ConsumerStatefulWidget {
  const ClientBookingsScreen({super.key});

  @override
  ConsumerState<ClientBookingsScreen> createState() => _ClientBookingsScreenState();
}

class _ClientBookingsScreenState extends ConsumerState<ClientBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard.client(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('My Bookings'),
          backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: AppTextStyles.labelLarge,
            unselectedLabelStyle: AppTextStyles.labelLarge,
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildActiveTab(),
              _buildCompletedTab(),
              _buildCancelledTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTab() {
    final activeBookingsAsync = ref.watch(clientActiveBookingsStreamProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(clientActiveBookingsStreamProvider);
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      child: activeBookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) return _buildEmptyState('No active bookings right now.', Icons.calendar_month_rounded);
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : AppDimensions.paddingLG,
              vertical: AppDimensions.paddingLG,
            ),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.paddingLG),
                child: BookingCard(
                  booking: booking,
                  viewerRole: UserRole.client,
                  onTap: () => context.push('/booking/${booking.id}'),
                  actionArea: _buildClientActions(context, ref, booking),
                ),
              );
            },
          );
        },
        loading: () => const LoadingShimmer(type: ShimmerType.list),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(clientActiveBookingsStreamProvider)),
      ),
    );
  }

  Widget _buildCompletedTab() {
    final completedBookingsAsync = ref.watch(clientCompletedBookingsProvider);
    
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(clientCompletedBookingsProvider);
        await ref.read(clientCompletedBookingsProvider.future);
      },
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      child: completedBookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) return _buildEmptyState('You have no completed bookings.', Icons.check_circle_outline_rounded);
          return NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                ref.read(clientCompletedBookingsProvider.notifier).loadMore();
              }
              return false;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : AppDimensions.paddingLG,
                vertical: AppDimensions.paddingLG,
              ),
              itemCount: bookings.length + (completedBookingsAsync.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= bookings.length) {
                  return const Center(child: Padding(padding: EdgeInsets.all(AppDimensions.paddingSM), child: CircularProgressIndicator()));
                }
                final booking = bookings[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.paddingLG),
                  child: BookingCard(
                    booking: booking,
                    viewerRole: UserRole.client,
                    onTap: () => context.push('/booking/${booking.id}'),
                    actionArea: _buildClientActions(context, ref, booking),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const LoadingShimmer(type: ShimmerType.list),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(clientCompletedBookingsProvider)),
      ),
    );
  }

  Widget _buildCancelledTab() {
    final cancelledBookingsAsync = ref.watch(clientCancelledBookingsProvider);
    
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(clientCancelledBookingsProvider);
        await ref.read(clientCancelledBookingsProvider.future);
      },
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      child: cancelledBookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) return _buildEmptyState('No cancelled bookings.', Icons.cancel_outlined);
          return NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                ref.read(clientCancelledBookingsProvider.notifier).loadMore();
              }
              return false;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : AppDimensions.paddingLG,
                vertical: AppDimensions.paddingLG,
              ),
              itemCount: bookings.length + (cancelledBookingsAsync.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= bookings.length) {
                  return const Center(child: Padding(padding: EdgeInsets.all(AppDimensions.paddingSM), child: CircularProgressIndicator()));
                }
                final booking = bookings[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.paddingLG),
                  child: BookingCard(
                    booking: booking,
                    viewerRole: UserRole.client,
                    onTap: () => context.push('/booking/${booking.id}'),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const LoadingShimmer(type: ShimmerType.list),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(clientCancelledBookingsProvider)),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        EmptyState(
          icon: icon,
          title: 'No Bookings',
          subtitle: message,
        ),
      ],
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, BookingModel booking, BookingStatus newStatus, {String? reason}) async {
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

      final notifRef = db.collection('notifications').doc();
      final notification = NotificationModel(
        id: notifRef.id,
        userId: booking.providerId,
        title: 'Booking Cancelled',
        body: '${booking.clientName} cancelled the booking.',
        type: NotificationType.system,
        payload: {'bookingId': booking.id},
        isRead: false,
        createdAt: DateTime.now(),
      );
      batch.set(notifRef, notification.toMap());

      await batch.commit();
      
      if (mounted) SnackbarHelper.info(context, 'Booking cancelled successfully.');
    } catch (e) {
      if (mounted) SnackbarHelper.error(context, 'Failed to update: $e');
    }
  }

  void _showCancelSheet(BuildContext context, WidgetRef ref, BookingModel booking) {
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
                    _updateStatus(context, ref, booking, BookingStatus.cancelled, reason: 'Client Cancelled: ${ctrl.text}');
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

  Widget? _buildClientActions(BuildContext context, WidgetRef ref, BookingModel booking) {
    if (booking.status == BookingStatus.pending) {
      return SizedBox(
        width: double.infinity,
        child: AppButton(
          label: 'Cancel Booking',
          variant: ButtonVariant.danger,
          onPressed: () => _showCancelSheet(context, ref, booking),
        ),
      );
    }
    
    if (booking.status == BookingStatus.accepted) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'View Details',
                  variant: ButtonVariant.secondary,
                  onPressed: () => context.push('/booking/${booking.id}'),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMD),
              Expanded(
                child: AppButton(
                  label: 'Chat',
                  icon: Icons.chat_bubble_outline_rounded,
                  onPressed: () async {
                    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                    try {
                      final chatId = await ref.read(chatRepositoryProvider).getOrCreateChat(booking.clientId, booking.providerId, booking.serviceId);
                      if (context.mounted) Navigator.pop(context);
                      if (context.mounted) context.push('/chat/$chatId');
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        SnackbarHelper.error(context, 'Failed to start chat: $e');
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Cancel Booking',
              variant: ButtonVariant.danger,
              onPressed: () => _showCancelSheet(context, ref, booking),
            ),
          ),
        ],
      );
    }

    if (booking.status == BookingStatus.completed && !booking.clientReviewed) {
      return SizedBox(
        width: double.infinity,
        child: AppButton(
          label: 'Leave Review',
          icon: Icons.star_outline_rounded,
          onPressed: () => context.push('/review/${booking.id}'),
        ),
      );
    }

    return null;
  }
}
