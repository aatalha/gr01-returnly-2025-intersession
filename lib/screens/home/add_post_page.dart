import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class AddPostPage extends StatefulWidget {
  const AddPostPage({super.key});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final _picker = ImagePicker();
  XFile? _image;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;
  double _progress = 0.0;
  bool _isHighPriority = false;

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

  // High priority categories that auto-suggest high priority
  final List<String> _highPriorityCategories = [
    'Documents', 'Keys', 'Electronics' // Important items
  ];

  String? _selectedCategory;
  String? _selectedLocation;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked != null) setState(() => _image = picked);
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      _selectedCategory = category;
      // Auto-suggest high priority for important categories
      if (category != null && _highPriorityCategories.contains(category)) {
        _isHighPriority = true;
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedCategory == null ||
        _selectedLocation == null ||
        _titleCtrl.text.trim().isEmpty ||
        _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in title, description, category, and location'))
      );
      return;
    }

    setState(() { _loading = true; _progress = 0.0; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userName = (user?.displayName?.isNotEmpty == true)
          ? user!.displayName
          : (user?.email?.split('@').first ?? 'Anonymous');

      String imageUrl = '';

      // Only upload image if one is selected
      if (_image != null) {
        final file = File(_image!.path);
        final ref = FirebaseStorage.instance
            .ref('posts/${user?.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = ref.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        final snapshot = await uploadTask.whenComplete(() {
          debugPrint('Upload complete');
        });

        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('posts').add({
        'title':         _titleCtrl.text.trim(),
        'imageUrl':      imageUrl, // Will be empty string if no image
        'category':      _selectedCategory,
        'location':      _selectedLocation,
        'isHighPriority': _isHighPriority,
        'status':        'active',
        'userId':        user?.uid,
        'userName':      userName,
        'timestamp':     FieldValue.serverTimestamp(),
        'description':   _descCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isHighPriority
                ? 'High priority item posted! Users will be notified.'
                : 'Item posted successfully!'),
            backgroundColor: _isHighPriority ? Colors.orange : Colors.green,
          ),
        );
        context.pop(); // go back to home
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting: ${e.toString()}'))
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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
        title: const Text('Post Found Item'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop()
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          if (_loading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text('Uploading: ${(_progress * 100).toStringAsFixed(0)}%'),
          ] else ...[
            const SizedBox(height: 16),
          ],

          // Image picker
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: _image == null
                  ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Tap to add photo', style: TextStyle(color: Colors.grey)),
                ],
              )
                  : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(_image!.path), fit: BoxFit.cover),
              ),
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
              border: UnderlineInputBorder(),
            ),
            items: _categories.map((c) =>
                DropdownMenuItem(value: c, child: Text(c))
            ).toList(),
            value: _selectedCategory,
            onChanged: _onCategoryChanged,
          ),
          const SizedBox(height: 12),

          // Location dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Where did you find it?',
              border: UnderlineInputBorder(),
            ),
            items: _locations.map((l) =>
                DropdownMenuItem(value: l, child: Text(l))
            ).toList(),
            value: _selectedLocation,
            onChanged: (val) => setState(() => _selectedLocation = val),
          ),
          const SizedBox(height: 20),

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
                    ? '⚠️ Important item - users will be notified immediately'
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
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Additional details that might help identify the owner...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const Spacer(),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isHighPriority ? Colors.orange : null,
              ),
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_isHighPriority ? 'Post High Priority Item' : 'Post Found Item'),
            ),
          ),
        ]),
      ),
    );
  }
}