import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../repositories/chat_repository.dart';

final chatListStreamProvider = StreamProvider.autoDispose<List<ChatModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return const Stream.empty();

  final field = user.role == UserRole.client ? 'clientId' : 'providerId';

  return FirebaseFirestore.instance
      .collection('chats')
      .where(field, isEqualTo: user.uid)
      .orderBy('lastMessageTime', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList());
});

final unreadChatsCountProvider = Provider.autoDispose<int>((ref) {
  final chatsAsync = ref.watch(chatListStreamProvider);
  final user = ref.watch(currentUserProvider).value;
  if (user == null || chatsAsync.value == null) return 0;
  
  int count = 0;
  for (var chat in chatsAsync.value!) {
    if (user.role == UserRole.client) {
      count += chat.clientUnread;
    } else {
      count += chat.providerUnread;
    }
  }
  return count;
});

final chatMessagesStreamProvider = StreamProvider.autoDispose.family<List<MessageModel>, String>((ref, chatId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getMessages(chatId);
});

final typingStatusStreamProvider = StreamProvider.autoDispose.family<bool, ({String chatId, String otherUserId})>((ref, args) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getTypingStatus(args.chatId, args.otherUserId);
});
