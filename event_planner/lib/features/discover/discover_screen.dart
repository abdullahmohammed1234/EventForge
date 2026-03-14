import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../events/events_provider.dart';
import 'widgets/discover_header.dart';
import 'widgets/category_item.dart';

/// Discover screen with custom header and event filtering
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int _selectedCategoryIndex = 0;

  final List<CategoryData> _categories = const [
    CategoryData(label: 'All', icon: Icons.apps),
    CategoryData(label: 'Music', icon: Icons.music_note),
    CategoryData(label: 'Food', icon: Icons.restaurant),
    CategoryData(label: 'Sports', icon: Icons.sports_basketball),
    CategoryData(label: 'Arts', icon: Icons.palette),
    CategoryData(label: 'Tech', icon: Icons.computer),
    CategoryData(label: 'Social', icon: Icons.people),
  ];

  @override
  void initState() {
    super.initState();
    // Fetch events when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().fetchEvents();
    });
  }

  void _onCategorySelected(int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
    // TODO: Filter events based on selected category
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Custom Discover Header
          const DiscoverHeader(),
          const SizedBox(height: 12),
          // Category List
          const SizedBox(height: 12),
          CategoryList(
            categories: _categories,
            selectedIndex: _selectedCategoryIndex,
            onCategorySelected: _onCategorySelected,
          ),

          const SizedBox(height: 12),

          // Events List
          Expanded(
            child: _buildEventsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return Consumer<EventsProvider>(
      builder: (context, eventsProvider, child) {
        if (eventsProvider.isLoading && eventsProvider.events.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (eventsProvider.events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No events found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try changing your location or category',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => eventsProvider.fetchEvents(refresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: eventsProvider.events.length,
            itemBuilder: (context, index) {
              final event = eventsProvider.events[index];
              return ListTile(
                leading: event.coverImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          event.coverImageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: Colors.grey[200],
                            child: const Icon(Icons.event),
                          ),
                        ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.event),
                      ),
                title: Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  event.description ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  // Navigate to event details
                },
              );
            },
          ),
        );
      },
    );
  }
}
