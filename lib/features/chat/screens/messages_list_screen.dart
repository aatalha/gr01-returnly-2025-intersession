import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:returnly/features/chat/models/chat_model.dart';
import 'package:returnly/features/chat/screens/chat_detail_screen.dart';
import 'package:returnly/features/chat/services/chat_services.dart';

class MessagesListScreen extends StatelessWidget {
  MessagesListScreen({Key? key}) : super(key: key);

  final ChatService _chatService = ChatService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Messages"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getChatsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "No conversations yet.\nStart a chat from an item's page!",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => Divider(height: 1, indent: 70),
            itemBuilder: (context, index) {
              final chatDoc = snapshot.data!.docs[index];
              final chat = ChatModel.fromFirestore(chatDoc, currentUserId);

              return ListTile(
                leading: CircleAvatar(
                  child: Icon(Icons.person_outline),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
                title: Text(chat.otherUserName, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  DateFormat.jm().format(chat.lastMessageTimestamp.toDate()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(
                        chatId: chat.id,
                        receiverName: chat.otherUserName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}