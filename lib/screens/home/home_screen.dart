import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:returnly_app/screens/home/post_detail_page.dart';
import 'package:returnly_app/screens/home/edit_post_screen.dart';
import 'package:returnly_app/screens/profile/profile_screen.dart';
import 'package:returnly_app/screens/chat/chat_list_screen.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';

// Add this helper function to format the time difference
String formatTimeDifference(DateTime postTime) {
  final now = DateTime.now();
  final difference = now.difference(postTime);

  if (difference.inSeconds < 60) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hr ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
  } else if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return '$weeks week${weeks > 1 ? 's' : ''} ago';
  } else if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return '$months month${months > 1 ? 's' : ''} ago';
  } else {
    final years = (difference.inDays / 365).floor();
    return '$years year${years > 1 ? 's' : ''} ago';
  }
}

class HomeScreen extends StatefulWidget {
  final User? user;
  const HomeScreen({super.key, this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeTab(),
      const ChatTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<int>(
              stream: _chatService.getUnreadMessagesCountStream(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Stack(
                  children: [
                    const Icon(Icons.favorite),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Chat',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedLocation;
  String? _selectedStatus; // 'active', 'resolved', or null for all
  bool? _isHighPriority; // true for high priority only, null for all

  // Categories from your posts
  final List<String> _categories = [
    'Electronics', 'Books', 'Clothing', 'Documents', 'Accessories',
    'Jewelry', 'Water Bottle', 'Charger', 'Keys', 'Glasses', 'Others'
  ];

  // Locations from your posts
  final List<String> _locations = [
    'Science Building', 'Library Building', 'University Centre',
    'Engineering Building', 'Arts and Administration Building',
    'Residence Halls', 'Sports Complex', 'Cafeteria', 'Parking Lot',
    'Student Services', 'Computer Science Building', 'Other Location'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Search function triggered by Enter key
  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  // Filter posts based on search criteria
  List<DocumentSnapshot> _filterPosts(List<DocumentSnapshot> allPosts) {
    return allPosts.where((doc) {
      final post = doc.data()! as Map<String, dynamic>;

      // Search query filter - ONLY match title
      if (_searchQuery.isNotEmpty) {
        final title = (post['title'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();

        if (!title.contains(query)) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != null && post['category'] != _selectedCategory) {
        return false;
      }

      // Location filter
      if (_selectedLocation != null && post['location'] != _selectedLocation) {
        return false;
      }

      // Status filter
      if (_selectedStatus != null && post['status'] != _selectedStatus) {
        return false;
      }

      // Priority filter
      if (_isHighPriority == true && post['isHighPriority'] != true) {
        return false;
      }

      return true;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = null;
      _selectedLocation = null;
      _selectedStatus = null;
      _isHighPriority = null;
    });
  }

  // Helper function to get category icons
  Widget _getCategoryIcon(String category) {
    IconData iconData;
    Color iconColor = Colors.blue.shade600;

    switch (category.toLowerCase()) {
      case 'electronics':
        iconData = Icons.phone_android;
        iconColor = Colors.blue.shade600;
        break;
      case 'books':
        iconData = Icons.book;
        iconColor = Colors.brown.shade600;
        break;
      case 'clothing':
        iconData = Icons.checkroom;
        iconColor = Colors.purple.shade600;
        break;
      case 'documents':
        iconData = Icons.description;
        iconColor = Colors.orange.shade600;
        break;
      case 'accessories':
        iconData = Icons.watch;
        iconColor = Colors.green.shade600;
        break;
      case 'jewelry':
        iconData = Icons.diamond;
        iconColor = Colors.pink.shade600;
        break;
      case 'water bottle':
        iconData = Icons.local_drink;
        iconColor = Colors.cyan.shade600;
        break;
      case 'charger':
        iconData = Icons.battery_charging_full;
        iconColor = Colors.red.shade600;
        break;
      case 'keys':
        iconData = Icons.key;
        iconColor = Colors.amber.shade600;
        break;
      case 'glasses':
        iconData = Icons.visibility;
        iconColor = Colors.indigo.shade600;
        break;
      default:
        iconData = Icons.category;
        iconColor = Colors.grey.shade600;
    }

    return Icon(iconData, size: 20, color: iconColor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Returnly'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snap.data?.docs ?? [];
          if (allDocs.isEmpty) {
            return const Center(child: Text('No posts yet.'));
          }

          // Apply filters and sort
          final filteredDocs = _filterPosts(allDocs);

          // Sort to put high priority items at the top
          filteredDocs.sort((a, b) {
            final aPost = a.data()! as Map<String, dynamic>;
            final bPost = b.data()! as Map<String, dynamic>;

            final aIsHighPriority = aPost['isHighPriority'] == true;
            final bIsHighPriority = bPost['isHighPriority'] == true;

            // High priority items first
            if (aIsHighPriority && !bIsHighPriority) return -1;
            if (!aIsHighPriority && bIsHighPriority) return 1;

            // If same priority, sort by timestamp (newest first)
            final aTimestamp = aPost['timestamp'] as Timestamp?;
            final bTimestamp = bPost['timestamp'] as Timestamp?;

            if (aTimestamp != null && bTimestamp != null) {
              return bTimestamp.compareTo(aTimestamp);
            }

            return 0;
          });

          return Column(
            children: [
              // Search bar and filters
              Container(
                color: Colors.grey[50],
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search items... ',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onSubmitted: (value) {
                        _performSearch(); // Search when Enter is pressed
                      },
                      textInputAction: TextInputAction.search, // Shows search button on keyboard
                    ),

                    const SizedBox(height: 12),

                    // Important filter chips only (no category chips)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Priority filter chip
                          FilterChip(
                            label: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.priority_high, size: 16, color: Colors.orange),
                                SizedBox(width: 4),
                                Text('High Priority'),
                              ],
                            ),
                            selected: _isHighPriority == true,
                            onSelected: (selected) {
                              setState(() {
                                _isHighPriority = selected ? true : null;
                              });
                            },
                            selectedColor: Colors.orange.withOpacity(0.3),
                          ),
                          const SizedBox(width: 8),

                          // Status filter chips
                          FilterChip(
                            label: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search, size: 16, color: Colors.green),
                                SizedBox(width: 4),
                                Text('Active'),
                              ],
                            ),
                            selected: _selectedStatus == 'active',
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatus = selected ? 'active' : null;
                              });
                            },
                            selectedColor: Colors.green.withOpacity(0.3),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 16, color: Colors.blue),
                                SizedBox(width: 4),
                                Text('Resolved'),
                              ],
                            ),
                            selected: _selectedStatus == 'resolved',
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatus = selected ? 'resolved' : null;
                              });
                            },
                            selectedColor: Colors.blue.withOpacity(0.3),
                          ),
                          const SizedBox(width: 8),

                          // Clear filters button
                          if (_searchQuery.isNotEmpty ||
                              _selectedCategory != null ||
                              _selectedLocation != null ||
                              _selectedStatus != null ||
                              _isHighPriority != null)
                            TextButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.clear_all, size: 16),
                              label: const Text('Clear All'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Category dropdown - always visible
                    DropdownButtonFormField<String?>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Filter by Category',
                        hintText: 'What type of item are you looking for?',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ..._categories.map((category) {
                          return DropdownMenuItem<String?>(
                            value: category,
                            child: Row(
                              children: [
                                _getCategoryIcon(category),
                                const SizedBox(width: 8),
                                Text(category),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                      },
                    ),

                    const SizedBox(height: 8),

                    // Location dropdown - always visible
                    DropdownButtonFormField<String?>(
                      value: _selectedLocation,
                      decoration: InputDecoration(
                        labelText: 'Filter by Location',
                        hintText: 'Where did you lose your item?',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Locations'),
                        ),
                        ..._locations.map((location) {
                          return DropdownMenuItem<String?>(
                            value: location,
                            child: Text(location),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedLocation = value);
                      },
                    ),
                  ],
                ),
              ),

              // Results
              Expanded(
                child: filteredDocs.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No items found',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search or filters',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (ctx, i) {
                    final doc = filteredDocs[i];
                    final post = doc.data()! as Map<String, dynamic>;
                    final imageUrl = post['imageUrl'] as String? ?? '';
                    final location = post['location'] as String? ?? '';
                    final userName = post['userName'] as String? ?? '';
                    final timestamp = (post['timestamp'] as Timestamp?)?.toDate();
                    final title = post['title'] as String? ?? '';
                    final description = post['description'] as String? ?? '';
                    final category = post['category'] as String? ?? '';
                    final isHighPriority = post['isHighPriority'] == true;
                    final status = post['status'] as String? ?? 'active';

                    String timeAgo = '';
                    if (timestamp != null) {
                      timeAgo = formatTimeDifference(timestamp);
                    }

                    return InkWell(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (_) => FractionallySizedBox(
                          heightFactor: 0.9,
                          child: PostDetailSheet(post: post, postId: doc.id),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: isHighPriority
                              ? Border.all(color: Colors.orange, width: 2)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Post Image
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                imageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported),
                                  );
                                },
                              )
                                  : Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image, size: 32, color: Colors.grey[400]),
                                    const SizedBox(height: 4),
                                    Text(
                                      'No Image',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Post Details
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title and Priority/Status badges
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title.isNotEmpty ? title : description,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // High Priority Badge
                                        if (isHighPriority)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.priority_high, size: 12, color: Colors.white),
                                                SizedBox(width: 2),
                                                Text(
                                                  'URGENT',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                        const SizedBox(width: 4),

                                        // Status Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: status == 'resolved'
                                                ? Colors.blue.shade100
                                                : Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            status == 'resolved' ? 'RESOLVED' : 'ACTIVE',
                                            style: TextStyle(
                                              color: status == 'resolved'
                                                  ? Colors.blue.shade800
                                                  : Colors.green.shade800,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),

                                    // Category
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        category,
                                        style: TextStyle(
                                          color: Colors.blue.shade800,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    // Username (moved up)
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          userName.isNotEmpty ? userName : 'Anonymous',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          timeAgo,
                                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),

                                    // Description (moved down and improved styling)
                                    if (title.isNotEmpty && description.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Text(
                                          description,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                    const SizedBox(height: 6),

                                    // Location
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            location,
                                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/add_post'),
        tooltip: 'Add a Post',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// The Chat tab
class ChatTab extends StatelessWidget {
  const ChatTab({super.key});
  @override
  Widget build(BuildContext context) => const ChatListScreen();
}

/// The Profile tab
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) => const ProfileScreen();
}