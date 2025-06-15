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
  final _descCtrl = TextEditingController();
  bool _loading = false;
  double _progress = 0.0;
  bool? _isLost;

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

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked != null) setState(() => _image = picked);
  }

  Future<void> _submit() async {
  if (_image == null ||
      _selectedCategory == null ||
      _selectedLocation == null ||
      _descCtrl.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all fields'))
    );
    return;
  }

  setState(() { _loading = true; _progress = 0.0; });

  try {
    final user = FirebaseAuth.instance.currentUser;
    final userName = (user?.displayName?.isNotEmpty == true)
    ? user!.displayName
    : (user?.email?.split('@').first ?? 'Anonymous');
    final file = File(_image!.path);
    final ref = FirebaseStorage.instance
        .ref('posts/${user?.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    // 1. Add metadata with content type
    final uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'), // ✅ Add this
    );
    // This single await replaces the snapshotEvents listener:
    final snapshot = await uploadTask.whenComplete(() {
      debugPrint('Upload complete');
    });


    final url = await snapshot.ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('posts').add({
      'imageUrl':    url,
      'category':    _selectedCategory,
      'location':    _selectedLocation,
      'isLost':      _isLost ?? true, 
      'userId':      user?.uid,
      'userName':    userName,
      'timestamp':   FieldValue.serverTimestamp(),
      'description': _descCtrl.text.trim(),
    });

     if (mounted) context.pop(); // go back to home
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
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),

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
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: _image == null
                ? const Icon(Icons.add_a_photo, size: 48, color: Colors.grey)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(_image!.path), fit: BoxFit.cover),
                  ),
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
            onChanged: (val) => setState(() => _selectedCategory = val),
          ),
          const SizedBox(height: 12),

          // Location dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Location',
              border: UnderlineInputBorder(),
            ),
            items: _locations.map((l) =>
              DropdownMenuItem(value: l, child: Text(l))
            ).toList(),
            value: _selectedLocation,
            onChanged: (val) => setState(() => _selectedLocation = val),
          ),
          const SizedBox(height: 20),
          // inside your Column, after Location dropdown
          const Text('Item status'),  
          Row(children: [
            Expanded(child: RadioListTile<bool>(
              title: const Text('Lost'),
              value: true, groupValue: _isLost,
              onChanged: (v) => setState(() => _isLost = v),
            )),
            Expanded(child: RadioListTile<bool>(
              title: const Text('Found'),
              value: false, groupValue: _isLost,
              onChanged: (v) => setState(() => _isLost = v),
            )),
          ]),

          // Description
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const Spacer(),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Post'),
            ),
          ),
        ]),
      ),
    );
  }
}
