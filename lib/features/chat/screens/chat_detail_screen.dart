import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:returnly/features/chat/models/message_model.dart';
import 'package:returnly/features/chat/screens/message_bubble.dart';
import 'package:returnly/features/chat/services/chat_services.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String receiverName;

  const ChatDetailScreen({
    Key? key,
    required this.chatId,
    required this.receiverName,
  }) : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      _chatService.sendMessage(widget.chatId, _messageController.text.trim());
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error occurred."));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(12),
                  children: snapshot.data!.docs.map((doc) {
                    final message = MessageModel.fromJson(doc.data() as Map<String, dynamic>);
                    return MessageBubble(
                      message: message,
                      isMe: message.senderId == _currentUserId,
                    );
                  }).toList(),
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  border: InputBorder.none,
                  filled: false,
                ),
                onSubmitted: (_) => _sendMessage(),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}