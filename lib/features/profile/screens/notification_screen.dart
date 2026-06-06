import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../../shared/widgets/widgets.dart';

final notificationsStreamProvider = StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
});

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  Future<void> _markAsRead(String id) async {
    await FirebaseFirestore.instance.collection('notifications').doc(id).update({'isRead': true});
  }

  Future<void> _markAllAsRead(String userId, List<NotificationModel> notifications) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var n in notifications.where((n) => !n.isRead)) {
      batch.update(FirebaseFirestore.instance.collection('notifications').doc(n.id), {'isRead': true});
    }
    await batch.commit();
  }

  void _handleTap(BuildContext context, NotificationModel n) {
    if (!n.isRead) _markAsRead(n.id);
    
    final payload = n.payload ?? {};
    final bookingId = payload['bookingId'];
    final chatId = payload['chatId'];

    if (n.type == NotificationType.newMessage && chatId != null) {
      context.push('/chat/$chatId');
    } else if (bookingId != null && (n.type == NotificationType.bookingRequest || n.type == NotificationType.bookingAccepted || n.type == NotificationType.bookingCompleted)) {
      context.push('/booking/$bookingId');
    }
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.bookingRequest: return Icons.event_available_rounded;
      case NotificationType.bookingAccepted: return Icons.check_circle_rounded;
      case NotificationType.bookingCompleted: return Icons.star_rounded;
      case NotificationType.newMessage: return Icons.chat_bubble_rounded;
      case NotificationType.system: return Icons.info_rounded;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.bookingRequest: return AppColors.primary;
      case NotificationType.bookingAccepted: return AppColors.success;
      case NotificationType.bookingCompleted: return AppColors.warning;
      case NotificationType.newMessage: return AppColors.accent;
      case NotificationType.system: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsStreamProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        actions: [
          userAsync.when(
            data: (user) => notifsAsync.when(
              data: (notifs) {
                final hasUnread = notifs.any((n) => !n.isRead);
                if (!hasUnread) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton.icon(
                    onPressed: () => _markAllAsRead(user!.uid, notifs),
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Mark all read'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notifsAsync.when(
        data: (notifs) {
          if (notifs.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No Notifications',
              subtitle: 'You\'re all caught up! Check back later for updates.',
            );
          }

          return SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.paddingMD),
              itemCount: notifs.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.paddingSM),
              itemBuilder: (context, index) {
                final n = notifs[index];
                return InkWell(
                  onTap: () => _handleTap(context, n),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingMD),
                    decoration: BoxDecoration(
                      color: n.isRead ? AppColors.surface : AppColors.accent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                      border: Border.all(
                        color: n.isRead ? AppColors.border : AppColors.accent.withValues(alpha: 0.3),
                        width: AppDimensions.cardBorderWidth,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getIconColor(n.type).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getIcon(n.type), color: _getIconColor(n.type), size: 24),
                        ),
                        const SizedBox(width: AppDimensions.paddingMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: AppTextStyles.labelLarge.copyWith(
                                        fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w700,
                                        color: n.isRead ? AppColors.textPrimary : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  if (!n.isRead) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                                    ),
                                  ]
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(n.body, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat.yMMMd().add_jm().format(n.createdAt),
                                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const LoadingShimmer(type: ShimmerType.list),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(notificationsStreamProvider)),
      ),
    );
  }
}
