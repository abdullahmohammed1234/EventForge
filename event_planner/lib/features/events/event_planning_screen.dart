import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as cal;
import 'dart:convert';
import '../../core/api/maps_service.dart';
import '../../core/api/event_service.dart';
import 'events_provider.dart';
import '../safety/safety_center_screen.dart';
import '../auth/auth_provider.dart';

class EventPlanningScreen extends StatefulWidget {
  final String eventId;
  final bool showTicket;

  const EventPlanningScreen(
      {super.key, required this.eventId, this.showTicket = false});

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

  // New fields for transportation choices
  String _selectedTransportation = ''; // 'car', 'transit', 'bike'
  String _estimatedDistance = '';
  String _estimatedTime = '';

  // Sample contacts for the event
  List<Map<String, String>> _eventContacts = [];

  // Key for storing contacts list
  static const String _contactsKey = 'event_contacts_';

  final TextEditingController _transportationController =
      TextEditingController();
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
        _transportationPlan =
            prefs.getString('transportation_${widget.eventId}') ?? '';
        _foodPlan = prefs.getString('food_${widget.eventId}') ?? '';
        _musicPlan = prefs.getString('music_${widget.eventId}') ?? '';
        _tripPlan = prefs.getString('trip_${widget.eventId}') ?? '';
        _contacts = prefs.getString('contacts_${widget.eventId}') ?? '';

        _transportationController.text = _transportationPlan;
        _foodController.text = _foodPlan;
        _musicController.text = _musicPlan;
        _tripController.text = _tripPlan;
        _contactsController.text = _contacts;

        // Load contacts from SharedPreferences
        final contactsJson =
            prefs.getString('${_contactsKey}${widget.eventId}');
        if (contactsJson != null && contactsJson.isNotEmpty) {
          final List<dynamic> decoded = json.decode(contactsJson);
          _eventContacts =
              decoded.map((e) => Map<String, String>.from(e)).toList();
        }

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

    final String address = event.address ?? '';
    final String city = event.city ?? '';

    if (address.isEmpty && city.isEmpty) {
      return;
    }

    final String searchQuery = address.isNotEmpty
        ? (city.isNotEmpty ? '$address, $city' : address)
        : city;

