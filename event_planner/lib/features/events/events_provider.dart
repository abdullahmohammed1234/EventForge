import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/event_service.dart';
import '../../core/config/app_config.dart';

class SubEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final int? maxAttendees;
  final int currentAttendees;

  SubEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.maxAttendees,
    this.currentAttendees = 0,
  });

  factory SubEvent.fromJson(Map<String, dynamic> json) {
    return SubEvent(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      location: json['location'],
      maxAttendees: json['maxAttendees'] != null ? (json['maxAttendees'] as num).toInt() : null,
      currentAttendees: (json['currentAttendees'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
      'maxAttendees': maxAttendees,
      'currentAttendees': currentAttendees,
    };
  }
}

/// Organizer model for event detail
class Organizer {
  final String? id;
  final String name;
  final String? type;
  final String? avatarUrl;

  Organizer({
    this.id,
    required this.name,
    this.type,
    this.avatarUrl,
  });

  factory Organizer.fromJson(Map<String, dynamic> json) {
    return Organizer(
      id: json['id'] ?? json['_id'],
      name: json['displayName'] ?? json['name'] ?? 'Event Organizer',
      type: json['type'],
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'avatarUrl': avatarUrl,
    };
  }
}

/// Location model for event
class EventLocation {
  final String? name;
  final String? address;
  final double? latitude;
  final double? longitude;

  EventLocation({
    this.name,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory EventLocation.fromJson(Map<String, dynamic> json) {
    // Handle nested location object
    final locationData = json['location'] is Map ? json['location'] : json;
    
    double? lat;
    double? lng;
    
    if (locationData != null && locationData['coordinates'] != null) {
      final coords = locationData['coordinates'];
      if (coords is List && coords.length >= 2) {
        lng = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
        // Only use coordinates if they are valid (not 0,0)
        if (lat == 0 && lng == 0) {
          lat = null;
          lng = null;
        }
      }
    }
    
    return EventLocation(
      name: locationData?['name'] ?? json['city'],
      address: json['address'],
      latitude: lat ?? json['latitude'],
      longitude: lng ?? json['longitude'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

/// Contact info for event
class EventContact {
  final String? phone;
  final String? email;

  EventContact({
    this.phone,
    this.email,
  });

  factory EventContact.fromJson(Map<String, dynamic> json) {
    final contactData = json['contact'] is Map ? json['contact'] : json;
    return EventContact(
      phone: contactData?['phone'],
      email: contactData?['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email': email,
    };
  }
}

/// Attendee model
class Attendee {
  final String id;
  final String? name;
  final String? avatarUrl;

  Attendee({
    required this.id,
    this.name,
    this.avatarUrl,
  });

  factory Attendee.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] is Map ? json['user'] : json;
    final avatarUrl = userData?['avatarUrl'];
    return Attendee(
      id: userData?['_id'] ?? userData?['id'] ?? json['id'] ?? '',
      name: userData?['displayName'] ?? userData?['name'],
      avatarUrl: avatarUrl is String && avatarUrl.isNotEmpty ? AppConfig.getFullUrl(avatarUrl) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
    };
  }
}

class Event {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String city;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime startTime;
  final DateTime? endTime;
  final int? maxAttendees;
  final int currentAttendees;
  final String createdBy;
  final String? creatorName;
  final DateTime createdAt;
  final List<SubEvent> subEvents;
  final bool isUserRegistered;
  final String? registrationId; // Unique QR code ID
  final bool isUserSaved; // Whether the user has saved this event
  
  // New fields for dynamic event detail screen
  final String? coverImageUrl;
  final List<String> tags;
  final Organizer? organizer;
  final EventContact? contact;
  final List<Attendee> attendees;
  final int attendeeCount;
  final List<String> highlights;
  final bool isFree;
  final double? price;
  final EventLocation? location;
  final bool? isUserOrganizer;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.city,
    this.address,
    this.latitude,
    this.longitude,
    required this.startTime,
    this.endTime,
    this.maxAttendees,
    required this.currentAttendees,
    required this.createdBy,
    this.creatorName,
    required this.createdAt,
    this.subEvents = const [],
    this.isUserRegistered = false,
    this.registrationId,
    this.isUserSaved = false,
    this.coverImageUrl,
    this.tags = const [],
    this.organizer,
    this.contact,
    this.attendees = const [],
    this.attendeeCount = 0,
    this.highlights = const [],
    this.isFree = true,
    this.price,
    this.location,
    this.isUserOrganizer,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    List<SubEvent> subEventsList = [];
    if (json['subEvents'] != null) {
      subEventsList = (json['subEvents'] as List)
          .map((e) => SubEvent.fromJson(e))
          .toList();
    }
    
    // Extract and validate coordinates
    double? lat;
    double? lng;
    if (json['location'] != null && json['location']['coordinates'] != null) {
      final coords = json['location']['coordinates'];
      // Validate coordinates are not the default [0, 0]
      lng = (coords[0] as num).toDouble();
      lat = (coords[1] as num).toDouble();
      // Only use coordinates if they are valid (not 0,0)
      if (lat == 0 && lng == 0) {
        lat = null;
        lng = null;
      }
    }
    
    // Build organizer from createdBy field
    Organizer? organizer;
    if (json['createdBy'] != null) {
      final creator = json['createdBy'];
      final avatarUrl = creator['avatarUrl'];
      organizer = Organizer(
        id: creator['_id'] ?? creator['id'],
        name: creator['displayName'] ?? 'Event Organizer',
        type: creator['type'] ?? creator['city'] != null ? 'Local Community' : null,
        avatarUrl: avatarUrl is String && avatarUrl.isNotEmpty ? AppConfig.getFullUrl(avatarUrl) : null,
      );
    }
    
    // Build attendees list
    List<Attendee> attendeesList = [];
    if (json['attendees'] != null) {
      attendeesList = (json['attendees'] as List)
          .map((e) => Attendee.fromJson(e))
          .toList();
    }
    
    // Extract tags
    List<String> tagsList = [];
    if (json['tags'] != null) {
      tagsList = (json['tags'] as List).map((e) => e.toString()).toList();
    }
    
    // Extract highlights
    List<String> highlightsList = [];
    if (json['highlights'] != null) {
      highlightsList = (json['highlights'] as List).map((e) => e.toString()).toList();
    }
    
    // Build location object
    final eventLocation = EventLocation.fromJson(json);
    
    // Build contact object
    final eventContact = EventContact.fromJson(json);
    
    // Determine if event is free
    final isFree = json['isFree'] == true || json['price'] == null || json['price'] == 0;
    
    return Event(
      id: json['id'] ?? json['_id'],
      title: json['title'],
      description: json['description'],
      category: json['category'] ?? 'other',
      city: json['city'],
      address: json['address'],
      latitude: lat,
      longitude: lng,
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      maxAttendees: json['maxAttendees'] != null ? (json['maxAttendees'] as num).toInt() : null,
      currentAttendees: (json['currentAttendees'] as num?)?.toInt() ?? 0,
      createdBy: json['createdBy']?['id'] ?? json['createdBy']?['_id'] ?? json['createdBy'] ?? '',
      creatorName: json['createdBy']?['displayName'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      subEvents: subEventsList,
      isUserRegistered: json['isUserRegistered'] ?? false,
      registrationId: json['registrationId'],
      isUserSaved: json['isUserSaved'] ?? false,
      coverImageUrl: (json['coverImageUrl'] is String && json['coverImageUrl'].isNotEmpty) 
          ? '${AppConfig.apiBaseUrl.replaceAll('/api', '')}${json['coverImageUrl']}' 
          : null,
      tags: tagsList,
      organizer: organizer,
      contact: eventContact,
      attendees: attendeesList,
      attendeeCount: json['attendeeCount'] ?? (json['currentAttendees'] as num?)?.toInt() ?? 0,
      highlights: highlightsList,
      isFree: isFree,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      location: eventLocation,
      isUserOrganizer: json['isUserOrganizer'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'maxAttendees': maxAttendees,
      'currentAttendees': currentAttendees,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'subEvents': subEvents.map((e) => e.toJson()).toList(),
      'isUserRegistered': isUserRegistered,
      'registrationId': registrationId,
      'isUserSaved': isUserSaved,
      'coverImageUrl': coverImageUrl,
      'tags': tags,
      'organizer': organizer?.toJson(),
      'contact': contact?.toJson(),
      'attendees': attendees.map((e) => e.toJson()).toList(),
      'attendeeCount': attendeeCount,
      'highlights': highlights,
      'isFree': isFree,
      'price': price,
      'location': location?.toJson(),
      'isUserOrganizer': isUserOrganizer,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? city,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? startTime,
    DateTime? endTime,
    int? maxAttendees,
    int? currentAttendees,
    String? createdBy,
    String? creatorName,
    DateTime? createdAt,
    List<SubEvent>? subEvents,
    bool? isUserRegistered,
    String? registrationId,
    bool? isUserSaved,
    String? coverImageUrl,
    List<String>? tags,
    Organizer? organizer,
    EventContact? contact,
    List<Attendee>? attendees,
    int? attendeeCount,
    List<String>? highlights,
    bool? isFree,
    double? price,
    EventLocation? location,
    bool? isUserOrganizer,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      city: city ?? this.city,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      currentAttendees: currentAttendees ?? this.currentAttendees,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      subEvents: subEvents ?? this.subEvents,
      isUserRegistered: isUserRegistered ?? this.isUserRegistered,
      registrationId: registrationId ?? this.registrationId,
      isUserSaved: isUserSaved ?? this.isUserSaved,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      tags: tags ?? this.tags,
      organizer: organizer ?? this.organizer,
      contact: contact ?? this.contact,
      attendees: attendees ?? this.attendees,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      highlights: highlights ?? this.highlights,
      isFree: isFree ?? this.isFree,
      price: price ?? this.price,
      location: location ?? this.location,
      isUserOrganizer: isUserOrganizer ?? this.isUserOrganizer,
    );
  }
}

class EventsProvider with ChangeNotifier {
  final EventService eventService;
  final FlutterSecureStorage storage;

  List<Event> _events = [];
  List<Event> _registeredEvents = [];
  List<Event> _savedEvents = [];
  Event? _currentEvent;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isRegistering = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _currentSearchQuery;
  String? _currentCategory;

  EventsProvider({
    required this.eventService,
    required this.storage,
  }) {
    _loadRegisteredEvents();
    _loadSavedEvents();
  }

  List<Event> get events => _events;
  List<Event> get registeredEvents {
    // Sort events by date in ascending order (soonest first)
    final sortedEvents = List<Event>.from(_registeredEvents);
    sortedEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    return sortedEvents;
  }
  List<Event> get savedEvents {
    // Sort events by date in ascending order (soonest first)
    final sortedEvents = List<Event>.from(_savedEvents);
    sortedEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    return sortedEvents;
  }
  Event? get currentEvent => _currentEvent;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRegistering => _isRegistering;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<String?> _getToken() async {
    return await storage.read(key: 'auth_token');
  }

  Future<void> _loadRegisteredEvents() async {
    try {
      final token = await _getToken();
      if (token == null) return;
      
      final response = await eventService.getRegisteredEvents(
        token: token,
        page: 1,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> eventsJson = data['data']['events'];
        _registeredEvents = eventsJson.map((e) => Event.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading registered events: $e');
    }
  }

  Future<bool> searchEvents(String query, {String? category}) async {
    _currentSearchQuery = query;
    _currentPage = 1;
    _hasMore = true;
    _events = [];
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final response = await eventService.searchEvents(
        query: query,
        category: category,
        page: _currentPage,
        token: token,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> eventsJson = data['data']['events'];
        final pagination = data['data']['pagination'];

        _events = eventsJson.map((e) => Event.fromJson(e)).toList();
        _hasMore = _currentPage < pagination['pages'];
        _currentPage++;

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to search events';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> filterByCategory(String category) async {
    _currentCategory = category;
    _currentPage = 1;
    _hasMore = true;
    _events = [];
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final response = await eventService.getEvents(
        category: category,
        page: _currentPage,
        token: token,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> eventsJson = data['data']['events'];
        final pagination = data['data']['pagination'];

        _events = eventsJson.map((e) => Event.fromJson(e)).toList();
        _hasMore = _currentPage < pagination['pages'];
        _currentPage++;

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to filter events';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> fetchEvents({
    String? city,
    String? category,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _events = [];
    }

    if (_isLoading) return false;

    _isLoading = _events.isEmpty;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final response = await eventService.getEvents(
        city: city,
        category: category,
        page: _currentPage,
        token: token,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> eventsJson = data['data']['events'];
        final pagination = data['data']['pagination'];

        final newEvents = eventsJson.map((e) => Event.fromJson(e)).toList();

        if (refresh) {
          _events = newEvents;
        } else {
          _events.addAll(newEvents);
        }

        _hasMore = _currentPage < pagination['pages'];
        _currentPage++;

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to load events';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loadMoreEvents({String? city, String? category}) async {
    if (_isLoadingMore || !_hasMore) return false;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final token = await _getToken();
      final response = await eventService.getEvents(
        city: city,
        category: category,
        page: _currentPage,
        token: token,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> eventsJson = data['data']['events'];
        final pagination = data['data']['pagination'];

        final newEvents = eventsJson.map((e) => Event.fromJson(e)).toList();
        _events.addAll(newEvents);
        _hasMore = _currentPage < pagination['pages'];
        _currentPage++;

        _isLoadingMore = false;
        notifyListeners();
        return true;
      } else {
        _isLoadingMore = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoadingMore = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createEvent({
    required String title,
    String? description,
    required String category,
    required String city,
    String? address,
    double? latitude,
    double? longitude,
    required DateTime startTime,
    DateTime? endTime,
    int? maxAttendees,
    List<String>? tags,
    String? coverImageUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _error = 'Not authenticated';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await eventService.createEvent(
        title: title,
        description: description,
        category: category,
        city: city,
        address: address,
        latitude: latitude,
        longitude: longitude,
        startTime: startTime.toIso8601String(),
        endTime: endTime?.toIso8601String(),
        maxAttendees: maxAttendees,
        tags: tags,
        coverImageUrl: coverImageUrl,
        token: token,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newEvent = Event.fromJson(data['data']['event']);
        _events.insert(0, newEvent);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Failed to create event';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<String?> uploadEventCover(File imageFile) async {
    try {
      final token = await _getToken();
      if (token == null) {
        _error = 'Not authenticated';
        return null;
      }

      final response = await eventService.uploadEventCover(
        token: token,
        imageFile: imageFile,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Convert relative URL to absolute URL
        final relativeUrl = data['data']['coverImageUrl'];
        return AppConfig.getFullUrl(relativeUrl);
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Upload failed';
        return null;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      return null;
    }
  }

  // Web-compatible version using bytes
  Future<String?> uploadEventCoverWeb(Uint8List imageBytes, String fileName) async {
    try {
      final token = await _getToken();
      if (token == null) {
        _error = 'Not authenticated';
        return null;
      }

      final response = await eventService.uploadEventCoverWeb(
        token: token,
        imageBytes: imageBytes,
        fileName: fileName,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Convert relative URL to absolute URL
        final relativeUrl = data['data']['coverImageUrl'];
        return AppConfig.getFullUrl(relativeUrl);
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Upload failed';
        return null;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      return null;
    }
  }

  // Initialize/refresh data after login
  Future<void> initialize() async {
    await _loadRegisteredEvents();
    await _loadSavedEvents();
  }

  // Refresh registered events
  Future<void> refreshRegisteredEvents() async {
    await fetchRegisteredEvents(refresh: true);
  }

  // Clear search state - should be called when leaving search screen
  void clearSearchState() {
    _currentSearchQuery = null;
    _currentCategory = null;
    notifyListeners();
  }

  // Get a single event by ID
  Future<Event?> getEventById(String eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final response = await eventService.getEvent(eventId, token: token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final event = Event.fromJson(data['data']['event']);
        _currentEvent = event;
        _isLoading = false;
        notifyListeners();
        return event;
      } else {
        _error = 'Failed to load event';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Register for an event
  Future<bool> registerForEvent(String eventId) async {
    _isRegistering = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _error = 'Not authenticated';
        _isRegistering = false;
        notifyListeners();
        return false;
      }

      final response = await eventService.registerForEvent(
        eventId: eventId,
        token: token,
      );

      if (response.statusCode == 201) {
        // Update the current event's registration status
        if (_currentEvent != null && _currentEvent!.id == eventId) {
          _currentEvent = _currentEvent!.copyWith(
            isUserRegistered: true,
            currentAttendees: _currentEvent!.currentAttendees + 1,
          );
        }
        // Update event in list if present
        final eventIndex = _events.indexWhere((e) => e.id == eventId);
        if (eventIndex != -1) {
          _events[eventIndex] = _events[eventIndex].copyWith(
            isUserRegistered: true,
            currentAttendees: _events[eventIndex].currentAttendees + 1,
          );
        }
        // Refresh registered events to ensure My Events page is updated
        await fetchRegisteredEvents(refresh: true);
        _isRegistering = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Failed to register for event';
        _isRegistering = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isRegistering = false;
      notifyListeners();
      return false;
    }
  }

  // Unregister from an event
  Future<bool> unregisterFromEvent(String eventId) async {
    _isRegistering = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _error = 'Not authenticated';
        _isRegistering = false;
        notifyListeners();
        return false;
      }

      final response = await eventService.unregisterFromEvent(
        eventId: eventId,
        token: token,
      );

      if (response.statusCode == 200) {
        // Update the current event's registration status
        if (_currentEvent != null && _currentEvent!.id == eventId) {
          _currentEvent = _currentEvent!.copyWith(
            isUserRegistered: false,
            currentAttendees: (_currentEvent!.currentAttendees - 1).clamp(0, double.infinity).toInt(),
          );
        }
        // Update event in list if present
        final eventIndex = _events.indexWhere((e) => e.id == eventId);
        if (eventIndex != -1) {
          _events[eventIndex] = _events[eventIndex].copyWith(
            isUserRegistered: false,
            currentAttendees: (_events[eventIndex].currentAttendees - 1).clamp(0, double.infinity).toInt(),
          );
        }
        // Remove from registered events list
        _registeredEvents.removeWhere((e) => e.id == eventId);
        // Refresh registered events to ensure My Events page is updated
        await fetchRegisteredEvents(refresh: true);
        _isRegistering = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Failed to unregister from event';
        _isRegistering = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isRegistering = false;
      notifyListeners();
      return false;
    }
  }

  // Get registered events
  Future<bool> fetchRegisteredEvents({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _registeredEvents = [];
    }

    if (_isLoading) return false;

    _isLoading = _registeredEvents.isEmpty;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _error = 'Not authenticated';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await eventService.getRegisteredEvents(
        token: token,
        page: _currentPage,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> eventsJson = data['data']['events'];
        final pagination = data['data']['pagination'];

        final newEvents = eventsJson.map((e) => Event.fromJson(e)).toList();

        if (refresh) {
          _registeredEvents = newEvents;
        } else {
          _registeredEvents.addAll(newEvents);
        }

        _hasMore = _currentPage < pagination['pages'];
        _currentPage++;

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to load registered events';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  bool isEventRegistered(String eventId) {
    return _registeredEvents.any((e) => e.id == eventId);
  }

  bool isEventSaved(String eventId) {
    return _savedEvents.any((e) => e.id == eventId);
  }

  // Get saved events
  Future<bool> fetchSavedEvents({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _savedEvents = [];
    }

    if (_isLoading) return false;

    _isLoading = _savedEvents.isEmpty;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _error = 'Not authenticated';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await eventService.getSavedEvents(
        token: token,
        page: _currentPage,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> eventsJson = data['data']['events'];
        final pagination = data['data']['pagination'];

        final newEvents = eventsJson.map((e) => Event.fromJson(e)).toList();

        if (refresh) {
          _savedEvents = newEvents;
        } else {
          _savedEvents.addAll(newEvents);
        }

        _hasMore = _currentPage < pagination['pages'];
        _currentPage++;

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to load saved events';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Save an event
  Future<bool> saveEvent(String eventId) async {
    _isRegistering = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _error = 'Not authenticated';
        _isRegistering = false;
        notifyListeners();
        return false;
      }

      final response = await eventService.saveEvent(
        eventId: eventId,
        token: token,
      );

      if (response.statusCode == 201) {
        // Update the current event's saved status
        if (_currentEvent != null && _currentEvent!.id == eventId) {
          _currentEvent = _currentEvent!.copyWith(
            isUserSaved: true,
          );
        }
        // Update event in list if present
        final eventIndex = _events.indexWhere((e) => e.id == eventId);
        if (eventIndex != -1) {
          _events[eventIndex] = _events[eventIndex].copyWith(
            isUserSaved: true,
          );
        }
        // Refresh saved events to ensure My Events page is updated
        await fetchSavedEvents(refresh: true);
        _isRegistering = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Failed to save event';
        _isRegistering = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isRegistering = false;
      notifyListeners();
      return false;
    }
  }

  // Unsave an event
  Future<bool> unsaveEvent(String eventId) async {
    _isRegistering = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _error = 'Not authenticated';
        _isRegistering = false;
        notifyListeners();
        return false;
      }

      final response = await eventService.unsaveEvent(
        eventId: eventId,
        token: token,
      );

      if (response.statusCode == 200) {
        // Update the current event's saved status
        if (_currentEvent != null && _currentEvent!.id == eventId) {
          _currentEvent = _currentEvent!.copyWith(
            isUserSaved: false,
          );
        }
        // Update event in list if present
        final eventIndex = _events.indexWhere((e) => e.id == eventId);
        if (eventIndex != -1) {
          _events[eventIndex] = _events[eventIndex].copyWith(
            isUserSaved: false,
          );
        }
        // Remove from saved events list
        _savedEvents.removeWhere((e) => e.id == eventId);
        // Refresh saved events to ensure My Events page is updated
        await fetchSavedEvents(refresh: true);
        _isRegistering = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Failed to unsave event';
        _isRegistering = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isRegistering = false;
      notifyListeners();
      return false;
    }
  }

  // Load saved events from storage
  Future<void> _loadSavedEvents() async {
    try {
      final token = await _getToken();
      if (token == null) return;
      
      final response = await eventService.getSavedEvents(
        token: token,
        page: 1,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> eventsJson = data['data']['events'];
        _savedEvents = eventsJson.map((e) => Event.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved events: $e');
    }
  }
}
