import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../auth/auth_provider.dart';
import 'events_provider.dart';

const accent = Color(0xFFF062AE);

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  int _selectedTab = 0;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      // Update shared profile image in AuthProvider
      context.read<AuthProvider>().setProfileImage(bytes);
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EventsProvider>();

      if (provider.registeredEvents.isEmpty) {
        provider.fetchRegisteredEvents(refresh: true);
      }

      if (provider.savedEvents.isEmpty) {
        provider.fetchSavedEvents(refresh: true);
      }
    });
  }

  /* Event preferences */
  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent),
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      body: Column(
        children: [
          /// PROFILE HEADER
          SizedBox(
            width: double.infinity,
            height: 260,
            child: Stack(
              children: [
                /// TOP GRADIENT
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 120,
                    padding: const EdgeInsets.only(top: 60, right: 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFF2B8D7),
                          Color(0xFFFFE4C1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            context.push('/profile');
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                /// BOTTOM WHITE BACKGROUND (UNDER THE GRADIENT
                Positioned(
                  top: 120,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: const Color.fromARGB(0, 255, 255, 255),
                  ),
                ),

                /// CONTENT
                Positioned(
                  top: 60,
                  left: 20,
                  right: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// LEFT SIDE
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.white,
                                      backgroundImage:
                                          authProvider.profileImage != null
                                              ? MemoryImage(
                                                  authProvider.profileImage!)
                                              : null,
                                      child: authProvider.profileImage == null
                                          ? const Icon(Icons.person, size: 44)
                                          : null,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      width: 35,
                                      height: 35,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFF6BBA),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.black),
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              user?.displayName ?? user?.email ?? 'User',
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                            if (user?.city != null &&
                                user!.city!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      user.city!,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      /// RIGHT SIDE
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _chip("Music"),
                              _chip("Sports"),
                              _chip("Food"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// ORIGINAL TABS
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _selectedTab == 0
                                      ? const Color(0xFFF062AE)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              'My events',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: _selectedTab == 0
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                color: _selectedTab == 0
                                    ? const Color(0xFFF062AE)
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _selectedTab == 1
                                      ? const Color(0xFFF062AE)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              'Saved events',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: _selectedTab == 1
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                color: _selectedTab == 1
                                    ? const Color(0xFFF062AE)
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedTab == 0 ? _RegisteredTab() : _SavedTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisteredTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();

    if (eventsProvider.isLoading && eventsProvider.registeredEvents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (eventsProvider.registeredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 72,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No registered events',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse events and register to see them here!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/events'),
              child: const Text('Discover Events'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: eventsProvider.registeredEvents.length,
      itemBuilder: (context, index) {
        final event = eventsProvider.registeredEvents[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _RegisteredEventCard(event: event),
        );
      },
    );
  }
}

class _SavedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();

    if (eventsProvider.isLoading && eventsProvider.savedEvents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (eventsProvider.savedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 72,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No saved events',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save events to see them here!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/events'),
              child: const Text('Discover Events'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: eventsProvider.savedEvents.length,
      itemBuilder: (context, index) {
        final event = eventsProvider.savedEvents[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _SavedEventCard(event: event),
        );
      },
    );
  }
}

class _SavedEventCard extends StatelessWidget {
  final Event event;

  const _SavedEventCard({required this.event});

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMMM d • h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/events/${event.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.coverImageUrl != null && event.coverImageUrl!.isNotEmpty)
              Image.network(
                event.coverImageUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 40),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(event.startTime),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (event.location?.address != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.location!.address!,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisteredEventCard extends StatelessWidget {
  final Event event;

  const _RegisteredEventCard({required this.event});

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMMM d • h:mm a').format(date);
  }

  Future<void> _toggleSaved(BuildContext context) async {
    final eventsProvider = context.read<EventsProvider>();

    final isSaved = eventsProvider.savedEvents.any((e) => e.id == event.id);

    final success = isSaved
        ? await eventsProvider.unsaveEvent(event.id)
        : await eventsProvider.saveEvent(event.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (isSaved
                  ? 'Removed from saved events'
                  : 'Added to saved events')
              : (eventsProvider.error ?? 'Failed to update saved event'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  String _timeUntil(DateTime eventDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(eventDate.year, eventDate.month, eventDate.day);

    final difference = target.difference(today).inDays;

    if (difference <= 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'In 1 day';
    }

    if (difference < 30) {
      return 'In $difference days';
    }

    if (difference < 365) {
      final months = (difference / 30).floor();
      return months == 1 ? 'In 1 month' : 'In $months months';
    }

    final years = (difference / 365).floor();
    return years == 1 ? 'In 1 year' : 'In $years years';
  }

  Future<void> _shareEvent(BuildContext context) async {
    final text = [
      event.title,
      _formatDate(event.startTime),
      if (event.city.isNotEmpty) event.city,
      if (event.description != null && event.description!.trim().isNotEmpty)
        event.description!.trim(),
    ].join('\n');

    await Share.share(text);
  }

  Future<void> _cancelRegistration(BuildContext context) async {
    final eventsProvider = context.read<EventsProvider>();
    final success = await eventsProvider.unregisterFromEvent(event.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Registration cancelled successfully'
              : (eventsProvider.error ?? 'Failed to cancel registration'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _showActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.ios_share_rounded,
                      color: Colors.black,
                    ),
                    title: const Text(
                      'Share event',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _shareEvent(context);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.close_rounded,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Cancel registration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);

                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Cancel registration?'),
                          content: Text(
                            'Are you sure you want to cancel your registration for "${event.title}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Keep it'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Cancel event'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && context.mounted) {
                        await _cancelRegistration(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF062AE);
    final eventsProvider = context.watch<EventsProvider>();
    final isSaved = eventsProvider.savedEvents.any((e) => e.id == event.id);

    return InkWell(
      onTap: () => context.push('/events/${event.id}'),
      borderRadius: BorderRadius.circular(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 96,
              height: 96,
              child:
                  event.coverImageUrl != null && event.coverImageUrl!.isNotEmpty
                      ? Image.network(
                          event.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade300,
                            child: const Icon(
                              Icons.image_outlined,
                              color: Colors.grey,
                              size: 32,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.image_outlined,
                            color: Colors.grey,
                            size: 32,
                          ),
                        ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFFF6D7D1),
                      border: Border.all(
                          color: Colors.white.withOpacity(0), width: 1.2),
                    ),
                    child: Text(
                      _timeUntil(event.startTime),
                      style: const TextStyle(
                        color: accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatDate(event.startTime),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              children: [
                IconButton(
                  onPressed: () => _shareEvent(context),
                  icon: const Icon(
                    Icons.ios_share_rounded,
                    size: 30,
                    color: Colors.black,
                  ),
                  splashRadius: 24,
                  tooltip: 'Share event',
                ),
                const SizedBox(height: 10),
                IconButton(
                  onPressed: () => _toggleSaved(context),
                  icon: Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 32,
                    color: const Color(0xFFF062AE),
                  ),
                  splashRadius: 24,
                  tooltip: isSaved ? 'Unsave event' : 'Save event',
                ),
                const SizedBox(height: 10),
                IconButton(
                  onPressed: () => _showActionsSheet(context),
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    size: 32,
                    color: Colors.black,
                  ),
                  splashRadius: 24,
                  tooltip: 'More options',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
