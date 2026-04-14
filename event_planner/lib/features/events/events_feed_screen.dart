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

String _selectedCity = "Surrey";

final List<String> _cities = [
  "Coquitlam",
  "Surrey",
  "Richmond",
  "Vancouver",
  "Burnaby",
];

String _getDaysRemaining(DateTime date) {
  final diff = date.difference(DateTime.now()).inDays;

  if (diff <= 0) return "Today";
  if (diff == 1) return "Tomorrow";
  return "in $diff days";
}

String _getCleanLocation(Event event) {
  final street = event.address ?? '';
  final place = event.location?.name ?? '';
  final city = event.city ?? '';

  // Priority: street > place > city
  if (street.isNotEmpty && city.isNotEmpty) {
    return "$street, $city";
  }

  if (place.isNotEmpty && place != city) {
    return "$place, $city";
  }

  return city;
}

class EventsFeedScreen extends StatefulWidget {
  const EventsFeedScreen({super.key});

  @override
  State<EventsFeedScreen> createState() => _EventsFeedScreenState();
}

class _EventsFeedScreenState extends State<EventsFeedScreen> {
  // Track which view is selected: 0 = Discover Events, 1 = Your Groups
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

  List<Event> _getFilteredHotEvents(List<Event> events) {
    if (_selectedCategoryIndex == 0) return events;

    final selected = _categories[_selectedCategoryIndex].label.toLowerCase();

    return events.where((e) => e.category == selected).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear any search state from previous searches before fetching events
      context.read<EventsProvider>().clearSearchState();
      context.read<EventsProvider>().fetchEvents(refresh: true);
    });
  }

  @override
  void dispose() {
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
            },
            onYourGroupsTap: () {
              setState(() {
                _selectedView = 1;
              });
            },
          ),
          const SizedBox(height: 12),
          //if (_selectedView == 0) _buildCategoryBar(),

          // Content area - switch between views
          Expanded(
            child: _selectedView == 0
                ? _buildDiscoverEventsTab(eventsProvider)
                : _buildYourGroupsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildYourGroupsTab() {
    return const YourGroupsScreen();
  }

  Widget _buildCategoryBar() {
    return CategoryList(
      categories: _categories,
      selectedIndex: _selectedCategoryIndex,
      onCategorySelected: (index) {
        setState(() {
          _selectedCategoryIndex = index;
        });
      },
    );
  }

  Widget _buildUpcomingEvent(List<Event> events) {
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    final event = events.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.push('/events/${event.id}'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFE76B8)),
            color: Colors.white,
          ),
          child: Row(
            children: [
              /// IMAGE
              Expanded(
                flex: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    event.coverImageUrl ?? '',
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              /// TEXT CONTENT
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// PINK
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getDaysRemaining(event.startTime),
                        style: const TextStyle(
                          color: Color(0xFFFE76B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// TITLE
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// DATE
                    Text(
                      DateFormat('EEE, MMM d • h:mm a').format(event.startTime),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 4),

                    /// LOCATION
                    Text(
                      _getCleanLocation(event),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              /// ➜ BUTTON
              Transform.rotate(
                angle: -0.785, // 45 degrees
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFE76B8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverEventsTab(EventsProvider eventsProvider) {
    final savedEvents =
        eventsProvider.events.where((e) => e.isUserSaved).toList();

    final user = context.watch<AuthProvider>().user;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            context.read<EventsProvider>().clearSearchState();
            await context.read<EventsProvider>().fetchEvents(refresh: true);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                /// 👋 HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Hey, ${user?.displayName ?? 'there'}!",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// UPCOMING (Saved Events)
                _buildSectionTitle("Upcoming Event"),
                const SizedBox(height: 12),

                savedEvents.isEmpty
                    ? _buildEmptyUpcoming()
                    : _buildUpcomingEvent(savedEvents),

                const SizedBox(height: 24),

                /// DISCOVER NEAR YOU
                _buildLocationHeader(),

                const SizedBox(height: 12),

                _buildHorizontalEvents(
                  eventsProvider.events.where((e) {
                    final eventCity = (e.city ?? '').toLowerCase();
                    final selected = _selectedCity.toLowerCase();

                    return eventCity.contains(selected);
                  }).toList(),
                ),

                const SizedBox(height: 24),

                /// POPULAR EVENTS
                _buildHotEventsHeader(),
                const SizedBox(height: 12),
                _buildCategoryBar(),
                const SizedBox(height: 16),
                _buildHorizontalEvents(
                    _getFilteredHotEvents(eventsProvider.events)),
              ],
            ),
          ),
        ),

        /// FAB
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyUpcoming() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.pinkAccent),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.pink),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "No saved events yet.\nFind more events!",
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// SECTION TITLE (NEW)
          const Text(
            "Discover events near you",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          /// CITY DROPDOWN ROW
          Row(
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCity,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  items: _cities.map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 18),
                          const SizedBox(width: 6),
                          Text(city),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCity = value;
                      });
                    }
                  },
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text(
                  "View All >",
                  style: TextStyle(color: Colors.grey[500]),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHotEventsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            "Popular Events",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: const Text("View All >"),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalEvents(List<Event> events) {
    if (events.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text("No events")),
      );
    }

    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];

          return GestureDetector(
            onTap: () => context.push('/events/${event.id}'),
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// IMAGE (separate square box)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          event.coverImageUrl ?? '',
                          height: 140,
                          width: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 140,
                            width: 160,
                            color: Colors.grey[300],
                          ),
                        ),
                      ),

                      /// HEART BUTTON
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () async {
                            final provider = context.read<EventsProvider>();

                            bool success;

                            if (event.isUserSaved) {
                              success = await provider.unsaveEvent(event.id);
                            } else {
                              success = await provider.saveEvent(event.id);
                            }

                            if (!success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Something went wrong")),
                              );
                            }
                          },
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
                              size: 18,
                              color: const Color(0xFFFE76B8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  /// CONTENT (outside image)
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),

                  /// LOCATION + TIME
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${_getCleanLocation(event)} • ${DateFormat('h:mm a').format(event.startTime)}",
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  /// ORGANIZER
                  Row(
                    children: [
                      const Icon(Icons.person, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "By ${event.organizer?.name ?? 'Unknown'}",
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  final bool isHorizontal;

  const EventCard({
    super.key,
    required this.event,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return isHorizontal ? _buildHorizontal(context) : _buildVertical(context);
  }

  /// HORIZONTAL (your new UI)
  Widget _buildHorizontal(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/events/${event.id}'),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: (event.coverImageUrl != null &&
                          event.coverImageUrl!.isNotEmpty)
                      ? Image.network(
                          event.coverImageUrl!,
                          height: isHorizontal ? 130 : 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: isHorizontal ? 130 : 180,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image),
                          ),
                        )
                      : Container(
                          height: 130,
                          color: Colors.grey[300],
                        ),
                ),

                /// DATE BADGE
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      DateFormat('MMM d').format(event.startTime),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${event.locationName ?? event.city} • ${DateFormat('h:mm a').format(event.startTime)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "By ${event.organizerName}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  /// VERTICAL (your old UI)
  Widget _buildVertical(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/events/${event.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
        ),
        child: Column(
          children: [
            (event.coverImageUrl != null && event.coverImageUrl!.isNotEmpty)
                ? Image.network(
                    event.coverImageUrl!,
                    errorBuilder: (_, __, ___) => Container(
                      height: 130,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
                  )
                : Container(height: 180, color: Colors.grey[300]),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(event.title),
            ),
          ],
        ),
      ),
    );
  }
}