    final result =
        await MapsService.getOrsSearchUrl(address: address, city: city);
    if (result != null && result['url'] != null) {
      final url = Uri.parse(result['url'] as String);
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Error opening map: $e');
      }
    }
  }

  Future<void> _getDirections() async {
    final eventsProvider = context.read<EventsProvider>();
    final event = eventsProvider.currentEvent;

    if (event == null) return;

    String query;
    if (event.latitude != null &&
        event.longitude != null &&
        event.latitude != 0 &&
        event.longitude != 0) {
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

    final url = Uri.parse(
        'https://www.openstreetmap.org/directions?from=&to=$query&route=car');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error getting driving directions: $e');
    }
  }

  Future<void> _getPublicTransit() async {
    final eventsProvider = context.read<EventsProvider>();
    final event = eventsProvider.currentEvent;

    if (event == null) return;

    String query;
    if (event.latitude != null &&
        event.longitude != null &&
        event.latitude != 0 &&
        event.longitude != 0) {
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

    final url = Uri.parse(
        'https://www.openstreetmap.org/directions?from=&to=$query&route=pedestrian');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error getting public transit: $e');
    }
  }

  Set<Marker> _getMarkers(Event event) {
    if (event.latitude != null &&
        event.longitude != null &&
        event.latitude != 0 &&
        event.longitude != 0) {
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
    if (event.latitude != null &&
        event.longitude != null &&
        event.latitude != 0 &&
        event.longitude != 0) {
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

    await prefs.setString(
        'transportation_${widget.eventId}', _transportationController.text);
    await prefs.setString('food_${widget.eventId}', _foodController.text);
    await prefs.setString('music_${widget.eventId}', _musicController.text);
    await prefs.setString('trip_${widget.eventId}', _tripController.text);
    await prefs.setString(
        'contacts_${widget.eventId}', _contactsController.text);

    // Save contacts list to SharedPreferences
    final contactsJson = json.encode(_eventContacts);
    await prefs.setString('${_contactsKey}${widget.eventId}', contactsJson);

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
        title: const Text('Plan Event'),
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
                      // Choose Transportation Section
                      _buildTransportationSection(event),
                      const SizedBox(height: 24),

                      // Add Contacts Section
                      _buildContactsSection(event),
                      const SizedBox(height: 24),

                      // Destination + Estimated Time Section
                      _buildDestinationSection(event),
                      const SizedBox(height: 24),

                      // Action Buttons Section
                      _buildActionButtonsSection(event),
                      const SizedBox(height: 24),

                      // Collaborative To-Do List Section
                      _buildTodoListSection(event),
                      const SizedBox(height: 24),

                      // Polls Section
                      _buildPollsSection(event),
                      const SizedBox(height: 24),

                      // Comments Section
                      _buildCommentsSection(event),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  // ==================== COLLABORATION FEATURES ====================

  Widget _buildTodoListSection(Event event) {
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
                Icon(Icons.checklist, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Collaborative To-Do List',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => _showAddTodoDialog(event),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (event.todoItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.assignment_turned_in, color: Colors.grey),
                    SizedBox(width: 12),
                    Text('No tasks yet. Add one!',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              ...event.todoItems.map((todo) => _buildTodoItem(event, todo)),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoItem(Event event, TodoItem todo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: todo.isCompleted ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Checkbox(
            value: todo.isCompleted,
            onChanged: (value) => _toggleTodo(event, todo),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: TextStyle(
                    decoration:
                        todo.isCompleted ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (todo.description != null && todo.description!.isNotEmpty)
                  Text(
                    todo.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _deleteTodo(event, todo),
          ),
        ],
      ),
    );
  }

  void _showAddTodoDialog(Event event) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                prefixIcon: Icon(Icons.task),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                await _addTodo(
                    event, titleController.text, descController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addTodo(Event event, String title, String description) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final eventService = EventService();
    final response = await eventService.addTodoItem(
      eventId: event.id,
      title: title,
      description: description.isNotEmpty ? description : null,
      token: token,
    );

    if (response.statusCode == 201) {
      if (mounted) {
        context.read<EventsProvider>().getEventById(event.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Task added!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _toggleTodo(Event event, TodoItem todo) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final eventService = EventService();
    final response = await eventService.updateTodoItem(
      eventId: event.id,
      todoId: todo.id,
      isCompleted: !todo.isCompleted,
      token: token,
    );

    if (response.statusCode == 200) {
      if (mounted) {
        context.read<EventsProvider>().getEventById(event.id);
      }
    }
  }

  Future<void> _deleteTodo(Event event, TodoItem todo) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final eventService = EventService();
    final response = await eventService.deleteTodoItem(
      eventId: event.id,
      todoId: todo.id,
      token: token,
    );

    if (response.statusCode == 200) {
      if (mounted) {
        context.read<EventsProvider>().getEventById(event.id);
      }
    }
  }

  Widget _buildPollsSection(Event event) {
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
                Icon(Icons.poll, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text(
                  'Group Polls',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => _showCreatePollDialog(event),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (event.polls.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.how_to_vote, color: Colors.grey),
                    SizedBox(width: 12),
                    Text('No polls yet. Create one!',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              ...event.polls.map((poll) => _buildPollItem(event, poll)),
          ],
        ),
      ),
    );
  }

  Widget _buildPollItem(Event event, Poll poll) {
    final userId = context.read<AuthProvider>().user?.id ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  poll.question,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              if (!poll.isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Closed', style: TextStyle(fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...poll.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final voteCount = option.votes.length;
            final hasVoted = option.votes.contains(userId);
            final totalVotes =
                poll.options.fold(0, (sum, o) => sum + o.votes.length);
            final percentage =
                totalVotes > 0 ? (voteCount / totalVotes * 100).round() : 0;

            return GestureDetector(
              onTap:
                  poll.isActive ? () => _voteOnPoll(event, poll, index) : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: hasVoted ? Colors.blue[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasVoted ? Colors.blue : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasVoted
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: hasVoted ? Colors.blue : Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(option.text)),
                          Text('$voteCount ($percentage%)',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    if (percentage > 0)
                      Positioned.fill(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: percentage / 100,
                              child: Container(
                                color: Colors.blue.withOpacity(0.2),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          if (poll.isActive)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (event.isUserOrganizer == true)
                  TextButton(
                    onPressed: () => _closePoll(event, poll),
                    child: const Text('Close Poll',
                        style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  void _showCreatePollDialog(Event event) {
    final questionController = TextEditingController();
    final List<TextEditingController> optionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Poll'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    prefixIcon: Icon(Icons.help_outline),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Options (at least 2)',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
                const SizedBox(height: 8),
                ...optionControllers.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: 'Option ${entry.key + 1}',
                        prefixIcon: const Icon(Icons.circle_outlined, size: 16),
                      ),
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      optionControllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Option'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final options = optionControllers
                    .map((c) => c.text)
                    .where((t) => t.isNotEmpty)
                    .toList();
                if (questionController.text.isNotEmpty && options.length >= 2) {
                  await _createPoll(event, questionController.text, options);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPoll(
      Event event, String question, List<String> options) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final eventService = EventService();
    final response = await eventService.addPoll(
      eventId: event.id,
      question: question,
      options: options,
      token: token,
    );

    if (response.statusCode == 201) {
      if (mounted) {
        context.read<EventsProvider>().getEventById(event.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Poll created!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _voteOnPoll(Event event, Poll poll, int optionIndex) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final eventService = EventService();
    final response = await eventService.voteOnPoll(
      eventId: event.id,
      pollId: poll.id,
      optionIndex: optionIndex,
      token: token,
    );

    if (response.statusCode == 200) {
      if (mounted) {
        context.read<EventsProvider>().getEventById(event.id);
      }
    }
  }

  Future<void> _closePoll(Event event, Poll poll) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final eventService = EventService();
    final response = await eventService.closePoll(
      eventId: event.id,
      pollId: poll.id,
      token: token,
    );

    if (response.statusCode == 200) {
      if (mounted) {
        context.read<EventsProvider>().getEventById(event.id);
      }
    }
  }

  Widget _buildCommentsSection(Event event) {
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
                Icon(Icons.comment, color: Colors.purple[700]),
                const SizedBox(width: 8),
                const Text(
                  'Discussion',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Add comment input
            Row(
              children: [
                Flexible(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () => _postComment(event),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (event.comments.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Colors.grey),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('No comments yet. Start the conversation!',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              )
            else
              ...event.comments
                  .map((comment) => _buildCommentItem(event, comment)),
          ],
        ),
      ),
    );
  }

  final TextEditingController _commentController = TextEditingController();

  Widget _buildCommentItem(Event event, Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.blue[100],
                child: Text(
                  (comment.creatorName ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  comment.creatorName ?? 'User',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatCommentTime(comment.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (ctx) {
              final currentEvent = event;
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (comment.createdBy == ctx.read<AuthProvider>().user?.id)
                    GestureDetector(
                      onTap: () => _deleteComment(currentEvent, comment),
                      child: const Text('Delete',
                          style: TextStyle(fontSize: 12, color: Colors.red)),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatCommentTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dateTime);
  }

  Future<void> _postComment(Event event) async {
    if (_commentController.text.trim().isEmpty) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final eventService = EventService();
    final response = await eventService.addComment(
      eventId: event.id,
      content: _commentController.text.trim(),
      token: token,
    );

    if (response.statusCode == 201) {
      _commentController.clear();
      if (mounted) {
        context.read<EventsProvider>().getEventById(event.id);
      }
    }
  }

  Future<void> _deleteComment(Event event, Comment comment) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final eventService = EventService();
    final response = await eventService.deleteComment(
      eventId: event.id,
      commentId: comment.id,
      token: token,
    );

    if (response.statusCode == 200) {
      if (mounted) {
        context.read<EventsProvider>().getEventById(event.id);
      }
    }
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
    final qrData =
        'EVENT_REGISTRATION:${event.id}:${event.registrationId ?? DateTime.now().millisecondsSinceEpoch}';

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
            if (event.latitude != null &&
                event.longitude != null &&
                event.latitude != 0 &&
                event.longitude != 0)
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
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
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
                  if (event.latitude != null &&
                      event.longitude != null &&
                      event.latitude != 0 &&
                      event.longitude != 0) ...[
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  // New method: Choose Transportation Section
  Widget _buildTransportationSection(Event event) {
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
                Icon(Icons.directions_car,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Choose Transportation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTransportOption(
                    icon: Icons.directions_car,
                    label: 'Car',
                    value: 'car',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTransportOption(
                    icon: Icons.train,
                    label: 'Transit',
                    value: 'transit',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTransportOption(
                    icon: Icons.directions_bike,
                    label: 'Bike',
                    value: 'bike',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportOption({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isSelected = _selectedTransportation == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTransportation = value;
        });
        // Update the transportation plan
        _transportationController.text = label;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New method: Add Contacts Section
  Widget _buildContactsSection(Event event) {
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
                Icon(Icons.contacts, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Add Contacts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'People joining you:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            // Display sample contacts
            if (_eventContacts.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.grey),
                    SizedBox(width: 12),
                    Text(
                      'No contacts added yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ...(_eventContacts.map((contact) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          child: Icon(Icons.person, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact['name'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              Text(
                                contact['phone'] ?? '',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ))),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddContactDialog(event),
                icon: const Icon(Icons.add),
                label: const Text('Add Contact'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog(Event event) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final newContact = {
                  'name': nameController.text,
                  'phone': phoneController.text,
                };
                setState(() {
                  _eventContacts.add(newContact);
                });
                // Automatically save contacts when added
                _saveContactsImmediately(newContact);
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // New method: Destination + Estimated Time Section
  Widget _buildDestinationSection(Event event) {
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
                Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Destination + Estimated Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Location
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.address ?? event.city,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (event.address != null)
                          Text(
                            event.city,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Distance and Time
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.straighten, color: Colors.blue),
                        const SizedBox(height: 4),
                        Text(
                          _estimatedDistance.isEmpty
                              ? '--'
                              : _estimatedDistance,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const Text(
                          'Distance',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.schedule, color: Colors.green),
                        const SizedBox(height: 4),
                        Text(
                          _estimatedTime.isEmpty ? '--' : _estimatedTime,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Text(
                          'Est. Time',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Google Maps API declaration
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Estimated via Google Maps API',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New method: Action Buttons Section
  Widget _buildActionButtonsSection(Event event) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Add to Google Calendar Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _addToGoogleCalendar(event),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Add to Google Calendar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Set Up Safety Features Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToSafetyCenter(event),
                icon: const Icon(Icons.security),
                label: const Text('Set Up Safety Features'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Share Trip Details Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _shareTripDetails(event),
                icon: const Icon(Icons.share),
                label: const Text('Share Trip Details'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToGoogleCalendar(Event event) async {
    final title = Uri.encodeComponent(event.title);
    final details = Uri.encodeComponent(
        'Event: ${event.title}\nLocation: ${event.address ?? event.city}');
    final location = Uri.encodeComponent('${event.address ?? event.city}');
    final startTime = event.startTime
        .toUtc()
        .toIso8601String()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .split('.')[0];
    final endTime = event.endTime!
        .toUtc()
        .toIso8601String()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .split('.')[0];

    final url = Uri.parse(
        'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$title&details=$details&location=$location&dates=$startTime/$endTime');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Calendar')),
        );
      }
    }
  }

  void _navigateToSafetyCenter(Event event) {
    context.push('/safety/${event.id}', extra: {'eventName': event.title});
  }

  void _shareTripDetails(Event event) {
    final details = '''
Event: ${event.title}
Date: ${_formatDate(event.startTime)}
Location: ${event.address ?? event.city}
Transportation: ${_selectedTransportation.isEmpty ? 'Not selected' : _selectedTransportation}
${_estimatedDistance.isNotEmpty ? 'Distance: $_estimatedDistance' : ''}
${_estimatedTime.isNotEmpty ? 'Estimated Time: $_estimatedTime' : ''}
''';
    Share.share(details, subject: 'Trip Details - ${event.title}');
  }

  // Save contacts immediately when added
  Future<void> _saveContactsImmediately(Map<String, String> newContact) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = json.encode(_eventContacts);
      await prefs.setString('${_contactsKey}${widget.eventId}', contactsJson);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Silently fail
    }
  }
}
