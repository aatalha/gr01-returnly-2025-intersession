import 'package:flutter/material.dart';
import '../models/item_model.dart';

class SearchFilters extends StatelessWidget {
  final String? selectedCategory;
  final String? selectedLocation;
  final bool? selectedItemType;
  final DateTimeRange? selectedDateRange;
  final Function(String?) onCategoryChanged;
  final Function(String?) onLocationChanged;
  final Function(bool?) onItemTypeChanged;
  final Function(DateTimeRange?) onDateRangeChanged;
  final VoidCallback onClearFilters;

  const SearchFilters({
    super.key,
    this.selectedCategory,
    this.selectedLocation,
    this.selectedItemType,
    this.selectedDateRange,
    required this.onCategoryChanged,
    required this.onLocationChanged,
    required this.onItemTypeChanged,
    required this.onDateRangeChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onClearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Filter Chips
          Text(
            'Quick Filters',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Lost Items'),
                selected: selectedItemType == true,
                onSelected: (selected) => onItemTypeChanged(selected ? true : null),
                selectedColor: Colors.red.withOpacity(0.3),
              ),
              FilterChip(
                label: const Text('Found Items'),
                selected: selectedItemType == false,
                onSelected: (selected) => onItemTypeChanged(selected ? false : null),
                selectedColor: Colors.green.withOpacity(0.3),
              ),
              FilterChip(
                label: const Text('Documents'),
                selected: selectedCategory == ItemCategories.documents,
                onSelected: (selected) => onCategoryChanged(
                  selected ? ItemCategories.documents : null,
                ),
                selectedColor: Colors.orange.withOpacity(0.3),
              ),
              FilterChip(
                label: const Text('Electronics'),
                selected: selectedCategory == ItemCategories.electronics,
                onSelected: (selected) => onCategoryChanged(
                  selected ? ItemCategories.electronics : null,
                ),
                selectedColor: Colors.blue.withOpacity(0.3),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category Dropdown
          Text(
            'Category',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: selectedCategory,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'All Categories',
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Categories'),
              ),
              ...ItemCategories.allCategories.map((category) {
                return DropdownMenuItem<String?>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
            ],
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: 16),

          // Location Dropdown
          Text(
            'Location',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: selectedLocation,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'All Locations',
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Locations'),
              ),
              ...CampusLocations.allLocations.map((location) {
                return DropdownMenuItem<String?>(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
            ],
            onChanged: onLocationChanged,
          ),
          const SizedBox(height: 16),

          // Date Range Selector
          Text(
            'Date Range',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDateRange(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedDateRange == null
                          ? 'Select Date Range'
                          : '${_formatDate(selectedDateRange!.start)} - ${_formatDate(selectedDateRange!.end)}',
                      style: TextStyle(
                        color: selectedDateRange == null ? Colors.grey[600] : Colors.black,
                      ),
                    ),
                  ),
                  if (selectedDateRange != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => onDateRangeChanged(null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateRangeChanged(picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}