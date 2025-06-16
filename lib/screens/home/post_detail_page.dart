import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/chat_starter_widget.dart';
import 'edit_post_screen.dart';

class PostDetailSheet extends StatelessWidget {
  final Map<String, dynamic> post;
  final String postId;

  const PostDetailSheet({required this.post, required this.postId, super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == post['userId'];

    final imageUrl = post['imageUrl'] as String? ?? '';
    final title = post['title'] as String? ?? '';
    final desc = post['description'] as String? ?? '';
    final userName = post['userName'] as String? ?? '';
    final userId = post['userId'] as String? ?? '';
    final location = post['location'] as String? ?? '';
    final category = post['category'] as String? ?? '';
    final isHighPriority = post['isHighPriority'] == true;
    final status = post['status'] as String? ?? 'active';
    final timestamp = post['timestamp'];

    String formattedDate = '';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      formattedDate =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and edit button
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.isNotEmpty ? title : desc,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.pop(context); // Close current sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPostScreen(
                            post: post,
                            postId: postId,
                          ),
                        ),
                      );
                    },
                    tooltip: 'Edit Post',
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Status and Priority badges
            Row(
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'resolved' ? Colors.blue.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status == 'resolved' ? Icons.check_circle : Icons.search,
                        size: 16,
                        color: status == 'resolved' ? Colors.blue.shade800 : Colors.green.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status == 'resolved' ? 'RESOLVED' : 'ACTIVE',
                        style: TextStyle(
                          color: status == 'resolved' ? Colors.blue.shade800 : Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Priority Badge
                if (isHighPriority)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.priority_high, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'HIGH PRIORITY',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Image
            if (imageUrl.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(imageUrl, height: 180),
                ),
              ),

            const SizedBox(height: 12),

            // Category
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Description
            if (title.isNotEmpty && desc.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                ],
              ),

            // Location and other details
            _buildDetailRow('Location', location, Icons.location_on),
            _buildDetailRow('Posted by', userName, Icons.person),
            if (formattedDate.isNotEmpty)
              _buildDetailRow('Posted on', formattedDate, Icons.calendar_today),

            const SizedBox(height: 24),

            // Contact button (only show if not owner and status is active)
            if (!isOwner && status == 'active')
              ContactButton(
                itemId: postId,
                itemTitle: title.isNotEmpty ? title : desc,
                itemOwnerId: userId,
                itemOwnerName: userName,
                itemImageUrl: imageUrl,
              ),

            // Message for resolved items
            if (status == 'resolved')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.blue.shade600, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'This item has been successfully returned to its owner!',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            // Owner message
            if (isOwner)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info, color: Colors.green.shade600, size: 24),
                    const SizedBox(height: 8),
                    Text(
                      'This is your post. You can edit details or mark it as resolved when you return the item.',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),
            CommentsSection(postId: postId),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class CommentsSection extends StatefulWidget {
  final String postId;
  const CommentsSection({required this.postId, super.key});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text('Comments',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .doc(widget.postId)
                .collection('comments')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Text('No comments yet.');
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final c = docs[i].data() as Map<String, dynamic>;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.comment, size: 20),
                    title: Text(c['text'] ?? '',
                        style: const TextStyle(fontSize: 15)),
                    subtitle: Text(c['userName'] ?? ''),
                    trailing: Text(
                      (c['timestamp'] as Timestamp?)?.toDate().toLocal().toString().substring(0, 16) ?? '',
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Add a comment…',
                  isDense: true,
                ),
                minLines: 1,
                maxLines: 2,
              ),
            ),
            IconButton(
              icon: _isSending
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              onPressed: _isSending || _controller.text.trim().isEmpty
                  ? null
                  : () async {
                setState(() => _isSending = true);
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .add({
                    'text': _controller.text.trim(),
                    'userName': user?.displayName ?? 'Anonymous',
                    'timestamp': FieldValue.serverTimestamp(),
                    'userId': user?.uid,
                  });
                  _controller.clear();
                } finally {
                  if (mounted) {
                    setState(() => _isSending = false);
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}