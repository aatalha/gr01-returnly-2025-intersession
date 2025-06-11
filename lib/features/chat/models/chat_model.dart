import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final Timestamp lastMessageTimestamp;
  final String otherUserName; 

  ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    required this.otherUserName,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc, String currentUserId) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<dynamic> participantUids = data['participants'];
    String otherUserName = "Chat User"; 
    int userIndex = participantUids.indexOf(currentUserId);
    if(data['participantNames'] != null && data['participantNames'].length == 2){
      otherUserName = data['participantNames'][userIndex == 0 ? 1 : 0];
    }
    
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants']),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTimestamp: data['lastMessageTimestamp'] ?? Timestamp.now(),
      otherUserName: otherUserName,
    );
  }
}