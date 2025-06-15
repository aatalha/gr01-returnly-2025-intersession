import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/chat_message_model.dart';
import '../../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String itemTitle;
  final String? itemImageUrl;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    required this.itemTitle,
    this.itemImageUrl,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when screen loads
    _chatService.markMessagesAsRead(widget.chatId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage({File? imageFile}) async {
    final message = _messageController.text.trim();
    if (message.isEmpty && imageFile == null) return;

    setState(() => _isSending = true);

    try {
      await _chatService.sendMessage(
        chatId: widget.chatId,
        message: message,
        type: imageFile != null ? MessageType.image : MessageType.text,
        imageFile: imageFile,
      );

      _messageController.clear();

      // Scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        await _sendMessage(imageFile: File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String timeString = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    if (messageDate == today) {
      return timeString;
    } else if (messageDate == yesterday) {
      return 'Yesterday $timeString';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} $timeString';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [

            CircleAvatar(
              radius: 20,
              backgroundImage: widget.itemImageUrl?.isNotEmpty == true
                  ? NetworkImage(widget.itemImageUrl!)
                  : null,
              backgroundColor: Colors.grey.shade300,
              child: widget.itemImageUrl?.isEmpty != false
                  ? Icon(Icons.image, color: Colors.grey.shade600, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),

            // Item info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.itemTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'with ${widget.otherUserName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 😎,
                        Text(
                          'Start the conversation!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Auto-scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollToBottom();
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message.senderId == _chatService.currentUser?.uid;
                    final showTimestamp = index == 0 ||
                        messages[index - 1].timestamp.difference(message.timestamp).inMinutes.abs() > 5;

                    return Column(
                      children: [
                        if (showTimestamp)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 😎,
                            child: Text(
                              _formatMessageTime(message.timestamp),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        _buildMessageBubble(message, isCurrentUser),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Attach image button
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _isSending ? null : _pickAndSendImage,
                  ),

                  // Message input field
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),

                  const SizedBox(width: 😎,

                  // Send button
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _isSending ? null : () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isCurrentUser) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: message.type == MessageType.system
              ? Colors.grey.shade200
              : isCurrentUser
              ? Theme.of(context).primaryColor
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isCurrentUser ? const Radius.circular(4) : null,
            bottomLeft: !isCurrentUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show sender name for system messages or in group chats
            if (message.type == MessageType.system || !isCurrentUser)
              Text(
                message.type == MessageType.system
                    ? 'System'
                    : message.senderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: message.type == MessageType.system
                      ? Colors.grey.shade600
                      : isCurrentUser
                      ? Colors.white70
                      : Colors.grey.shade700,
                ),
              ),

            if (message.type == MessageType.system || !isCurrentUser)
              const SizedBox(height: 4),

            // Message content
            if (message.type == MessageType.image && message.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(😎,
                child: Image.network(
                  message.imageUrl!,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 150,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.error_outline, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),

            if (message.message.isNotEmpty)
              Text(
                message.message,
                style: TextStyle(
                  color: message.type == MessageType.system
                      ? Colors.grey.shade700
                      : isCurrentUser
                      ? Colors.white
                      : Colors.black87,
                  fontStyle: message.type == MessageType.system
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
          ],
        ),
      ),
    );
  }
}