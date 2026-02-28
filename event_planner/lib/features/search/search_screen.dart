import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../events/events_provider.dart';
import '../events/events_feed_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';

  final List<String> _categories = [
    'all',
    'music',
    'sports',
    'arts',
    'food',
    'technology',
    'business',
    'social',
    'outdoor',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().fetchEvents(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    final eventsProvider = context.read<EventsProvider>();
    final category = _selectedCategory == 'all' ? null : _selectedCategory;
    
    if (query.isNotEmpty) {
      // Search by name - now also searches city in the backend
      eventsProvider.searchEvents(query, category: category);
    } else {
      eventsProvider.fetchEvents(refresh: true);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<EventsProvider>().fetchEvents(refresh: true);
  }

  void _onCategorySelected(String category) {
    final eventsProvider = context.read<EventsProvider>();
    setState(() {
      _selectedCategory = category;
    });
    
    final query = _searchController.text.trim();
    final cat = category == 'all' ? null : category;
    
    if (query.isNotEmpty) {
      eventsProvider.searchEvents(query, category: cat);
    } else if (cat != null) {
      eventsProvider.filterByCategory(cat);
    } else {
      eventsProvider.fetchEvents(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Events'),
      ),
      body: Column(
        children: [
          // Single Search TextField
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events by name or location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          // Search Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _performSearch,
                icon: const Icon(Icons.search),
                label: const Text('Search'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Category Filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(
                      category == 'all' ? 'All' : category[0].toUpperCase() + category.substring(1),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      _onCategorySelected(category);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Search Results
          Expanded(
            child: eventsProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : eventsProvider.events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No events found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try a different search term',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: eventsProvider.events.length,
                        itemBuilder: (context, index) {
                          final event = eventsProvider.events[index];
                          return EventCard(event: event);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
