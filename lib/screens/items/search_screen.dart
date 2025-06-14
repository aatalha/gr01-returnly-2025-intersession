import 'package:flutter/material.dart';
import '../../models/item_model.dart';
import '../../services/item_service.dart';
import '../../widgets/item_card.dart';
import '../../widgets/custom_text_field.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ItemService _itemService = ItemService();

  List<ItemModel> _searchResults = [];
  bool _isLoading = false;

  // Filter variables - focus on functionality, not complex UI
  String? _selectedCategory;
  String? _selectedLocation;
  bool? _selectedItemType; // true for lost, false for found, null for all
  DateTimeRange? _selectedDateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Core search function - this is what teammates need
  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty && _selectedCategory == null &&
        _selectedLocation == null && _selectedItemType == null &&
        _selectedDateRange == null) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _itemService.searchItems(
        searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        category: _selectedCategory,
        location: _selectedLocation,
        isLost: _selectedItemType,
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: ${e.toString()}')),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedLocation = null;
      _selectedItemType = null;
      _selectedDateRange = null;
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Items'),
        actions: [
          // Simple clear button - teammates can style this better
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearFilters,
            tooltip: 'Clear all filters',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search input - basic styling, teammates can enhance
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomTextField(
              controller: _searchController,
              labelText: 'Search items...',
              prefixIcon: Icons.search,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _performSearch();
                },
              ),
              onChanged: (value) {
                // Debounce search - teammates can add more sophisticated debouncing
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _performSearch();
                  }
                });
              },
            ),
          ),

          // Basic filters - teammates can make this prettier
          _buildBasicFilters(),

          // Results section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? _buildEmptyState()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  // Simple filter UI - teammates can redesign this completely
  Widget _buildBasicFilters() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Category filter
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Categories')),
                ...ItemCategories.allCategories.map((category) =>
                    DropdownMenuItem(value: category, child: Text(category))),
              ],
              onChanged: (value) {
                setState(() => _selectedCategory = value);
                _performSearch();
              },
            ),

            const SizedBox(height: 8),

            // Location filter
            DropdownButtonFormField<String>(
              value: _selectedLocation,
              decoration: const InputDecoration(labelText: 'Location'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Locations')),
                ...CampusLocations.allLocations.map((location) =>
                    DropdownMenuItem(value: location, child: Text(location))),
              ],
              onChanged: (value) {
                setState(() => _selectedLocation = value);
                _performSearch();
              },
            ),

            const SizedBox(height: 8),

            // Item type filter - simple radio buttons
            const Text('Item Type:'),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool?>(
                    title: const Text('All'),
                    value: null,
                    groupValue: _selectedItemType,
                    onChanged: (value) {
                      setState(() => _selectedItemType = value);
                      _performSearch();
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool?>(
                    title: const Text('Lost'),
                    value: true,
                    groupValue: _selectedItemType,
                    onChanged: (value) {
                      setState(() => _selectedItemType = value);
                      _performSearch();
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool?>(
                    title: const Text('Found'),
                    value: false,
                    groupValue: _selectedItemType,
                    onChanged: (value) {
                      setState(() => _selectedItemType = value);
                      _performSearch();
                    },
                  ),
                ),
              ],
            ),

            // Date range - basic implementation
            ListTile(
              title: Text(_selectedDateRange == null
                  ? 'Select Date Range'
                  : 'From ${_selectedDateRange!.start.toString().split(' ')[0]} to ${_selectedDateRange!.end.toString().split(' ')[0]}'),
              trailing: const Icon(Icons.date_range),
              onTap: _selectDateRange,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() => _selectedDateRange = picked);
      _performSearch();
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No items found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        // TODO: Create ItemCard widget - teammates can design this
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: item.imageUrls.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrls.first,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_not_supported),
              ),
            )
                : const Icon(Icons.help_outline),
            title: Text(item.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  '${item.category} • ${item.location} • ${item.isLost ? "Lost" : "Found"}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: Chip(
              label: Text(item.isLost ? 'LOST' : 'FOUND'),
              backgroundColor: item.isLost ? Colors.red.shade100 : Colors.green.shade100,
            ),
            onTap: () {
              // TODO: Navigate to item detail - teammates can implement
              print('Navigate to item: ${item.id}');
            },
          ),
        );
      },
    );
  }
}