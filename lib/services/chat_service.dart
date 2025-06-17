import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references - made public for chat list access
  CollectionReference get chatsCollection => _firestore.collection('chats');
  CollectionReference get messagesCollection => _firestore.collection('messages');

  // Keep private references for internal use
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
      // FIXED: Only try to upload image if imageFile is provided AND type is image
      if (imageFile != null && type == MessageType.image) {
        print('Uploading image...');
        imageUrl = await _uploadChatImage(imageFile, chatId);
        print('Image uploaded: $imageUrl');
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
        isRead: false, // Explicitly set to false for new messages
        imageUrl: imageUrl, // This will be null for text messages, which is fine
      );

      print('Sending message to Firestore...');

      // Use a batch to do both operations atomically (reduces rebuilds)
      final batch = _firestore.batch();

      // Add message to messages collection
      final messageRef = _messagesCollection.doc();
      batch.set(messageRef, chatMessage.toFirestore());

      // Update chat conversation with latest message info in the same batch
      final chatRef = _chatsCollection.doc(chatId);
      batch.update(chatRef, {
        'lastMessage': message.isEmpty ? 'Image' : message, // Show "Image" for image messages
        'lastMessageTime': Timestamp.fromDate(DateTime.now()),
        'lastMessageSenderId': user.uid,
      });

      // Execute both operations at once
      await batch.commit();

      print('Message sent and chat updated in single batch');

    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Upload chat image
  Future<String> _uploadChatImage(File imageFile, String chatId) async {
    try {
      print('Starting image upload for chat: $chatId');

      final fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('chat_images/$fileName');

      print('Uploading to path: chat_images/$fileName');

      // Add timeout and better error handling
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wait for upload with timeout
      final snapshot = await uploadTask.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          throw Exception('Upload timeout - please check your internet connection');
        },
      );

      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('Image upload completed: $downloadUrl');
      return downloadUrl;

    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  // Update chat with last message info and increment unread count
  Future<void> _updateChatLastMessage(String chatId, String message, String senderId) async {
    try {
      final updateData = {
        'lastMessage': message,
        'lastMessageTime': Timestamp.fromDate(DateTime.now()),
        'lastMessageSenderId': senderId,
      };

      await _chatsCollection.doc(chatId).update(updateData);

      // Reduced logging - only essential info
      print('Chat $chatId updated');
    } catch (e) {
      print('Error updating chat last message: $e');
      rethrow;
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

      // Get unread messages from other users in this specific chat
      final unreadMessages = await _messagesCollection
          .where('chatId', isEqualTo: chatId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isEmpty) {
        return; // No unread messages, don't do anything
      }

      // Mark them as read (only messages not sent by current user)
      final batch = _firestore.batch();
      int markedCount = 0;

      for (var doc in unreadMessages.docs) {
        final message = ChatMessage.fromFirestore(doc);
        if (message.senderId != userId) {
          batch.update(doc.reference, {'isRead': true});
          markedCount++;
        }
      }

      if (markedCount > 0) {
        await batch.commit();
        print('Marked $markedCount messages as read');

        // Reset unread count in chat
        await _chatsCollection.doc(chatId).update({'unreadCount': 0});
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // FIXED: Get unread messages count for user - using direct message stream for real-time updates
  Stream<int> getUnreadMessagesCountStream() {
    final userId = currentUser?.uid;
    if (userId == null) return Stream.value(0);

    // Listen directly to unread messages and filter by chat participation
    return _messagesCollection
        .where('isRead', isEqualTo: false)
        .snapshots()
        .asyncMap((snapshot) async {
      int totalUnread = 0;

      // Get user's active chats once
      final userChatsSnapshot = await _chatsCollection
          .where('participantIds', arrayContains: userId)
          .where('status', isEqualTo: ChatStatus.active.toString())
          .get();

      final userChatIds = userChatsSnapshot.docs.map((doc) => doc.id).toSet();

      // Count unread messages in user's chats that weren't sent by them
      for (var messageDoc in snapshot.docs) {
        final message = ChatMessage.fromFirestore(messageDoc);
        if (message.senderId != userId && userChatIds.contains(message.chatId)) {
          totalUnread++;
        }
      }

      print('Real-time unread count: $totalUnread');
      return totalUnread;
    });
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