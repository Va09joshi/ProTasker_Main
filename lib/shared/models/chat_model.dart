import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore path: chats/{chatId}

class ChatModel {
  final String id;
  final String clientId;
  final String clientName;
  final String? clientPhoto;
  final String providerId;
  final String providerName;
  final String? providerPhoto;
  final String bookingId;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int clientUnread;
  final int providerUnread;

  ChatModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientPhoto,
    required this.providerId,
    required this.providerName,
    this.providerPhoto,
    required this.bookingId,
    required this.lastMessage,
    required this.lastMessageTime,
    this.clientUnread = 0,
    this.providerUnread = 0,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};

    return ChatModel(
      id: doc.id,
      clientId: map['clientId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      clientPhoto: map['clientPhoto'] as String?,
      providerId: map['providerId'] as String? ?? '',
      providerName: map['providerName'] as String? ?? '',
      providerPhoto: map['providerPhoto'] as String?,
      bookingId: map['bookingId'] as String? ?? '',
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      clientUnread: map['clientUnread'] as int? ?? 0,
      providerUnread: map['providerUnread'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'clientPhoto': clientPhoto,
      'providerId': providerId,
      'providerName': providerName,
      'providerPhoto': providerPhoto,
      'bookingId': bookingId,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'clientUnread': clientUnread,
      'providerUnread': providerUnread,
    };
  }

  ChatModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientPhoto,
    String? providerId,
    String? providerName,
    String? providerPhoto,
    String? bookingId,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? clientUnread,
    int? providerUnread,
  }) {
    return ChatModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhoto: clientPhoto ?? this.clientPhoto,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerPhoto: providerPhoto ?? this.providerPhoto,
      bookingId: bookingId ?? this.bookingId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      clientUnread: clientUnread ?? this.clientUnread,
      providerUnread: providerUnread ?? this.providerUnread,
    );
  }
}
