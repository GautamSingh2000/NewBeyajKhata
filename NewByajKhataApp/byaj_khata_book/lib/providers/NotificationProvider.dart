
import 'package:flutter/cupertino.dart';

class NotificationProvider with ChangeNotifier {
  //
  // List<AppNotification> get todayNotifications {
  //   final now = DateTime.now();
  //   final today = DateTime(now.year, now.month, now.day);
  //   final tomorrow = today.add(const Duration(days: 1));
  //
  //   return _notifications.where((notification) {
  //     // Filter only FCM messages, reminders, and due dates
  //     if (!_isAllowedNotificationType(notification)) {
  //       return false;
  //     }
  //
  //     // Skip notifications that have been completed today
  //     if (_completedTodayNotificationIds.contains(notification.id)) {
  //       return false;
  //     }
  //
  //     // Check if due date is in data
  //     if (notification.data != null && notification.data!.containsKey('dueDate')) {
  //       try {
  //         final dueDate = DateTime.parse(notification.data!['dueDate']);
  //         final dueDateDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
  //         // Check if due date is today
  //         return dueDateDay.isAtSameMomentAs(today);
  //       } catch (e) {
  //         // If date parsing fails, fall back to timestamp check
  //         return notification.timestamp.isAfter(today) &&
  //             notification.timestamp.isBefore(tomorrow);
  //       }
  //     }
  //
  //     // Use timestamp for notifications without due date
  //     return notification.timestamp.isAfter(today) &&
  //         notification.timestamp.isBefore(tomorrow);
  //   }).toList();
  // }
  //
  // // Get upcoming notifications (future dates in current month)
  // List<AppNotification> get upcomingNotifications {
  //   final now = DateTime.now();
  //   final today = DateTime(now.year, now.month, now.day);
  //   final tomorrow = today.add(const Duration(days: 1));
  //   final nextMonth = DateTime(now.year, now.month + 1, 1);
  //
  //   return _notifications.where((notification) {
  //     // Filter only FCM messages, reminders, and due dates
  //     if (!_isAllowedNotificationType(notification)) {
  //       return false;
  //     }
  //
  //     // Check if due date is in data
  //     if (notification.data != null && notification.data!.containsKey('dueDate')) {
  //       try {
  //         final dueDate = DateTime.parse(notification.data!['dueDate']);
  //         final dueDateDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
  //
  //         // Check if due date is after tomorrow but still in current month
  //         return dueDateDay.isAfter(tomorrow) && dueDateDay.isBefore(nextMonth);
  //       } catch (e) {
  //         // If date parsing fails, fall back to timestamp check
  //         return notification.timestamp.isAfter(tomorrow);
  //       }
  //     }
  //
  //     // Use timestamp for notifications without due date
  //     return notification.timestamp.isAfter(tomorrow);
  //   }).toList();
  // }
  //
}