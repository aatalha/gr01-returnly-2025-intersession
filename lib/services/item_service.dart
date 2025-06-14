import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';

class ItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _itemsCollection => _firestore.collection('items');

  // Create a new item post
  Future<String?> createItem({
    required String title,
    required String description,
    required String category,
    required List<String> tags,
    required String location,
    required bool isLost,
    required List<File> imageFiles,
    PriorityLevel priority = PriorityLevel.normal,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload images first
      List<String> imageUrls = [];
      if (imageFiles.isNotEmpty) {
        imageUrls = await _uploadImages(imageFiles);
      }

      // Set priority to high for documents
      final itemPriority = category == ItemCategories.documents
          ? PriorityLevel.high
          : priority;

      // Create item model
      final now = DateTime.now();
      final item = ItemModel(
        id: '', // Will be set by Firestore
        title: title,
        description: description,
        category: category,
        tags: tags,
        location: location,
        imageUrls: imageUrls,
        isLost: isLost,
        userId: user.uid,
        userEmail: user.email ?? '',
        userDisplayName: user.displayName ?? 'Anonymous',
        createdAt: now,
        updatedAt: now,
        status: ItemStatus.active,
        priority: itemPriority,
      );

      // Save to Firestore
      final docRef = await _itemsCollection.add(item.toFirestore());

      print('Item created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating item: $e');
      rethrow;
    }
  }

  // Upload images to Firebase Storage
  Future<List<String>> _uploadImages(List<File> imageFiles) async {
    List<String> imageUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final file = imageFiles[i];
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final storageRef = _storage.ref().child('item_images/$fileName');

        final uploadTask = await storageRef.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        imageUrls.add(downloadUrl);

        print('Image uploaded: $downloadUrl');
      } catch (e) {
        print('Error uploading image $i: $e');
        // Continue with other images even if one fails
      }
    }

    return imageUrls;
  }

  // Get all items (for home screen display)
  Stream<List<ItemModel>> getAllItems() {
    return _itemsCollection
        .where('status', isEqualTo: ItemStatus.active.toString())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ItemModel.fromFirestore(doc);
      }).toList();
    });
  }

  // Get items by type (lost or found)
  Stream<List<ItemModel>> getItemsByType(bool isLost) {
    return _itemsCollection
        .where('isLost', isEqualTo: isLost)
        .where('status', isEqualTo: ItemStatus.active.toString())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ItemModel.fromFirestore(doc);
      }).toList();
    });
  }

  // Get user's own items
  Stream<List<ItemModel>> getUserItems() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _itemsCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ItemModel.fromFirestore(doc);
      }).toList();
    });
  }

  // Search items with filters
  Future<List<ItemModel>> searchItems({
    String? searchQuery,
    String? category,
    String? location,
    bool? isLost,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _itemsCollection.where('status', isEqualTo: ItemStatus.active.toString());

      // Add filters
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }

      if (isLost != null) {
        query = query.where('isLost', isEqualTo: isLost);
      }

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      List<ItemModel> items = snapshot.docs.map((doc) {
        return ItemModel.fromFirestore(doc);
      }).toList();

      // Filter by search query (client-side for flexibility)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowercaseQuery = searchQuery.toLowerCase();
        items = items.where((item) {
          return item.title.toLowerCase().contains(lowercaseQuery) ||
              item.description.toLowerCase().contains(lowercaseQuery) ||
              item.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
        }).toList();
      }

      return items;
    } catch (e) {
      print('Error searching items: $e');
      rethrow;
    }
  }

  // Get high priority items (for alerts)
  Stream<List<ItemModel>> getHighPriorityItems() {
    return _itemsCollection
        .where('priority', isEqualTo: PriorityLevel.high.toString())
        .where('status', isEqualTo: ItemStatus.active.toString())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ItemModel.fromFirestore(doc);
      }).toList();
    });
  }

  // Update item status
  Future<void> updateItemStatus(String itemId, ItemStatus status, {String? claimedByUserId}) async {
    try {
      final updateData = {
        'status': status.toString(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (claimedByUserId != null) {
        updateData['claimedByUserId'] = claimedByUserId;
        updateData['claimedAt'] = Timestamp.fromDate(DateTime.now());
      }

      await _itemsCollection.doc(itemId).update(updateData);
      print('Item status updated successfully');
    } catch (e) {
      print('Error updating item status: $e');
      rethrow;
    }
  }

  // Update item details
  Future<void> updateItem(String itemId, ItemModel updatedItem) async {
    try {
      await _itemsCollection.doc(itemId).update(updatedItem.toFirestore());
      print('Item updated successfully');
    } catch (e) {
      print('Error updating item: $e');
      rethrow;
    }
  }

  // Delete item
  Future<void> deleteItem(String itemId) async {
    try {
      // Get item to delete associated images
      final doc = await _itemsCollection.doc(itemId).get();
      if (doc.exists) {
        final item = ItemModel.fromFirestore(doc);

        // Delete images from storage
        for (String imageUrl in item.imageUrls) {
          try {
            await _storage.refFromURL(imageUrl).delete();
          } catch (e) {
            print('Error deleting image: $e');
            // Continue even if image deletion fails
          }
        }
      }

      // Delete document
      await _itemsCollection.doc(itemId).delete();
      print('Item deleted successfully');
    } catch (e) {
      print('Error deleting item: $e');
      rethrow;
    }
  }

  // Get item by ID
  Future<ItemModel?> getItemById(String itemId) async {
    try {
      final doc = await _itemsCollection.doc(itemId).get();
      if (doc.exists) {
        return ItemModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting item: $e');
      return null;
    }
  }

  // Get items by category
  Stream<List<ItemModel>> getItemsByCategory(String category) {
    return _itemsCollection
        .where('category', isEqualTo: category)
        .where('status', isEqualTo: ItemStatus.active.toString())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ItemModel.fromFirestore(doc);
      }).toList();
    });
  }

  // Get items by location
  Stream<List<ItemModel>> getItemsByLocation(String location) {
    return _itemsCollection
        .where('location', isEqualTo: location)
        .where('status', isEqualTo: ItemStatus.active.toString())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ItemModel.fromFirestore(doc);
      }).toList();
    });
  }
}