import 'package:flexitask_updated/dashboard.dart';
import 'package:flexitask_updated/local_notification.dart';
import 'package:flutter/material.dart';

class NotificationService {
  NotificationService() {
    LocalNotificationService.initialize();
  }

  Future<void> scheduleNotification(Task task) async {
    try {
      if (task.hasNotification) {
        await LocalNotificationService.scheduleNotification(task);
        debugPrint('Scheduled notification for task: ${task.title}');
      }
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
      throw Exception('Failed to schedule notification: $e');
    }
  }

  Future<void> cancelNotification(Task task) async {
    try {
      await LocalNotificationService.cancelNotification(task);
      debugPrint('Canceled notification for task: ${task.title}');
    } catch (e) {
      debugPrint('Error canceling notification: $e');
      throw Exception('Failed to cancel notification: $e');
    }
  }

  Future<void> updateNotification(Task task) async {
    try {
      await LocalNotificationService.updateNotification(task);
      debugPrint('Updated notification for task: ${task.title}');
    } catch (e) {
      debugPrint('Error updating notification: $e');
      throw Exception('Failed to update notification: $e');
    }
  }
}
