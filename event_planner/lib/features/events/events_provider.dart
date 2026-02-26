import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api/event_service.dart';

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
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? json['_id'],
      title: json['title'],
      description: json['description'],
      category: json['category'] ?? 'other',
      city: json['city'],
      address: json['address'],
      latitude: json['location'] != null ? (json['location']['coordinates'][1] as num).toDouble() : null,
      longitude: json['location'] != null ? (json['location']['coordinates'][0] as num).toDouble() : null,
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      maxAttendees: json['maxAttendees'] != null ? (json['maxAttendees'] as num).toInt() : null,
      currentAttendees: (json['currentAttendees'] as num?)?.toInt() ?? 0,
      createdBy: json['createdBy']?['id'] ?? json['createdBy']?['_id'] ?? json['createdBy'] ?? '',
      creatorName: json['createdBy']?['displayName'],
      createdAt: DateTime.parse(json['createdAt']),
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
    };
  }
}

class EventsProvider with ChangeNotifier {
  final EventService eventService;
  final FlutterSecureStorage storage;

  List<Event> _events = [];
  List<Event> _savedEvents = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _currentSearchQuery;
  String? _currentCategory;

  EventsProvider({
    required this.eventService,
    required this.storage,
  }) {
    _loadSavedEvents();
  }

  List<Event> get events => _events;
  List<Event> get savedEvents => _savedEvents;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<String?> _getToken() async {
    return await storage.read(key: 'auth_token');
  }

  Future<void> _loadSavedEvents() async {
    try {
      final savedData = await storage.read(key: 'saved_events');
      if (savedData != null) {
        final List<dynamic> decoded = jsonDecode(savedData);
        _savedEvents = decoded.map((e) => Event.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      // Ignore errors loading saved events
    }
  }

  Future<void> _saveSavedEvents() async {
    try {
      final encoded = jsonEncode(_savedEvents.map((e) => e.toJson()).toList());
      await storage.write(key: 'saved_events', value: encoded);
    } catch (e) {
      // Ignore errors saving events
    }
  }

  bool isEventSaved(String eventId) {
    return _savedEvents.any((e) => e.id == eventId);
  }

  Future<void> toggleSaveEvent(Event event) async {
    if (isEventSaved(event.id)) {
      _savedEvents.removeWhere((e) => e.id == event.id);
    } else {
      _savedEvents.add(event);
    }
    await _saveSavedEvents();
    notifyListeners();
  }

  Future<bool> searchEvents(String query) async {
    _currentSearchQuery = query;
    _currentPage = 1;
    _hasMore = true;
    _events = [];
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final response = await eventService.getEvents(
        city: query,
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
}
