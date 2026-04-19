import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../events/events_feed_screen.dart';
import '../events/my_events_screen.dart';
import '../events/events_provider.dart';
import '../search/search_screen.dart';
import '../profile/profile_screen.dart';
import '../events/widgets/bottom_floating_nav.dart';
import '../events/create_events_screen.dart';

class HomeScreen extends StatefulWidget {
  final int startingIndex;

  const HomeScreen({super.key, this.startingIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  bool _isInitialized = false;

  final List<Widget> _screens = const [
    EventsFeedScreen(), // 0 Home
    SearchScreen(), // 1
    CreateEventScreen(), // 2 (center create button)
    MyEventsScreen(), // 3
    ProfileScreen(), // 4
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startingIndex;
  }

  void _onTabSelected(int index) {
    // When switching to Events tab (index 0), clear search state and fetch all events
    if (index == 0) {
      final provider = Provider.of<EventsProvider>(context, listen: false);
      provider.clearSearchState();
      provider.fetchEvents(refresh: true);
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      // Initialize events data on first load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('HomeScreen: Calling initialize...');
        final provider = Provider.of<EventsProvider>(context, listen: false);
        provider.initialize().then((_) {
          debugPrint(
              'HomeScreen: Initialize complete - registered: ${provider.registeredEvents.length}');
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: BottomFloatingNav(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          accentColor: const Color(0xFFFF6BBA),
        ),
      ),
    );
  }
}
