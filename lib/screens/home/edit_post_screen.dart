import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class EditPostScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final String postId;

  const EditPostScreen({
    super.key,
    required this.post,
    required this.postId,
  });

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _picker = ImagePicker();
  XFile? _newImage;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;
  bool _isHighPriority = false;
  String _status = 'active';

  // Dropdown options
  final List<String> _categories = [
    'Electronics','Books','Clothing','Documents','Accessories',
    'Jewelry','Water Bottle','Charger','Keys','Glasses','Others'
  ];
  final List<String> _locations = [
    'Science Building','Library Building','University Centre',
    'Engineering Building','Arts and Administration Building',
    'Residence Halls','Sports Complex','Cafeteria','Parking Lot',
    'Student Services','Computer Science Building','Other Location'
  ];

  String? _selectedCategory;
  String? _selectedLocation;
  String _currentImageUrl = '';

  @override
  void initState() {
    super.initState();
    // Initialize with current post data
    _titleCtrl.text = widget.post['title'] ?? '';
    _descCtrl.text = widget.post['description'] ?? '';
    _selectedCategory = widget.post['category'];
    _selectedLocation = widget.post['location'];
    _isHighPriority = widget.post['isHighPriority'] == true;
    _status = widget.post['status'] ?? 'active';
    _currentImageUrl = widget.post['imageUrl'] ?? '';
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked != null) setState(() => _newImage = picked);
  }

  Future<String?> _uploadNewImage() async {
    if (_newImage == null) return null;

    try {
      final file = File(_newImage!.path);
      final ref = FirebaseStorage.instance
          .ref('posts/${widget.postId}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() {
        debugPrint('New image upload complete');
      });

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading new image: $e');
      return null;
    }
  }

  Future<void> _deleteOldImage() async {
    if (_currentImageUrl.isNotEmpty && _newImage != null) {
      try {
        await FirebaseStorage.instance.refFromURL(_currentImageUrl).delete();
        debugPrint('Old image deleted');
      } catch (e) {
        debugPrint('Error deleting old image: $e');
        // Continue even if deletion fails
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_selectedCategory == null ||
        _selectedLocation == null ||
        _titleCtrl.text.trim().isEmpty ||
        _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields'))
      );
      return;
    }

    setState(() => _loading = true);

    try {
      String imageUrl = _currentImageUrl;

      // Upload new image if selected
      if (_newImage != null) {
        final newImageUrl = await _uploadNewImage();
        if (newImageUrl != null) {
          await _deleteOldImage(); // Delete old image
          imageUrl = newImageUrl;
        }
      }

      // Update the post in Firestore
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _selectedCategory,
        'location': _selectedLocation,
        'isHighPriority': _isHighPriority,
        'status': _status,
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_status == 'resolved'
                ? 'Post marked as resolved! Great job helping someone.'
                : 'Post updated successfully!'),
            backgroundColor: _status == 'resolved' ? Colors.blue : Colors.green,
          ),
        );
        context.pop(); // Go back
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating post: ${e.toString()}'))
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _loading = true);

      try {
        // Delete image from storage
        if (_currentImageUrl.isNotEmpty) {
          await FirebaseStorage.instance.refFromURL(_currentImageUrl).delete();
        }

        // Delete post from Firestore
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
          context.pop(); // Go back
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting post: ${e.toString()}'))
        );
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _loading ? null : _deletePost,
            tooltip: 'Delete Post',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
              ],

              // Current/New Image
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  child: _newImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(_newImage!.path), fit: BoxFit.cover),
                  )
                      : _currentImageUrl.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(_currentImageUrl, fit: BoxFit.cover),
                  )
                      : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Tap to change photo', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),

              if (_newImage != null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '📷 New image selected',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),

              const SizedBox(height: 16),

              // Title field
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Item Title',
                  hintText: 'e.g., Black iPhone 13, Blue Backpack',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),

              // Category dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((c) =>
                    DropdownMenuItem(value: c, child: Text(c))
                ).toList(),
                value: _selectedCategory,
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 12),

              // Location dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                items: _locations.map((l) =>
                    DropdownMenuItem(value: l, child: Text(l))
                ).toList(),
                value: _selectedLocation,
                onChanged: (val) => setState(() => _selectedLocation = val),
              ),
              const SizedBox(height: 16),

              // Status Selection
              const Text(
                'Post Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Active'),
                      subtitle: const Text('Still looking for the owner'),
                      value: 'active',
                      groupValue: _status,
                      onChanged: (value) => setState(() => _status = value!),
                      secondary: const Icon(Icons.search, color: Colors.green),
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: const Text('Resolved'),
                      subtitle: const Text('Item has been returned to owner'),
                      value: 'resolved',
                      groupValue: _status,
                      onChanged: (value) => setState(() => _status = value!),
                      secondary: const Icon(Icons.check_circle, color: Colors.blue),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // High Priority Toggle
              Container(
                decoration: BoxDecoration(
                  color: _isHighPriority ? Colors.orange.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isHighPriority ? Colors.orange.shade200 : Colors.grey.shade300,
                  ),
                ),
                child: SwitchListTile(
                  title: const Text('High Priority Item'),
                  subtitle: Text(
                    _isHighPriority
                        ? '⚠️ Important item - users are notified immediately'
                        : 'Mark as high priority for important items (ID, keys, wallet, etc.)',
                    style: TextStyle(
                      color: _isHighPriority ? Colors.orange.shade700 : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  value: _isHighPriority,
                  onChanged: (value) => setState(() => _isHighPriority = value),
                  activeColor: Colors.orange,
                ),
              ),

              const SizedBox(height: 16),

              // Description
              TextField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Additional details that might help identify the owner...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _status == 'resolved' ? Colors.blue :
                    _isHighPriority ? Colors.orange : null,
                  ),
                  onPressed: _loading ? null : _saveChanges,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_status == 'resolved'
                      ? 'Mark as Resolved ✓'
                      : 'Save Changes'),
                ),
              ),

              const SizedBox(height: 16),

              // Post Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Post Information',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Posted by: ${widget.post['userName'] ?? 'Anonymous'}'),
                    if (widget.post['timestamp'] != null)
                      Text('Created: ${_formatDate((widget.post['timestamp'] as Timestamp).toDate())}'),
                    if (widget.post['updatedAt'] != null)
                      Text('Last updated: ${_formatDate((widget.post['updatedAt'] as Timestamp).toDate())}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}