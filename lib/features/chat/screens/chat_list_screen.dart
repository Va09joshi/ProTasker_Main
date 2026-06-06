import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../providers/chat_providers.dart';
import '../../../shared/widgets/widgets.dart';
import '../../jobs/providers/job_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatListStreamProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User error'));

          return chatsAsync.when(
            data: (chats) {
              if (chats.isEmpty) {
                return const EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'No Messages',
                  subtitle: 'You have no active conversations.',
                );
              }

              return SafeArea(
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: chats.length,
                  padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingSM),
                  separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border, indent: 88),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return _ChatListItem(chat: chat, user: user);
                  },
                ),
              );
            },
            loading: () => const LoadingShimmer(type: ShimmerType.list),
            error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(chatListStreamProvider)),
          );
        },
        loading: () => const LoadingShimmer(type: ShimmerType.list),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(currentUserProvider)),
      ),
    );
  }
}

class _ChatListItem extends ConsumerWidget {
  final ChatModel chat;
  final UserModel user;

  const _ChatListItem({required this.chat, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isClient = user.role == UserRole.client;
    final otherName = isClient ? chat.providerName : chat.clientName;
    final otherPhoto = isClient ? chat.providerPhoto : chat.clientPhoto;
    final unreadCount = isClient ? chat.clientUnread : chat.providerUnread;
    final isUnread = unreadCount > 0;

    final jobAsync = ref.watch(jobDetailProvider(chat.bookingId));

    return InkWell(
      onTap: () {
        context.push('/chat/${chat.id}');
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : AppDimensions.paddingLG, 
          vertical: AppDimensions.paddingMD
        ),
        child: Row(
          children: [
            AppAvatar(name: otherName, imageUrl: otherPhoto, size: 56),
            const SizedBox(width: AppDimensions.paddingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          otherName, 
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat.jm().format(chat.lastMessageTime), 
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isUnread ? AppColors.accent : AppColors.textTertiary,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Job Title Row
                  jobAsync.when(
                    data: (job) => job != null ? Text(
                      'Regarding: ${job.title}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ) : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage, 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppDimensions.radiusPill)),
                          child: Text('$unreadCount', style: const TextStyle(color: AppColors.background, fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
