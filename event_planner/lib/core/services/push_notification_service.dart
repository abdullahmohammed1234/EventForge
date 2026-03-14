import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize iOS settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialize settings
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _notificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions (Android 13+)
    await _requestPermissions();

    _isInitialized = true;

    if (kDebugMode) {
      print('Local notifications initialized successfully');
    }
  }

  Future<void> _requestPermissions() async {
    // Request Android permissions
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    // Request iOS permissions
    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    final payload = response.payload;
    if (payload != null && kDebugMode) {
      print('Notification tapped with payload: $payload');
    }
  }

  // Show a simple notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'event_planner_channel',
      'Event Planner Notifications',
      channelDescription: 'Notifications for event planner app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Save user ID for push notifications (for backend integration)
  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_notification_id', userId);

    if (kDebugMode) {
      print('User notification ID saved locally');
    }
  }

  // Example: Show event reminder notification
  Future<void> showEventReminder({
    required String eventId,
    required String eventName,
    required DateTime eventTime,
  }) async {
    await showNotification(
      id: eventId.hashCode,
      title: 'Event Reminder',
      body: '$eventName starts soon!',
      payload: 'event_$eventId',
    );
  }

  // Example: Show event update notification
  Future<void> showEventUpdate({
    required String eventId,
    required String eventName,
    required String update,
  }) async {
    await showNotification(
      id: eventId.hashCode + 1,
      title: 'Event Update',
      body: '$eventName: $update',
      payload: 'event_$eventId',
    );
  }

  // Example: Show new attendee notification
  Future<void> showNewAttendee({
    required String eventId,
    required String eventName,
    required String attendeeName,
  }) async {
    await showNotification(
      id: eventId.hashCode + 2,
      title: 'New Attendee',
      body: '$attendeeName joined $eventName',
      payload: 'event_$eventId',
    );
  }
}
