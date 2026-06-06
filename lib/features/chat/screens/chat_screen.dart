import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../providers/chat_providers.dart';
import '../repositories/chat_repository.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/widgets.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late TextEditingController _msgCtrl;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _msgCtrl = TextEditingController();
    
    // Mark as read immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      ref.read(chatRepositoryProvider).markAsRead(widget.chatId, user.role);
    }
  }

  void _onTextChanged(String text) {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final isTypingNow = text.trim().isNotEmpty;
    if (_isTyping != isTypingNow) {
      _isTyping = isTypingNow;
      ref.read(chatRepositoryProvider).setTypingStatus(widget.chatId, user.uid, isTypingNow);
    }
  }

  Future<void> _sendMessage(UserModel user) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    _msgCtrl.clear();
    _onTextChanged(''); // clear typing indicator

    final msg = MessageModel(
      id: FirebaseFirestore.instance.collection('chats').doc().id, // temp id before save
      chatId: widget.chatId,
      senderId: user.uid,
      senderName: user.name,
      content: text,
      type: MessageType.text,
      timestamp: DateTime.now(),
    );

    await ref.read(chatRepositoryProvider).sendMessage(widget.chatId, msg);
  }

  Future<void> _pickAndSendImage(UserModel user) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;

    if (mounted) SnackbarHelper.info(context, 'Sending image...');
    await ref.read(chatRepositoryProvider).sendImage(widget.chatId, user.uid, user.name, File(file.path));
  }

  void _showImageDialog(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppDimensions.paddingSM),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 16, right: 16,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.background, size: 32),
                onPressed: () => Navigator.pop(ctx),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserAsync = ref.watch(currentUserProvider);
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.chatId));

    return currentUserAsync.when(
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: Text('User error')));

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).snapshots(),
          builder: (context, snapshot) {
            final chatData = snapshot.data?.data() as Map<String, dynamic>?;
            String otherName = 'Chat';
            String otherId = '';
            
            if (chatData != null) {
              final isClient = user.role == UserRole.client;
              otherName = isClient ? chatData['providerName'] : chatData['clientName'];
              otherId = isClient ? chatData['providerId'] : chatData['clientId'];
            }

            final isOtherTypingAsync = otherId.isNotEmpty 
              ? ref.watch(typingStatusStreamProvider((chatId: widget.chatId, otherUserId: otherId)))
              : const AsyncValue.data(false);

            return Scaffold(
              backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                scrolledUnderElevation: 0,
                elevation: 1,
                shadowColor: Colors.black.withValues(alpha: 0.1),
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        isDark ? AppColors.darkSurface : AppColors.surface,
                        isDark ? AppColors.darkSurface : AppColors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
                titleSpacing: 0,
                title: Row(
                  children: [
                    AppAvatar(
                      name: otherName, 
                      imageUrl: chatData?[user.role == UserRole.client ? 'providerPhoto' : 'clientPhoto'] as String?, 
                      size: 40
                    ),
                    const SizedBox(width: AppDimensions.paddingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            otherName, 
                            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isOtherTypingAsync.when(
                            data: (isTyping) => isTyping 
                              ? Text('typing...', style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent, fontStyle: FontStyle.italic))
                              : Row(
                                  children: [
                                    Container(
                                      width: 8, height: 8,
                                      decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 4),
                                    Text('Online', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                                  ],
                                ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.call_outlined),
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    onPressed: () => SnackbarHelper.info(context, 'Voice call coming soon'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.videocam_outlined),
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    onPressed: () => SnackbarHelper.info(context, 'Video call coming soon'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    onPressed: () {},
                  ),
                  const SizedBox(width: AppDimensions.paddingSM),
                ],
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: messagesAsync.when(
                        data: (messages) {
                          return ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD, vertical: AppDimensions.paddingLG),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              final isMe = msg.senderId == user.uid;

                              if (msg.type == MessageType.system) {
                                return _buildSystemMessage(msg);
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _buildMessageBubble(msg, isMe, isDark, chatData),
                              );
                            },
                          );
                        },
                        loading: () => const LoadingShimmer(type: ShimmerType.list),
                        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(chatMessagesStreamProvider(widget.chatId))),
                      ),
                    ),
                    _buildInputRow(user, isDark),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Scaffold(body: LoadingShimmer(type: ShimmerType.profile)),
      error: (e, _) => Scaffold(body: ErrorView(message: e.toString(), onRetry: () => ref.refresh(currentUserProvider))),
    );
  }

  Widget _buildSystemMessage(MessageModel msg) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMD),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD, vertical: AppDimensions.paddingSM),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt, 
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
        ),
        child: Text(msg.content, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe, bool isDark, Map<String, dynamic>? chatData) {
    String? senderPhoto;
    if (chatData != null) {
      senderPhoto = chatData[msg.senderId == chatData['clientId'] ? 'clientPhoto' : 'providerPhoto'];
    }

    final bubbleColor = isMe 
        ? AppColors.primary.withValues(alpha: 0.15) 
        : (isDark ? AppColors.darkSurface : AppColors.surface);
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[
          AppAvatar(name: msg.senderName, imageUrl: senderPhoto, size: 28),
          const SizedBox(width: 8),
        ],
        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            border: isMe ? null : Border.all(color: AppColors.border.withValues(alpha: 0.4), width: 1),
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (msg.type == MessageType.image && msg.imageUrl != null)
                GestureDetector(
                  onTap: () => _showImageDialog(msg.imageUrl!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(imageUrl: msg.imageUrl!, width: 220, height: 220, fit: BoxFit.cover),
                  ),
                ),
              if (msg.type == MessageType.text || (msg.type == MessageType.image && msg.imageUrl == null))
                Text(
                  msg.content, 
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textColor,
                    height: 1.3,
                  )
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    DateFormat.jm().format(msg.timestamp),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all_rounded, size: 14, color: AppColors.accent),
                  ]
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputRow(UserModel user, bool isDark) {
    return Container(
      padding: const EdgeInsets.only(
        left: AppDimensions.paddingSM,
        right: AppDimensions.paddingSM,
        top: 8,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          )
        ]
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.add_rounded, color: AppColors.textSecondary, size: 28),
              onPressed: () => _pickAndSendImage(user),
            ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      padding: const EdgeInsets.only(bottom: 8, left: 12),
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.emoji_emotions_outlined, color: AppColors.textTertiary, size: 24),
                      onPressed: () {},
                    ),
                    Expanded(
                      child: TextField(
                        controller: _msgCtrl,
                        onChanged: _onTextChanged,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                      ),
                    ),
                    IconButton(
                      padding: const EdgeInsets.only(bottom: 8, right: 12),
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.attach_file_rounded, color: AppColors.textTertiary, size: 22),
                      onPressed: () => _pickAndSendImage(user),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _msgCtrl,
                builder: (context, value, child) {
                  final hasText = value.text.trim().isNotEmpty;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: hasText ? AppColors.primary : (isDark ? AppColors.darkBackground : AppColors.background),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        if (hasText) {
                          _sendMessage(user);
                        } else {
                          SnackbarHelper.info(context, 'Voice messages coming soon');
                        }
                      },
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          hasText ? Icons.send_rounded : Icons.mic_none_rounded,
                          key: ValueKey<bool>(hasText),
                          color: hasText ? Colors.white : AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
