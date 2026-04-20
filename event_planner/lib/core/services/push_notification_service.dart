import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

enum ReminderOption {
  thirtyMinutes(30, '30 minutes before'),
  oneHour(60, '1 hour before'),
  oneDay(1440, '1 day before'),
  none(0, 'No reminder');

  final int minutesBefore;
  final String label;

  const ReminderOption(this.minutesBefore, this.label);

  static ReminderOption fromMinutes(int minutes) {
    return ReminderOption.values.firstWhere(
      (option) => option.minutesBefore == minutes,
      orElse: () => ReminderOption.none,
    );
  }
}

class ScheduledReminder {
  final String eventId;
  final String eventName;
  final DateTime eventTime;
  final ReminderOption option;
  final int notificationId;

  ScheduledReminder({
    required this.eventId,
    required this.eventName,
    required this.eventTime,
    required this.option,
    required this.notificationId,
  });

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'eventName': eventName,
        'eventTime': eventTime.toIso8601String(),
        'option': option.minutesBefore,
        'notificationId': notificationId,
      };

  factory ScheduledReminder.fromJson(Map<String, dynamic> json) {
    return ScheduledReminder(
      eventId: json['eventId'],
      eventName: json['eventName'],
      eventTime: DateTime.parse(json['eventTime']),
      option: ReminderOption.fromMinutes(json['option']),
      notificationId: json['notificationId'],
    );
  }
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  List<ScheduledReminder> _scheduledReminders = [];

  List<ScheduledReminder> get scheduledReminders => _scheduledReminders;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _requestPermissions();
    await _loadScheduledReminders();

    _isInitialized = true;

    if (kDebugMode) {
      print('Local notifications initialized successfully');
    }
  }

  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

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
    final payload = response.payload;
    if (payload != null && kDebugMode) {
      print('Notification tapped with payload: $payload');
    }
  }

  Future<void> _loadScheduledReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getString('scheduled_reminders');
    if (remindersJson != null) {
      final List<dynamic> decoded = jsonDecode(remindersJson);
      _scheduledReminders =
          decoded.map((json) => ScheduledReminder.fromJson(json)).toList();

      // Reschedule any valid reminders
      for (final reminder in _scheduledReminders) {
        if (reminder.eventTime.isAfter(DateTime.now())) {
          await _scheduleReminderInternal(reminder);
        }
      }
    }
  }

  Future<void> _saveScheduledReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = jsonEncode(
      _scheduledReminders.map((r) => r.toJson()).toList(),
    );
    await prefs.setString('scheduled_reminders', remindersJson);
  }

  Future<void> _scheduleReminderInternal(ScheduledReminder reminder) async {
    if (reminder.option == ReminderOption.none) return;

    final scheduledTime = reminder.eventTime.subtract(
      Duration(minutes: reminder.option.minutesBefore),
    );

    if (scheduledTime.isBefore(DateTime.now())) return;

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'event_reminders',
      'Event Reminders',
      channelDescription: 'Reminders for upcoming events',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
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

    String timeLabel;
    if (reminder.option == ReminderOption.thirtyMinutes) {
      timeLabel = 'in 30 minutes';
    } else if (reminder.option == ReminderOption.oneHour) {
      timeLabel = 'in 1 hour';
    } else {
      timeLabel = 'tomorrow';
    }

    await _notificationsPlugin.zonedSchedule(
      reminder.notificationId,
      'Event Reminder',
      '${reminder.eventName} starts $timeLabel',
      tzScheduledTime,
      details,
      payload: 'event_${reminder.eventId}',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleEventReminder({
    required String eventId,
    required String eventName,
    required DateTime eventTime,
    required ReminderOption option,
  }) async {
    if (option == ReminderOption.none) return;

    // Cancel any existing reminder for this event
    await cancelEventReminder(eventId);

    final notificationId = '${eventId}_${option.minutesBefore}'.hashCode;

    final reminder = ScheduledReminder(
      eventId: eventId,
      eventName: eventName,
      eventTime: eventTime,
      option: option,
      notificationId: notificationId,
    );

    _scheduledReminders.add(reminder);
    await _scheduleReminderInternal(reminder);
    await _saveScheduledReminders();
  }

  Future<void> cancelEventReminder(String eventId) async {
    final remindersToCancel = _scheduledReminders
        .where(
          (r) => r.eventId == eventId,
        )
        .toList();

    for (final reminder in remindersToCancel) {
      await _notificationsPlugin.cancel(reminder.notificationId);
      _scheduledReminders.remove(reminder);
    }

    await _saveScheduledReminders();
  }

  Future<void> updateReminderOption(
    String eventId,
    ReminderOption option,
  ) async {
    await scheduleEventReminder(
      eventId: eventId,
      eventName: '',
      eventTime: DateTime.now(),
      option: option,
    );
  }

  Future<List<ScheduledReminder>> getRemindersForEvent(String eventId) async {
    return _scheduledReminders.where((r) => r.eventId == eventId).toList();
  }

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

    await _notificationsPlugin.show(id, title, body, details, payload: payload);
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    _scheduledReminders.clear();
    await _saveScheduledReminders();
  }

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_notification_id', userId);

    if (kDebugMode) {
      print('User notification ID saved locally');
    }
  }

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
