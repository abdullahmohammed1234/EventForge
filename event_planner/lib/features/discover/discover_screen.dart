import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../events/events_provider.dart';
// import 'widgets/discover_header.dart';
// import 'widgets/category_item.dart';
// import '../../core/config/app_config.dart';
import 'package:go_router/go_router.dart';
import '../events/events_feed_screen.dart';

/// Discover screen with custom header and event filtering
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  //int _selectedCategoryIndex = 0;

  // final List<CategoryData> _categories = const [
  //   CategoryData(label: 'All', icon: Icons.apps),
  //   CategoryData(label: 'Music', icon: Icons.music_note),
  //   CategoryData(label: 'Food', icon: Icons.restaurant),
  //   CategoryData(label: 'Sports', icon: Icons.sports_basketball),
  //   CategoryData(label: 'Arts', icon: Icons.palette),
  //   CategoryData(label: 'Tech', icon: Icons.computer),
  //   CategoryData(label: 'Social', icon: Icons.people),
  // ];

  @override
  void initState() {
    super.initState();
    // Fetch events when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().fetchEvents();
    });
  }

  // void _onCategorySelected(int index) {
  //   setState(() {
  //     _selectedCategoryIndex = index;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final cityFilter = uri.queryParameters['city'];
    final typeFilter = uri.queryParameters['type'];
    final categoryFilter = uri.queryParameters['category'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Custom Discover Header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      context.pop(); // go back
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      (cityFilter != null && cityFilter.isNotEmpty)
                          ? "Events in $cityFilter"
                          : typeFilter == 'popular'
                              ? (categoryFilter != null &&
                                      categoryFilter.isNotEmpty
                                  ? "Popular ${_capitalize(categoryFilter)} Events"
                                  : "Popular Events")
                              : "Discover Events",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Category List

          const SizedBox(height: 12),

          // Events List
          Expanded(
            child: _buildEventsList(cityFilter, typeFilter, categoryFilter),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(
    String? cityFilter,
    String? typeFilter,
    String? categoryFilter,
  ) {
    return Consumer<EventsProvider>(
      builder: (context, eventsProvider, child) {
        final allEvents = eventsProvider.events;

        // Start with all events
        List<Event> filtered = allEvents;

        // Filter by city
        if (cityFilter != null && cityFilter.isNotEmpty) {
          filtered = filtered.where((e) {
            return (e.city ?? '')
                .toLowerCase()
                .contains(cityFilter.toLowerCase());
          }).toList();
        }

        // Category filter
        if (categoryFilter != null && categoryFilter.isNotEmpty) {
          filtered =
              filtered.where((e) => e.category == categoryFilter).toList();
        }

        // Popular
        if (typeFilter == 'popular') {
          filtered = filtered;
        }

        // Loading state
        if (eventsProvider.isLoading && allEvents.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Empty state AFTER filtering
        if (filtered.isEmpty) {
          return Center(
            child: Text(
              'No events match your filters',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => eventsProvider.fetchEvents(refresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final event = filtered[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: EventCard(
                  event: event,
                  isHorizontal: false, // vertical card
                ),
              );
            },
          ),
        );
      },
    );
  }
}