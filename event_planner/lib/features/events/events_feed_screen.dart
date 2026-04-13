import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'events_provider.dart';
import '../auth/auth_provider.dart';
import '../groups/your_groups_screen.dart';
import '../discover/widgets/discover_header.dart';
import '../discover/widgets/category_item.dart';
import '../../core/config/app_config.dart';

class EventsFeedScreen extends StatefulWidget {
  const EventsFeedScreen({super.key});

  @override
  State<EventsFeedScreen> createState() => _EventsFeedScreenState();
}

class _EventsFeedScreenState extends State<EventsFeedScreen> {
  final ScrollController _scrollController = ScrollController();

  // Track which view is selected: 0 = Discover, 1 = Your Groups, 2 = Hidden Gems, 3 = Underground
  int _selectedView = 0;

  //track which category is selected
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear any search state from previous searches before fetching events
      context.read<EventsProvider>().clearSearchState();
      context.read<EventsProvider>().fetchEvents(refresh: true);
    });
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (context.read<EventsProvider>().hasMore &&
          !context.read<EventsProvider>().isLoadingMore) {
        context.read<EventsProvider>().loadMoreEvents();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Custom Discover Header - replaces AppBar
          DiscoverHeader(
            selectedIndex: _selectedView,
            onDiscoverEventsTap: () {
              setState(() {
                _selectedView = 0;
              });
              context.read<EventsProvider>().fetchEvents(refresh: true);
            },
            onYourGroupsTap: () {
              setState(() {
                _selectedView = 1;
              });
            },
            onHiddenGemsTap: () {
              setState(() {
                _selectedView = 2;
              });
              context.read<EventsProvider>().fetchHiddenGems(refresh: true);
            },
            onUndergroundTap: () {
              setState(() {
                _selectedView = 3;
              });
              context.read<EventsProvider>().fetchUnderground(refresh: true);
            },
          ),
          const SizedBox(height: 12),
          if (_selectedView == 0) _buildCategoryBar(),
          if (_selectedView == 2 || _selectedView == 3) _buildNewFiltersBar(),

          // Content area - switch between views
          Expanded(
            child: _selectedView == 0
                ? _buildDiscoverEventsTab(eventsProvider)
                : _selectedView == 2
                    ? _buildHiddenGemsTab(eventsProvider)
                    : _selectedView == 3
                        ? _buildUndergroundTab(eventsProvider)
                        : _buildYourGroupsTab(),
          ),
        ],
),
    );
  }

  Widget _buildCategoryBar() {
    return CategoryList(
      categories: _categories,
      selectedIndex: _selectedCategoryIndex,
      onCategorySelected: (index) {
        setState(() {
          _selectedCategoryIndex = index;
        });

        final label = _categories[index].label;

        final category = label == 'All' ? null : label.toLowerCase();

        context.read<EventsProvider>().fetchEvents(
              refresh: true,
              category: category,
            );
      },
    );
  }

  Widget _buildNewFiltersBar() {
    final filters = [
      CategoryData(label: 'Small Events (<20)', icon: Icons.groups),
      CategoryData(label: 'Community', icon: Icons.people_outline),
      CategoryData(label: 'Free', icon: Icons.money_off),
    ];
    final labels = filters.map((f) => f.label).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final filter = filters[index];
            return CategoryItem(
              label: filter.label,
              icon: filter.icon,
              isSelected: false,
              onTap: () => _applyFilter(labels[index]),
            );
          },
        ),
      ),
    );
  }

  void _applyFilter(String filter) async {
    final provider = context.read<EventsProvider>();
    if (_selectedView == 2) {
      if (filter.contains('Small')) {
        await provider.fetchHiddenGems(refresh: true, maxAttendees: 20);
      } else if (filter.contains('Free')) {
        await provider.fetchHiddenGems(refresh: true, isFree: true);
      }
    } else if (_selectedView == 3) {
      await provider.fetchUnderground(refresh: true);
    }
  }

  Widget _buildDiscoverEventsTab(EventsProvider eventsProvider) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            // Clear search state on refresh to get all events
            context.read<EventsProvider>().clearSearchState();
            await context.read<EventsProvider>().fetchEvents(refresh: true);
          },
          child: eventsProvider.isLoading && eventsProvider.events.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : eventsProvider.events.isEmpty
                  ? ListView(
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy,
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
                                  'Be the first to create an event!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: eventsProvider.events.length +
                          (eventsProvider.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= eventsProvider.events.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final event = eventsProvider.events[index];
                        return EventCard(event: event);
                      },
                    ),
        ),
        // Floating Action Button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              context.go('/events/create');
            },
            label: const Text('Create Event'),
            icon: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildHiddenGemsTab(EventsProvider eventsProvider) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            await context.read<EventsProvider>().fetchHiddenGems(refresh: true);
          },
          child: eventsProvider.isLoading && eventsProvider.events.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : eventsProvider.events.isEmpty
                  ? ListView(
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.diamond_outlined, size: 80, color: Colors.amber[400]),
                                const SizedBox(height: 16),
                                Text('No hidden gems found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: eventsProvider.events.length + (eventsProvider.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= eventsProvider.events.length) {
                          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                        }
                        return EventCard(event: eventsProvider.events[index]);
                      },
                    ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => context.go('/events/create'),
            label: const Text('Create Event'),
            icon: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildUndergroundTab(EventsProvider eventsProvider) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            await context.read<EventsProvider>().fetchUnderground(refresh: true);
          },
          child: eventsProvider.isLoading && eventsProvider.events.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : eventsProvider.events.isEmpty
                  ? ListView(
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 80, color: Colors.purple[300]),
                                const SizedBox(height: 16),
                                Text('No underground events found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: eventsProvider.events.length + (eventsProvider.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= eventsProvider.events.length) {
                          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                        }
                        return EventCard(event: eventsProvider.events[index]);
                      },
                    ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => context.go('/events/create'),
            label: const Text('Create Event'),
            icon: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildYourGroupsTab() {
    return const YourGroupsScreen();
  }
}

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({
    super.key,
    required this.event,
  });

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d, yyyy • h:mm a').format(date);
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'music': Colors.purple,
      'sports': Colors.green,
      'arts': Colors.orange,
      'food': Colors.red,
      'technology': Colors.blue,
      'business': Colors.teal,
      'social': Colors.pink,
      'outdoor': Colors.lime,
      'other': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  Widget _buildCategoryBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getCategoryColor(event.category).withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(event.category),
            size: 16,
            color: _getCategoryColor(event.category),
          ),
          const SizedBox(width: 8),
          Text(
            event.category.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getCategoryColor(event.category),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBookmark(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final eventsProvider = context.read<EventsProvider>();

    if (!authProvider.isAuthenticated) {
      // Show login prompt
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Icon(Icons.login, size: 48, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'Sign in to save events',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'You need to be signed in to save events',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      }
      return;
    }

    // Toggle save/unsave
    if (event.isUserSaved) {
      await eventsProvider.unsaveEvent(event.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event removed from saved'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      await eventsProvider.saveEvent(event.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/events/${event.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: event.coverImageUrl != null
                      ? Image.network(
                          event.coverImageUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.image_not_supported, size: 40),
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 180,
                          color: Colors.grey[300],
                        ),
                ),

                // bookmark / like
                Positioned(
                  right: 10,
                  top: 10,
                  child: GestureDetector(
                    onTap: () => _toggleBookmark(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        event.isUserSaved
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: const Color(0xFFFE76B8),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // CONTENT
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // location + date
                  Text(
                    "${event.city} • ${_formatDate(event.startTime)}",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // creator
                  if (event.creatorName != null)
                    Text(
                      "By ${event.creatorName}",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),

                  const SizedBox(height: 10),

                  // bottom row (avatars + going)
                  Row(
                    children: [
                      // avatar image
                      Row(
                        children: List.generate(
                          3,
                          (index) => Container(
                            margin: const EdgeInsets.only(right: 4),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      Text(
                        "+ going",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),

                      const Spacer(),

                      Icon(
                        Icons.ios_share,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final icons = {
      'music': Icons.music_note,
      'sports': Icons.sports_baseball,
      'arts': Icons.palette,
      'food': Icons.restaurant,
      'technology': Icons.computer,
      'business': Icons.business,
      'social': Icons.groups,
      'outdoor': Icons.park,
      'other': Icons.event,
    };
    return icons[category] ?? Icons.event;
  }
}
