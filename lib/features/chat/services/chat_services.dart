import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<QuerySnapshot> getChatsStream() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: _auth.currentUser!.uid)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false) 
        .snapshots();
  }

  Future<void> sendMessage(String chatId, String messageText) async {
    final currentUser = _auth.currentUser!;
    final messageData = {
      'senderId': currentUser.uid,
      'text': messageText,
      'timestamp': Timestamp.now(),
    };

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': messageText,
      'lastMessageTimestamp': Timestamp.now(),
    });
  }

  Future<String> getOrCreateChatWithUser(String otherUserId, String otherUserName, String currentUserName) async {
    final currentUser = _auth.currentUser!;
    List<String> participants = [currentUser.uid, otherUserId];
    participants.sort();
    String chatId = participants.join('_');

    final chatDoc = _firestore.collection('chats').doc(chatId);
    final docSnapshot = await chatDoc.get();

    if (!docSnapshot.exists) {
      List<String> participantNames = [currentUserName, otherUserName];
      if (participants[0] != currentUser.uid) {
        participantNames = [otherUserName, currentUserName];
      }
      
      await chatDoc.set({
        'participants': participants,
        'participantNames': participantNames,
        'lastMessage': 'Chat started.',
        'lastMessageTimestamp': Timestamp.now(),
      });
    }
    return chatId;
  }
}