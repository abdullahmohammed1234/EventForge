import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'events_provider.dart';

class EventPlanningScreen extends StatefulWidget {
  final String eventId;

  const EventPlanningScreen({super.key, required this.eventId});

  @override
  State<EventPlanningScreen> createState() => _EventPlanningScreenState();
}

class _EventPlanningScreenState extends State<EventPlanningScreen> {
  GoogleMapController? _mapController;
  
  // Planning data
  String _transportationPlan = '';
  String _foodPlan = '';
  String _musicPlan = '';
  String _tripPlan = '';
  String _contacts = '';
  bool _isLoading = true;
  
  final TextEditingController _transportationController = TextEditingController();
  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _musicController = TextEditingController();
  final TextEditingController _tripController = TextEditingController();
  final TextEditingController _contactsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().getEventById(widget.eventId);
      _loadSavedPlans();
    });
  }

  Future<void> _loadSavedPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _transportationPlan = prefs.getString('transportation_${widget.eventId}') ?? '';
        _foodPlan = prefs.getString('food_${widget.eventId}') ?? '';
        _musicPlan = prefs.getString('music_${widget.eventId}') ?? '';
        _tripPlan = prefs.getString('trip_${widget.eventId}') ?? '';
        _contacts = prefs.getString('contacts_${widget.eventId}') ?? '';
        
        _transportationController.text = _transportationPlan;
        _foodController.text = _foodPlan;
        _musicController.text = _musicPlan;
        _tripController.text = _tripPlan;
        _contactsController.text = _contacts;
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _transportationController.dispose();
    _foodController.dispose();
    _musicController.dispose();
    _tripController.dispose();
    _contactsController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d, yyyy • h:mm a').format(date);
  }

  Future<void> _openGoogleMaps() async {
    final eventsProvider = context.read<EventsProvider>();
    final event = eventsProvider.currentEvent;
    
    if (event == null) return;
    
    final String address = Uri.encodeComponent('${event.address ?? event.city}, ${event.city}');
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$address');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _getDirections() async {
    final eventsProvider = context.read<EventsProvider>();
    final event = eventsProvider.currentEvent;
    
    if (event == null) return;
    
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
    
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$query&travelmode=driving');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _getPublicTransit() async {
    final eventsProvider = context.read<EventsProvider>();
    final event = eventsProvider.currentEvent;
    
    if (event == null) return;
    
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

  Set<Marker> _getMarkers(Event event) {
    if (event.latitude != null && event.longitude != null &&
        event.latitude != 0 && event.longitude != 0) {
      return {
        Marker(
          markerId: MarkerId(event.id),
          position: LatLng(event.latitude!, event.longitude!),
          infoWindow: InfoWindow(
            title: event.title,
            snippet: event.address ?? event.city,
          ),
        ),
      };
    }
    return {};
  }

  CameraPosition _getInitialPosition(Event event) {
    if (event.latitude != null && event.longitude != null &&
        event.latitude != 0 && event.longitude != 0) {
      return CameraPosition(
        target: LatLng(event.latitude!, event.longitude!),
        zoom: 14,
      );
    }
    // Default position - center on city if available
    // For now, show a message that location is not available
    return const CameraPosition(
      target: LatLng(0, 0),
      zoom: 1,
    );
  }

  void _savePlan() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('transportation_${widget.eventId}', _transportationController.text);
    await prefs.setString('food_${widget.eventId}', _foodController.text);
    await prefs.setString('music_${widget.eventId}', _musicController.text);
    await prefs.setString('trip_${widget.eventId}', _tripController.text);
    await prefs.setString('contacts_${widget.eventId}', _contactsController.text);
    
    setState(() {
      _transportationPlan = _transportationController.text;
      _foodPlan = _foodController.text;
      _musicPlan = _musicController.text;
      _tripPlan = _tripController.text;
      _contacts = _contactsController.text;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plan saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();
    final event = eventsProvider.currentEvent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan for Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePlan,
            tooltip: 'Save Plan',
          ),
        ],
      ),
      body: eventsProvider.isLoading || _isLoading
          ? const Center(child: CircularProgressIndicator())
          : event == null
              ? const Center(child: Text('Event not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Info Card
                      _buildEventInfoCard(event),
                      const SizedBox(height: 24),

                      // QR Code Section
                      _buildQRCodeSection(event),
                      const SizedBox(height: 24),

                      // Google Maps Section
                      _buildMapsSection(event),
                      const SizedBox(height: 24),

                      // Transportation Section
                      _buildPlanningSection(
                        title: 'Transportation',
                        icon: Icons.directions_car,
                        controller: _transportationController,
                        hintText: 'How will you get there? (e.g., drive, bus, uber)',
                        savedText: _transportationPlan,
                      ),
                      const SizedBox(height: 24),

                      // Food Section
                      _buildPlanningSection(
                        title: 'Food',
                        icon: Icons.restaurant,
                        controller: _foodController,
                        hintText: 'Meal plans, restaurants nearby, snacks to bring',
                        savedText: _foodPlan,
                      ),
                      const SizedBox(height: 24),

                      // Music Section
                      _buildPlanningSection(
                        title: 'Music',
                        icon: Icons.music_note,
                        controller: _musicController,
                        hintText: 'Playlist preferences, songs to add',
                        savedText: _musicPlan,
                      ),
                      const SizedBox(height: 24),

                      // Trip Plan Section
                      _buildPlanningSection(
                        title: 'Trip Plan',
                        icon: Icons.map,
                        controller: _tripController,
                        hintText: 'Itinerary, activities, things to do',
                        savedText: _tripPlan,
                      ),
                      const SizedBox(height: 24),

                      // Contacts Section
                      _buildPlanningSection(
                        title: 'Contacts',
                        icon: Icons.contacts,
                        controller: _contactsController,
                        hintText: 'Who is going with you? (name, phone, email)',
                        savedText: _contacts,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEventInfoCard(Event event) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _formatDate(event.startTime),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.address ?? event.city,
                    style: TextStyle(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeSection(Event event) {
    // Generate unique QR code data
    final qrData = 'EVENT_REGISTRATION:${event.id}:${event.registrationId ?? DateTime.now().millisecondsSinceEpoch}';
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.qr_code_2, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Your Event QR Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                errorStateBuilder: (ctx, err) {
                  return const Center(
                    child: Text('Error generating QR code'),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Show this QR code at the event check-in',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapsSection(Event event) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.map, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Location & Directions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Map
            if (event.latitude != null && event.longitude != null &&
                event.latitude != 0 && event.longitude != 0)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                clipBehavior: Clip.antiAlias,
                child: GoogleMap(
                  initialCameraPosition: _getInitialPosition(event),
                  markers: _getMarkers(event),
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
              )
            else
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Location coordinates not available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openGoogleMaps,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Maps'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Public transit option
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _getPublicTransit,
                icon: const Icon(Icons.train, color: Colors.orange),
                label: const Text('Find Public Transit Options'),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Location details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.city,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  if (event.address != null) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(
                        event.address!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                  ],
                  if (event.latitude != null && event.longitude != null &&
                      event.latitude != 0 && event.longitude != 0) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(
                        'Coordinates: ${event.latitude!.toStringAsFixed(4)}, ${event.longitude!.toStringAsFixed(4)}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
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

  Widget _buildPlanningSection({
    required String title,
    required IconData icon,
    required TextEditingController controller,
    required String hintText,
    required String savedText,
  }) {
    final hasSavedContent = savedText.isNotEmpty;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (hasSavedContent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Saved',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
