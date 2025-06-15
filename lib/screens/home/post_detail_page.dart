import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostDetailSheet extends StatelessWidget {
  final Map<String, dynamic> post;
  final String postId;

  const PostDetailSheet({required this.post, required this.postId, super.key});

  @override
  Widget build(BuildContext context) {
    final imageUrl = post['imageUrl'] as String? ?? '';
    final title = post['title'] as String? ?? '';
    final desc = post['description'] as String? ?? '';
    final userName = post['userName'] as String? ?? '';
    final location = post['location'] as String? ?? '';
    final timestamp = post['timestamp'];
    final isLost = post['isLost'] ?? true;

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
            if (imageUrl.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(imageUrl, height: 180),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(isLost ? 'LOST' : 'FOUND'),
              backgroundColor:
                  isLost ? Colors.red.shade100 : Colors.green.shade100,
            ),
            const SizedBox(height: 8),
            Text(desc, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Location: $location'),
            Text('Posted by: $userName'),
            if (formattedDate.isNotEmpty) Text('Posted at: $formattedDate'),
            const SizedBox(height: 24),
            CommentsSection(postId: postId),
          ],
        ),
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
    _controller.addListener(_handleTextChanged); // Listen to text changes
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    setState(() {}); // Rebuild when text changes
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