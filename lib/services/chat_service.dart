import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  CollectionReference get _chatsCollection => _firestore.collection('chats');
  CollectionReference get _messagesCollection => _firestore.collection('messages');

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Create or get existing chat for an item
  Future<String> createOrGetChat({
    required String itemId,
    required String itemTitle,
    required String itemOwnerId,
    required String itemOwnerName,
    required String otherUserId,
    required String otherUserName,
    String? itemImageUrl,
  }) async {
    try {
      final currentUserId = currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Create participant IDs list (sorted for consistency)
      final participantIds = [itemOwnerId, otherUserId];
      participantIds.sort();

      // Check if chat already exists for this item with these participants
      final existingChat = await _chatsCollection
          .where('itemId', isEqualTo: itemId)
          .where('participantIds', isEqualTo: participantIds)
          .limit(1)
          .get();

      if (existingChat.docs.isNotEmpty) {
        return existingChat.docs.first.id;
      }

      // Create new chat
      final participantNames = [itemOwnerName, otherUserName];
      if (participantIds[0] != itemOwnerId) {
        // If the first ID is not the item owner, swap names to match
        participantNames[0] = otherUserName;
        participantNames[1] = itemOwnerName;
      }

      final chatData = ChatConversation(
        id: '',
        itemId: itemId,
        itemTitle: itemTitle,
        itemImageUrl: itemImageUrl ?? '',
        participantIds: participantIds,
        participantNames: participantNames,
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        lastMessageSenderId: '',
        unreadCount: 0,
        createdAt: DateTime.now(),
        status: ChatStatus.active,
      );

      final docRef = await _chatsCollection.add(chatData.toFirestore());



      return docRef.id;
    } catch (e) {
      print('Error creating/getting chat: $e');
      rethrow;
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String message,
    MessageType type = MessageType.text,
    File? imageFile,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadChatImage(imageFile, chatId);
      }

      final chatMessage = ChatMessage(
        id: '',
        chatId: chatId,
        senderId: user.uid,
        senderName: user.displayName ?? 'Anonymous',
        senderEmail: user.email ?? '',
        message: message,
        timestamp: DateTime.now(),
        type: type,
        imageUrl: imageUrl,
      );

      // Add message to messages collection
      await _messagesCollection.add(chatMessage.toFirestore());

      // Update chat conversation with latest message info
      await _updateChatLastMessage(chatId, message, user.uid);

    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Upload chat image
  Future<String> _uploadChatImage(File imageFile, String chatId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('chat_images/$chatId/$fileName');

      final uploadTask = await storageRef.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading chat image: $e');
      rethrow;
    }
  }

  // Update chat with last message info
  Future<void> _updateChatLastMessage(String chatId, String message, String senderId) async {
    try {
      await _chatsCollection.doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': Timestamp.fromDate(DateTime.now()),
        'lastMessageSenderId': senderId,
      });
    } catch (e) {
      print('Error updating chat last message: $e');
    }
  }

  // Get messages stream for a chat
  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    return _messagesCollection
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessage.fromFirestore(doc);
      }).toList();
    });
  }

  // Get user's chat conversations
  Stream<List<ChatConversation>> getUserChatsStream() {
    final userId = currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _chatsCollection
        .where('participantIds', arrayContains: userId)
        .where('status', isEqualTo: ChatStatus.active.toString())
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatConversation.fromFirestore(doc);
      }).toList();
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return;

      // Get unread messages from other users
      final unreadMessages = await _messagesCollection
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Mark them as read
      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // Reset unread count in chat
      await _chatsCollection.doc(chatId).update({'unreadCount': 0});
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get unread messages count for user
  Stream<int> getUnreadMessagesCountStream() {
    final userId = currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return _chatsCollection
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      int totalUnread = 0;

      for (var doc in snapshot.docs) {
        final chat = ChatConversation.fromFirestore(doc);
        // Only count unread if the last message wasn't sent by current user
        if (chat.lastMessageSenderId != userId) {
          final unreadCount = await _getUnreadCountForChat(chat.id, userId);
          totalUnread += unreadCount;
        }
      }

      return totalUnread;
    });
  }

  // Get unread count for specific chat
  Future<int> _getUnreadCountForChat(String chatId, String userId) async {
    try {
      final unreadMessages = await _messagesCollection
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return unreadMessages.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Archive a chat
  Future<void> archiveChat(String chatId) async {
    try {
      await _chatsCollection.doc(chatId).update({
        'status': ChatStatus.archived.toString(),
      });
    } catch (e) {
      print('Error archiving chat: $e');
      rethrow;
    }
  }

  // Delete a chat (and all its messages)
  Future<void> deleteChat(String chatId) async {
    try {
      // Delete all messages in the chat
      final messages = await _messagesCollection
          .where('chatId', isEqualTo: chatId)
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }

      // Delete the chat conversation
      batch.delete(_chatsCollection.doc(chatId));

      await batch.commit();
    } catch (e) {
      print('Error deleting chat: $e');
      rethrow;
    }
  }

  // Get other participant's name in a chat
  String getOtherParticipantName(ChatConversation chat) {
    final currentUserId = currentUser?.uid;
    if (currentUserId == null) return 'Unknown';

    final currentUserIndex = chat.participantIds.indexOf(currentUserId);
    if (currentUserIndex == -1) return 'Unknown';

    // Return the other participant's name
    final otherIndex = currentUserIndex == 0 ? 1 : 0;
    return chat.participantNames.length > otherIndex
        ? chat.participantNames[otherIndex]
        : 'Unknown';
  }

  // Search chats
  Future<List<ChatConversation>> searchChats(String query) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return [];

      final chats = await _chatsCollection
          .where('participantIds', arrayContains: userId)
          .where('status', isEqualTo: ChatStatus.active.toString())
          .get();

      final searchResults = chats.docs
          .map((doc) => ChatConversation.fromFirestore(doc))
          .where((chat) {
        final lowercaseQuery = query.toLowerCase();
        return chat.itemTitle.toLowerCase().contains(lowercaseQuery) ||
            chat.participantNames.any((name) =>
                name.toLowerCase().contains(lowercaseQuery)) ||
            chat.lastMessage.toLowerCase().contains(lowercaseQuery);
      })
          .toList();

      return searchResults;
    } catch (e) {
      print('Error searching chats: $e');
      return [];
    }
  }
}