import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../items/search_screen.dart';

// -------------------- Post Model & Placeholder Firebase Logic -------------------------
class Post {
  final String imageUrl;
  final String title;
  final String author;
  final int comments;
  final String timestamp;

  Post({
    required this.imageUrl,
    required this.title,
    required this.author,
    required this.comments,
    required this.timestamp,
  });
}

Future<String> fetchUserProfileImageUrl() async {
  return 'https://picsum.photos/seed/626/600';
}

Future<List<Post>> fetchHighlightedPosts() async {
  return List.generate(
    3,
    (i) => Post(
      imageUrl: 'https://picsum.photos/seed/${i + 1}/600',
      title: 'Sample Title ${i + 1}',
      author: 'Author ${i + 1}',
      comments: (i + 1) * 5,
      timestamp: '${(i + 1) * 2}h',
    ),
  );
}

Future<List<Post>> fetchPopularPosts() async {
  return List.generate(
    3,
    (i) => Post(
      imageUrl: 'https://picsum.photos/seed/${i + 4}/600',
      title: 'Popular Title ${i + 1}',
      author: 'Author ${i + 1}',
      comments: (i + 1) * 3,
      timestamp: '${(i + 1) * 3}h',
    ),
  );
}

// -------------------- HomeScreen Navigation -------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const SearchTab(),
    const FavoritesTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// -------------------- HomeTab With Posts Layout -------------------------
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late TextEditingController _searchController;
  String _profileImageUrl = '';
  List<Post> _highlightedPosts = [];
  List<Post> _popularPosts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    _profileImageUrl = await fetchUserProfileImageUrl();
    _highlightedPosts = await fetchHighlightedPosts();
    _popularPosts = await fetchPopularPosts();
    setState(() {
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Hey ${user?.displayName ?? 'User'}',
          style: GoogleFonts.outfit(
            color: const Color(0xFF15161E),
            fontWeight: FontWeight.w500,
            fontSize: 24,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: NetworkImage(
              _profileImageUrl.isNotEmpty
                  ? _profileImageUrl
                  : 'https://via.placeholder.com/150',
            ),
            radius: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF15161E)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF15161E)),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  // Filter chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      children: ['For You', 'Tech', 'AI', 'News']
                          .map((label) => ChoiceChip(
                                label: Text(label),
                                selected: false,
                                onSelected: (_) {},
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Highlighted posts
                  SizedBox(
                    height: 260,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _highlightedPosts.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, i) =>
                          _buildHighlightedPostCard(_highlightedPosts[i]),
                    ),
                  ),
                  const Divider(),
                  // Popular posts
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Popular Today',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _popularPosts.length,
                    itemBuilder: (context, i) =>
                        _buildPopularPostCard(_popularPosts[i]),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHighlightedPostCard(Post post) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(post.imageUrl,
                width: double.infinity, height: 120, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(post.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularPostCard(Post post) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(post.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
      ),
      title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(post.author),
      trailing: Text(post.timestamp),
    );
  }
}

// -------------------- Other Tabs -------------------------
class SearchTab extends StatelessWidget {
  const SearchTab({super.key});
  @override
  Widget build(BuildContext context) => const SearchScreen();
}

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: const Center(child: Text('Favorites functionality - Coming soon')),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Text('Welcome, ${user?.displayName ?? 'User'}!'),
      );
  }
}
