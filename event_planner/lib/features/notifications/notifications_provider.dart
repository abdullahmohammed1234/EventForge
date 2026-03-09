import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      type: type,
    );
  }
}

enum NotificationType {
  eventReminder,
  eventUpdate,
  newAttendee,
  safetyAlert,
  checkIn,
  groupMessage,
  system,
}

class NotificationsProvider extends ChangeNotifier {
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;

  List<NotificationItem> get notifications => _notifications;
  List<NotificationItem> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get isLoading => _isLoading;

  NotificationsProvider() {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications');

      if (notificationsJson != null) {
        _notifications = notificationsJson.map((json) {
          final parts = json.split('|||');
          return NotificationItem(
            id: parts[0],
            title: parts[1],
            message: parts[2],
            timestamp: DateTime.parse(parts[3]),
            isRead: parts[4] == 'true',
            type: NotificationType.values[int.parse(parts[5])],
          );
        }).toList();
      } else {
        // Add some sample notifications
        _notifications = [
          NotificationItem(
            id: '1',
            title: 'Welcome to Event Planner',
            message: 'Stay safe! Set up your emergency contacts in the Safety Center.',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            type: NotificationType.system,
          ),
        ];
        await _saveNotifications();
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications.map((n) {
        return '${n.id}|||${n.title}|||${n.message}|||${n.timestamp.toIso8601String()}|||${n.isRead}|||${n.type.index}';
      }).toList();
      await prefs.setStringList('notifications', notificationsJson);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
    );

    _notifications.insert(0, notification);
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }

  // Convenience methods for different notification types
  Future<void> addEventReminder(String eventName, DateTime eventTime) async {
    await addNotification(
      title: 'Event Reminder',
      message: 'Don\'t forget: $eventName is coming up!',
      type: NotificationType.eventReminder,
    );
  }

  Future<void> addEventUpdate(String eventName, String update) async {
    await addNotification(
      title: 'Event Update',
      message: '$eventName: $update',
      type: NotificationType.eventUpdate,
    );
  }

  Future<void> addNewAttendee(String eventName, String attendeeName) async {
    await addNotification(
      title: 'New Attendee',
      message: '$attendeeName joined $eventName',
      type: NotificationType.newAttendee,
    );
  }

  Future<void> addSafetyAlert(String message) async {
    await addNotification(
      title: 'Safety Alert',
      message: message,
      type: NotificationType.safetyAlert,
    );
  }

  Future<void> addCheckInReminder(String eventName) async {
    await addNotification(
      title: 'Check-in Reminder',
      message: 'Remember to check in for $eventName',
      type: NotificationType.checkIn,
    );
  }
}
