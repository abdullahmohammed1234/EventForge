import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  bool _isOnline = true;
  List<dynamic> _cachedEvents = [];

  bool get isOnline => _isOnline;
  List<dynamic> get cachedEvents => _cachedEvents;

  Future<void> initialize() async {
    await _loadCachedEvents();
  }

  bool get hasNetwork => _isOnline;

  Future<void> cacheEvent(Map<String, dynamic> event) async {
    final prefs = await SharedPreferences.getInstance();

    _cachedEvents
        .removeWhere((e) => (e as Map<String, dynamic>)['id'] == event['id']);
    _cachedEvents.add(event);

    final eventsJson = jsonEncode(_cachedEvents);
    await prefs.setString('offline_events', eventsJson);
  }

  Future<void> cacheEvents(List<Map<String, dynamic>> events) async {
    final prefs = await SharedPreferences.getInstance();

    for (final event in events) {
      _cachedEvents
          .removeWhere((e) => (e as Map<String, dynamic>)['id'] == event['id']);
      _cachedEvents.add(event);
    }

    final eventsJson = jsonEncode(_cachedEvents);
    await prefs.setString('offline_events', eventsJson);
  }

  Future<void> _loadCachedEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString('offline_events');

    if (eventsJson != null) {
      final List<dynamic> decoded = jsonDecode(eventsJson);
      _cachedEvents = decoded;
    }
  }

  List<dynamic> getOfflineEvents() {
    return _cachedEvents;
  }

  Map<String, dynamic>? getOfflineEvent(String eventId) {
    try {
      return _cachedEvents.firstWhere(
        (e) => (e as Map<String, dynamic>)['id'] == eventId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('offline_events');
    _cachedEvents.clear();
  }

  void setOnlineStatus(bool online) {
    _isOnline = online;
  }
}
