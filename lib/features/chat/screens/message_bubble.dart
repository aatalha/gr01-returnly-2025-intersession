import 'package:flutter/material.dart';
import 'package:returnly/features/chat/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({Key? key, required this.message, required this.isMe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? theme.colorScheme.primary : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: isMe ? Radius.circular(16) : Radius.circular(4),
            bottomRight: isMe ? Radius.circular(4) : Radius.circular(16),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}