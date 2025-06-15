import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import '../screens/chat/chat_detail_screen.dart';

class ChatStarterWidget extends StatelessWidget {
  final String itemId;
  final String itemTitle;
  final String itemOwnerId;
  final String itemOwnerName;
  final String? itemImageUrl;
  final Widget child;

  const ChatStarterWidget({
    super.key,
    required this.itemId,
    required this.itemTitle,
    required this.itemOwnerId,
    required this.itemOwnerName,
    this.itemImageUrl,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _startChat(context),
      child: child,
    );
  }

  Future<void> _startChat(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to start a chat')),
        );
        return;
      }

      // Don't allow user to chat with themselves
      if (currentUser.uid == itemOwnerId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot chat about your own item')),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final chatService = ChatService();

      // Create or get existing chat
      final chatId = await chatService.createOrGetChat(
        itemId: itemId,
        itemTitle: itemTitle,
        itemOwnerId: itemOwnerId,
        itemOwnerName: itemOwnerName,
        otherUserId: currentUser.uid,
        otherUserName: currentUser.displayName ?? 'Anonymous',
        itemImageUrl: itemImageUrl,
      );

      // TODO: Code about notification can go here

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);

        print('DEBUG: Navigating to chat with itemTitle: "$itemTitle"');

        // Navigate to chat - Fixed to use proper itemTitle instead of just 'itemTitle'
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatId: chatId,
              otherUserName: itemOwnerName,
              itemTitle: itemTitle, // This now properly passes the actual item title
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting chat: ${e.toString()}')),
        );
      }
    }
  }
}

// Helper method to add "Contact" button to post details
class ContactButton extends StatelessWidget {
  final String itemId;
  final String itemTitle;
  final String itemOwnerId;
  final String itemOwnerName;
  final String? itemImageUrl;

  const ContactButton({
    super.key,
    required this.itemId,
    required this.itemTitle,
    required this.itemOwnerId,
    required this.itemOwnerName,
    this.itemImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Don't show contact button for own items
    if (currentUser?.uid == itemOwnerId) {
      return const SizedBox.shrink();
    }

    return ChatStarterWidget(
      itemId: itemId,
      itemTitle: itemTitle,
      itemOwnerId: itemOwnerId,
      itemOwnerName: itemOwnerName,
      itemImageUrl: itemImageUrl,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Contact Owner',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}