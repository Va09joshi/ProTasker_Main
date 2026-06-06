import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/cloudinary_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/models.dart';

final chatRepositoryProvider = Provider((ref) => ChatRepository());

class ChatRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> getOrCreateChat(String clientId, String providerId, String bookingId) async {
    // Generate a single unique chat room per Client-Provider pair
    final chatId = '${clientId}_$providerId';
    final doc = await _db.collection('chats').doc(chatId).get();
    
    if (!doc.exists) {
      final clientDoc = await _db.collection('users').doc(clientId).get();
      final providerDoc = await _db.collection('users').doc(providerId).get();
      
      final chat = ChatModel(
        id: chatId,
        clientId: clientId,
        clientName: clientDoc.data()?['name'] ?? 'Client',
        clientPhoto: clientDoc.data()?['profilePhoto'],
        providerId: providerId,
        providerName: providerDoc.data()?['name'] ?? 'Provider',
        providerPhoto: providerDoc.data()?['profilePhoto'],
        bookingId: bookingId,
        lastMessage: 'Chat started',
        lastMessageTime: DateTime.now(),
      );
      
      await _db.collection('chats').doc(chatId).set(chat.toMap());
    }
    
    return chatId;
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList());
  }

  Future<void> sendMessage(String chatId, MessageModel message) async {
    final batch = _db.batch();
    
    final msgRef = _db.collection('chats').doc(chatId).collection('messages').doc(message.id);
    batch.set(msgRef, message.toMap());
    
    final chatRef = _db.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();
    
    if (chatDoc.exists) {
      final chat = ChatModel.fromFirestore(chatDoc);
      bool isClient = message.senderId == chat.clientId;
      
      batch.update(chatRef, {
        'lastMessage': message.type == MessageType.image ? '📸 Image' : message.content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        isClient ? 'providerUnread' : 'clientUnread': FieldValue.increment(1),
      });
    }

    await batch.commit();
  }

  Future<void> sendImage(String chatId, String senderId, String senderName, File image) async {
    final msgId = _db.collection('chats').doc(chatId).collection('messages').doc().id;
    final url = await CloudinaryService.uploadFile(image);
    if (url == null) throw Exception('Cloudinary upload failed');
    
    final message = MessageModel(
      id: msgId,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      content: '📸 Image attached',
      type: MessageType.image,
      imageUrl: url,
      timestamp: DateTime.now(),
    );
    
    await sendMessage(chatId, message);
  }

  Future<void> markAsRead(String chatId, UserRole readerRole) async {
    final field = readerRole == UserRole.client ? 'clientUnread' : 'providerUnread';
    await _db.collection('chats').doc(chatId).update({
      field: 0,
    });
  }

  Stream<bool> getTypingStatus(String chatId, String otherPartyId) {
    return _db.collection('chats').doc(chatId).collection('typing').doc(otherPartyId).snapshots().map((doc) {
      return doc.data()?['isTyping'] == true;
    });
  }

  Future<void> setTypingStatus(String chatId, String myUserId, bool isTyping) async {
    await _db.collection('chats').doc(chatId).collection('typing').doc(myUserId).set({
      'isTyping': isTyping,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
