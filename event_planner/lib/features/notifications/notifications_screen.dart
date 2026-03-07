import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationsProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount > 0) {
                return TextButton(
                  onPressed: () => provider.markAllAsRead(),
                  child: const Text('Mark all read'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return _NotificationTile(notification: notification);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem notification;

  const _NotificationTile({required this.notification});

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.eventReminder:
        return Icons.event;
      case NotificationType.eventUpdate:
        return Icons.update;
      case NotificationType.newAttendee:
        return Icons.person_add;
      case NotificationType.safetyAlert:
        return Icons.warning;
      case NotificationType.checkIn:
        return Icons.check_circle;
      case NotificationType.groupMessage:
        return Icons.message;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.eventReminder:
        return Colors.blue;
      case NotificationType.eventUpdate:
        return Colors.orange;
      case NotificationType.newAttendee:
        return Colors.green;
      case NotificationType.safetyAlert:
        return Colors.red;
      case NotificationType.checkIn:
        return Colors.teal;
      case NotificationType.groupMessage:
        return Colors.purple;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<NotificationsProvider>().deleteNotification(notification.id);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getIconColor().withOpacity(0.1),
          child: Icon(
            _getIcon(),
            color: _getIconColor(),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          context.read<NotificationsProvider>().markAsRead(notification.id);
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(time);
    }
  }
}
