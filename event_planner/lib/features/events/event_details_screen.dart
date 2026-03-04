import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'events_provider.dart';
import '../auth/auth_provider.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().getEventById(widget.eventId);
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
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
    return colors[category.toLowerCase()] ?? Colors.grey;
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
    return icons[category.toLowerCase()] ?? Icons.event;
  }

  Future<void> _openGoogleMaps(Event event) async {
    String query;
    if (event.latitude != null && event.longitude != null &&
        event.latitude != 0 && event.longitude != 0) {
      query = '${event.latitude},${event.longitude}';
    } else {
      // Use address or city for geocoding
      final locationString = event.address ?? event.city;
      if (locationString.isNotEmpty) {
        query = Uri.encodeComponent(locationString);
      } else {
        return; // No location available
      }
    }
    
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _getPublicTransit(Event event) async {
    String query;
    if (event.latitude != null && event.longitude != null &&
        event.latitude != 0 && event.longitude != 0) {
      query = '${event.latitude},${event.longitude}';
    } else {
      // Use address or city for geocoding
      final locationString = event.address ?? event.city;
      if (locationString.isNotEmpty) {
        query = Uri.encodeComponent(locationString);
      } else {
        return; // No location available
      }
    }
    
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$query&travelmode=transit');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final event = eventsProvider.currentEvent;
    final themeColor = event != null ? _getCategoryColor(event.category) : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: Text(event?.title ?? 'Event Details'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: eventsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : event == null
              ? _buildErrorState(eventsProvider.error ?? 'Event not found')
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Image Section
                      _buildHeroSection(event, themeColor),
                      
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Badge
                            _buildCategoryBadge(event.category, themeColor),
                            
                            const SizedBox(height: 16),
                            
                            // Date & Time Section
                            _buildSectionTitle('Date & Time'),
                            const SizedBox(height: 8),
                            _buildInfoCard(
                              icon: Icons.calendar_today,
                              title: _formatDate(event.startTime),
                              subtitle: '${_formatTime(event.startTime)} - ${event.endTime != null ? _formatTime(event.endTime!) : "TBD"}',
                              themeColor: themeColor,
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Location Section
                            _buildSectionTitle('Location'),
                            const SizedBox(height: 8),
                            _buildInfoCard(
                              icon: Icons.location_on,
                              title: event.city,
                              subtitle: event.address ?? 'Address not specified',
                              themeColor: themeColor,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _openGoogleMaps(event),
                                    icon: const Icon(Icons.map),
                                    label: const Text('Open Maps'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _getPublicTransit(event),
                                    icon: const Icon(Icons.directions_transit),
                                    label: const Text('Public Transit'),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // About Section
                            if (event.description != null && event.description!.isNotEmpty) ...[
                              _buildSectionTitle('About'),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  event.description!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            
                            // Schedule Section
                            if (event.subEvents.isNotEmpty) ...[
                              _buildSectionTitle('Schedule'),
                              const SizedBox(height: 8),
                              _buildScheduleList(event.subEvents),
                              const SizedBox(height: 20),
                            ],
                            
                            // Attendees Section
                            _buildSectionTitle('Attendees'),
                            const SizedBox(height: 8),
                            _buildAttendeesInfo(event, themeColor),
                            
                            const SizedBox(height: 20),
                            
                            // Organizer Section
                            _buildSectionTitle('Organizer'),
                            const SizedBox(height: 8),
                            _buildOrganizerInfo(event, themeColor),
                            
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: event != null
          ? _buildBottomBar(event, eventsProvider, authProvider, themeColor)
          : null,
    );
  }

  Widget _buildHeroSection(Event event, Color themeColor) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColor,
            themeColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              _getCategoryIcon(event.category),
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          // Event date overlay
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM d, yyyy').format(event.startTime),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String category, Color themeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(category),
            size: 16,
            color: themeColor,
          ),
          const SizedBox(width: 6),
          Text(
            category.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: themeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color themeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: themeColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(List<SubEvent> subEvents) {
    return Column(
      children: subEvents.map((subEvent) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      DateFormat('h:mm a').format(subEvent.startTime),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('h:mm a').format(subEvent.endTime),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                subEvent.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subEvent.description != null && subEvent.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subEvent.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (subEvent.location != null && subEvent.location!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      subEvent.location!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAttendeesInfo(Event event, Color themeColor) {
    final spotsLeft = event.maxAttendees != null
        ? event.maxAttendees! - event.currentAttendees
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.people, color: Colors.orange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${event.currentAttendees} ${event.currentAttendees == 1 ? 'person' : 'people'} attending',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (spotsLeft != null && spotsLeft > 0)
                  Text(
                    '$spotsLeft spots remaining',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  )
                else if (spotsLeft == 0)
                  const Text(
                    'Event is full',
                    style: TextStyle(fontSize: 13, color: Colors.red),
                  )
                else
                  Text(
                    'Unlimited capacity',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerInfo(Event event, Color themeColor) {
    final organizerName = event.creatorName ?? 'Event Organizer';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                organizerName.isNotEmpty ? organizerName[0].toUpperCase() : 'O',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  organizerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Event Organizer',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    Event event,
    EventsProvider eventsProvider,
    AuthProvider authProvider,
    Color themeColor,
  ) {
    final isRegistered = event.isUserRegistered;
    final hasRegistrationId = event.registrationId != null && event.registrationId!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Price
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Free',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                ],
              ),
            ),
            // Button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: eventsProvider.isLoading
                    ? null
                    : () async {
                        if (!authProvider.isAuthenticated) {
                          _showLoginPrompt(context);
                          return;
                        }

                        if (isRegistered && hasRegistrationId) {
                          // Navigate to ticket
                          context.push('/ticket/${event.registrationId}');
                        } else {
                          // Register for event
                          await eventsProvider.registerForEvent(event.id);
                          if (eventsProvider.error == null && mounted) {
                            _showSuccessDialog(context);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRegistered ? Colors.green : themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: eventsProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isRegistered ? 'View Ticket' : 'Get Ticket',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(error, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  void _showLoginPrompt(BuildContext context) {
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
              'Sign in to continue',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You need to be signed in to register for events',
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

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 20),
            const Text(
              'Registered!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have successfully registered for this event.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
