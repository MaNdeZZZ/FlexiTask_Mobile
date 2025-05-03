import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:typed_data';
import 'dashboard.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Android settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize plugin (Android only)
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    // Create and register the notification channel on Android
    await _createNotificationChannel();

    debugPrint('LocalNotificationService initialized');
  }

  // Create notification channel for Android (important for newer Android versions)
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_reminder',
      'Task Reminders',
      description: 'Notifications for upcoming tasks',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
      enableLights: true,
      ledColor: Color(0xFF34A853),
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('Notification channel created: ${channel.id}');
  }

  static Future<void> requestPermissions() async {
    // Try different methods for requesting permissions based on package version
    try {
      final android =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (android != null) {
        // Try different methods that might be available in different versions
        try {
          // For newer versions
          await android.requestNotificationsPermission();
          debugPrint('Android notification permissions requested successfully');
        } catch (e1) {
          debugPrint('First method failed: $e1');

          try {
            // Skip explicit permission request - Android will request when showing notification
            debugPrint(
                'Skipping explicit permission request - Android will handle it automatically');
          } catch (e2) {
            debugPrint('Second attempt also failed: $e2');
          }
        }
      }
    } catch (e) {
      debugPrint('Error in permission request flow: $e');
      // Fallback - the app will still work as Android requests permissions automatically
      // when showing notifications
    }
  }

  // Schedule a notification for a task with error handling to avoid affecting task creation
  static Future<void> scheduleNotification(Task task) async {
    try {
      if (!task.hasNotification) return;

      // Calculate when to show notification based on task deadline
      final scheduledTime = task.date.subtract(
        Duration(minutes: task.notificationMinutesBefore),
      );

      // Debug time calculations
      _debugTimeCalculations(
          task.date, task.notificationMinutesBefore, scheduledTime);

      // Don't schedule if the time is in the past
      if (scheduledTime.isBefore(DateTime.now())) {
        debugPrint(
            'Skipping notification for "${task.title}" - scheduled time is in the past');
        return;
      }

      // Get emojis based on task attributes
      final priorityEmoji = _getPriorityEmoji(task.priority);
      final timeEmoji = _getTimeEmoji(task.notificationMinutesBefore);
      final randomEmoji = _getRandomTaskEmoji();

      // Set notification color based on task priority
      Color notificationColor;
      String priorityText;
      switch (task.priority) {
        case 1:
          notificationColor = const Color(0xFF34A853); // Green for low priority
          priorityText = 'Prioritas Rendah';
          break;
        case 2:
          notificationColor = Colors.orange; // Orange for medium priority
          priorityText = 'Prioritas Sedang';
          break;
        case 3:
          notificationColor = Colors.red; // Red for high priority
          priorityText = 'Prioritas Tinggi';
          break;
        default:
          notificationColor = const Color(0xFF34A853);
          priorityText = '';
      }

      // Create enhanced notification title with emoji
      final notificationTitle = '$priorityEmoji FlexiTask: ${task.title}';

      // Create enhanced notification content with emojis
      String notificationBody;
      if (task.description.isEmpty) {
        notificationBody =
            '$timeEmoji Tugas ini akan jatuh tempo dalam ${_formatRemainingTime(task.notificationMinutesBefore)}';
      } else {
        notificationBody = '$randomEmoji ${task.description}';
      }

      // Add priority text for medium and high priority tasks
      if (task.priority > 1) {
        notificationBody = '$notificationBody\n\n$priorityEmoji $priorityText';
      }

      // Enhanced notification details - using system default sound
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'task_reminder',
        'Task Reminders',
        channelDescription: 'Notifikasi untuk tugas-tugas FlexiTask Anda',
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        ticker: 'Pengingat tugas: ${task.title}',
        color: notificationColor,
        enableLights: true,
        ledColor: notificationColor,
        ledOnMs: 1000,
        ledOffMs: 500,
        // Using system default sound
        playSound: true,
        styleInformation: BigTextStyleInformation(
          notificationBody,
          htmlFormatBigText: true,
          contentTitle: '<b>$notificationTitle</b>',
          htmlFormatContentTitle: true,
          summaryText: '$timeEmoji Jatuh tempo: ${_formatTime(task.date)}',
          htmlFormatSummaryText: true,
        ),
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        category: task.priority == 3
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.reminder,
        ongoing: task.priority == 3,
        autoCancel: task.priority < 3,
      );

      // Android-only notification details
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      // Calculate exact delay in milliseconds from now until notification time
      final int delayMilliseconds =
          scheduledTime.difference(DateTime.now()).inMilliseconds;

      if (delayMilliseconds > 0) {
        // Log more detailed information about the scheduled notification
        final hoursUntilNotification = delayMilliseconds / (1000 * 60 * 60);
        final minutesUntilDeadline = task.notificationMinutesBefore;

        debugPrint('Scheduling notification for task: "${task.title}"'
            '\n  - Task deadline: ${task.date}'
            '\n  - Notification will show: $scheduledTime'
            '\n  - That\'s ${hoursUntilNotification.toStringAsFixed(2)} hours from now'
            '\n  - And $minutesUntilDeadline minutes before deadline');

        // Schedule immediate notification for testing if very short timeframe
        if (delayMilliseconds < 5000) {
          // If less than 5 seconds, show immediately for testing
          await _notificationsPlugin.show(
            task.hashCode,
            notificationTitle,
            notificationBody,
            NotificationDetails(android: androidDetails),
            payload: 'task_${task.hashCode}',
          );
          debugPrint(
              'Immediate notification displayed for task: ${task.title}');
        } else {
          // Schedule the notification using Future.delayed with error handling
          Future.delayed(Duration(milliseconds: delayMilliseconds), () async {
            try {
              await _notificationsPlugin.show(
                task.hashCode,
                notificationTitle,
                notificationBody,
                NotificationDetails(android: androidDetails),
                payload: 'task_${task.hashCode}',
              );
              debugPrint('Notification displayed for task: ${task.title}');
            } catch (e) {
              debugPrint('Error showing delayed notification: $e');
            }
          });
        }
      }
    } catch (e) {
      // Catch any errors to prevent notification issues from blocking task creation
      debugPrint('Error scheduling notification: $e');
    }
  }

  // Helper method to get emoji based on task priority
  static String _getPriorityEmoji(int priority) {
    switch (priority) {
      case 1:
        return '🟢'; // Low priority
      case 2:
        return '🟠'; // Medium priority
      case 3:
        return '🔴'; // High priority
      default:
        return '📌'; // Default
    }
  }

  // Helper method to get emoji based on time until deadline
  static String _getTimeEmoji(int minutesBeforeDeadline) {
    if (minutesBeforeDeadline <= 15) {
      return '⏰'; // Very soon
    } else if (minutesBeforeDeadline <= 60) {
      return '⌛'; // Within an hour
    } else if (minutesBeforeDeadline <= 24 * 60) {
      return '📅'; // Today
    } else if (minutesBeforeDeadline <= 48 * 60) {
      return '📆'; // Tomorrow
    } else {
      return '🗓️'; // Later
    }
  }

  // Helper method to get a random task emoji for variety
  static String _getRandomTaskEmoji() {
    final taskEmojis = [
      '✅',
      '📝',
      '📌',
      '✨',
      '🔔',
      '📊',
      '🎯',
      '📒',
      '🚀',
      '💼',
      '⭐',
      '🌟',
      '📘',
      '🏆',
      '💪',
      '✓'
    ];
    return taskEmojis[Random().nextInt(taskEmojis.length)];
  }

  // Format time in a more user-friendly way
  static String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');

    return '$day/$month/${time.year} $hour:$minute';
  }

  // New helper method for debugging time calculations
  static void _debugTimeCalculations(
      DateTime taskDeadline, int minutesBefore, DateTime notificationTime) {
    final now = DateTime.now();

    debugPrint('⏱️ TIME DEBUG INFO ⏱️');
    debugPrint('Current time: ${_formatDateTime(now)}');
    debugPrint('Task deadline: ${_formatDateTime(taskDeadline)}');
    debugPrint('Minutes before deadline for notification: $minutesBefore');
    debugPrint(
        'Notification scheduled for: ${_formatDateTime(notificationTime)}');

    final minutesUntilDeadline = taskDeadline.difference(now).inMinutes;
    final minutesUntilNotification = notificationTime.difference(now).inMinutes;

    debugPrint('Minutes until deadline: $minutesUntilDeadline');
    debugPrint('Minutes until notification: $minutesUntilNotification');
    debugPrint(
        'Human-readable time until deadline: ${_formatDuration(taskDeadline.difference(now))}');
    debugPrint(
        'Human-readable time until notification: ${_formatDuration(notificationTime.difference(now))}');
    debugPrint('----------------------------------------');
  }

  // Format DateTime to readable string
  static String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  // Format Duration to human-readable string
  static String _formatDuration(Duration duration) {
    if (duration.isNegative) {
      return 'Already passed ${_formatDuration(duration.abs())} ago';
    }

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    final parts = <String>[];
    if (days > 0) parts.add('$days day${days > 1 ? 's' : ''}');
    if (hours > 0) parts.add('$hours hour${hours > 1 ? 's' : ''}');
    if (minutes > 0) parts.add('$minutes minute${minutes > 1 ? 's' : ''}');
    if (seconds > 0 && days == 0) {
      parts.add('$seconds second${seconds > 1 ? 's' : ''}');
    }

    return parts.join(', ');
  }

  // Helper method to format remaining time in a readable format - now with debug info
  static String _formatRemainingTime(int minutes) {
    debugPrint('📝 Formatting remaining time: $minutes minutes');

    String result;
    if (minutes < 60) {
      result = '$minutes minutes';
      debugPrint('   ↳ Less than 1 hour: $result');
    } else if (minutes < 24 * 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      result =
          '$hours hour${hours > 1 ? 's' : ''}${remainingMinutes > 0 ? ' and $remainingMinutes minute${remainingMinutes > 1 ? 's' : ''}' : ''}';
      debugPrint('   ↳ Less than 1 day: $result');
    } else {
      final days = minutes ~/ (24 * 60);
      final remainingHours = (minutes % (24 * 60)) ~/ 60;
      result =
          '$days day${days > 1 ? 's' : ''}${remainingHours > 0 ? ' and $remainingHours hour${remainingHours > 1 ? 's' : ''}' : ''}';
      debugPrint('   ↳ Multiple days: $result');
    }

    return result;
  }

  // Cancel notification for a task
  static Future<void> cancelNotification(Task task) async {
    await _notificationsPlugin.cancel(task.hashCode);
    debugPrint('Cancelled notification for task ID: ${task.hashCode}');
  }

  // Update notification for a task (cancel and reschedule)
  static Future<void> updateNotification(Task task) async {
    await cancelNotification(task);
    if (task.hasNotification) {
      await scheduleNotification(task);
    }
  }
}
