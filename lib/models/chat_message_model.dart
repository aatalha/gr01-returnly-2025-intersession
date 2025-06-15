import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String message;
  final DateTime timestamp;
  final MessageType type;
  final bool isRead;
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.imageUrl,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString(),
      'isRead': isRead,
      'imageUrl': imageUrl,
    };
  }

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatMessage(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderEmail: data['senderEmail'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: MessageType.values.firstWhere(
            (e) => e.toString() == data['type'],
        orElse: () => MessageType.text,
      ),
      isRead: data['isRead'] ?? false,
      imageUrl: data['imageUrl'],
    );
  }

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? message,
    DateTime? timestamp,
    MessageType? type,
    bool? isRead,
    String? imageUrl,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class ChatConversation {
  final String id;
  final String itemId;
  final String itemTitle;
  final String itemImageUrl;
  final List<String> participantIds;
  final List<String> participantNames;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final int unreadCount;
  final DateTime createdAt;
  final ChatStatus status;

  ChatConversation({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.itemImageUrl,
    required this.participantIds,
    required this.participantNames,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    required this.unreadCount,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'itemId': itemId,
      'itemTitle': itemTitle,
      'itemImageUrl': itemImageUrl,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.toString(),
    };
  }

  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatConversation(
      id: doc.id,
      itemId: data['itemId'] ?? '',
      itemTitle: data['itemTitle'] ?? '',
      itemImageUrl: data['itemImageUrl'] ?? '',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantNames: List<String>.from(data['participantNames'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      unreadCount: data['unreadCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: ChatStatus.values.firstWhere(
            (e) => e.toString() == data['status'],
        orElse: () => ChatStatus.active,
      ),
    );
  }

  ChatConversation copyWith({
    String? id,
    String? itemId,
    String? itemTitle,
    String? itemImageUrl,
    List<String>? participantIds,
    List<String>? participantNames,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    int? unreadCount,
    DateTime? createdAt,
    ChatStatus? status,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemTitle: itemTitle ?? this.itemTitle,
      itemImageUrl: itemImageUrl ?? this.itemImageUrl,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

enum MessageType {
  text,
  image,
  system, // For system messages like "Item claimed", "Meeting arranged", etc.
}

enum ChatStatus {
  active,
  archived,
  blocked,
}