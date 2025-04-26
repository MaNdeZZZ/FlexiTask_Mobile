import 'dart:async'; // Add this import for Timer
import 'package:flutter/material.dart';
import 'chatbot.dart';
import 'profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'completed.dart';
import 'theme_constants.dart';
import 'local_notification.dart'; // Import the real notification service
import 'dart:io'; // Add this import for File class
import 'transitions.dart'; // Add this import

void main() {
  runApp(const MyApp());
}

// Task model to store task information
class Task {
  String title;
  DateTime date;
  String description;
  bool isCompleted;
  int priority; // Added priority field
  Color color; // Added color field
  bool hasNotification; // Added notification field
  int notificationMinutesBefore; // Minutes before deadline to notify

  Task({
    required this.title,
    required this.date,
    this.description = '',
    this.isCompleted = false,
    this.priority = 1, // Default priority is low (1)
    this.color = Colors.white, // Default color is white
    this.hasNotification = false, // Default is no notification
    this.notificationMinutesBefore = 24 * 60, // Default 1 day before
  });
}

// Mock notification service for compatibility with existing code
class NotificationService {
  // List to track scheduled notifications
  static final List<Map<String, dynamic>> _scheduledNotifications = [];

  static Future<void> initialize() async {
    // Call the real notification service instead
    await LocalNotificationService.initialize();
    debugPrint('Mock notification service redirecting to real service');
  }

  // Schedule a notification for a task
  static Future<void> scheduleNotification(Task task) async {
    // Delegate to the real notification service
    await LocalNotificationService.scheduleNotification(task);

    // Keep track for backwards compatibility
    if (!task.hasNotification) return;

    final scheduledTime = task.date.subtract(
      Duration(minutes: task.notificationMinutesBefore),
    );

    if (scheduledTime.isBefore(DateTime.now())) return;

    _scheduledNotifications.add({
      'id': task.hashCode,
      'title': 'Upcoming Task: ${task.title}',
      'body': task.description.isEmpty
          ? 'This task is due soon!'
          : task.description,
      'scheduledTime': scheduledTime,
    });
  }

  // Cancel notification for a task
  static Future<void> cancelNotification(Task task) async {
    // Delegate to the real notification service
    await LocalNotificationService.cancelNotification(task);

    _scheduledNotifications.removeWhere(
      (notification) => notification['id'] == task.hashCode,
    );
  }

  // Update notification for a task (cancel and reschedule)
  static Future<void> updateNotification(Task task) async {
    // Delegate to the real notification service
    await LocalNotificationService.updateNotification(task);

    await cancelNotification(task);
    if (task.hasNotification) {
      await scheduleNotification(task);
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize notifications when app starts
    LocalNotificationService.initialize();
    // Request notification permissions
    LocalNotificationService.requestPermissions();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const DashboardScreen(),
    );
  }
}

// Add a separate list for completed tasks
final List<Task> _completedTasks = [];

class DashboardScreen extends StatefulWidget {
  // Renamed from TodoListScreen
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState(); // Updated state class name
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Renamed from _TodoListScreenState
  // Task list to store all tasks
  final List<Task> _tasks = [
    // Existing tasks
    Task(
      title: 'Attend webinar on Flutter development',
      date: DateTime.now(),
      description: 'Join the Zoom meeting at 2 PM',
    ),
    Task(title: 'Complete prototype for FlexiTask', date: DateTime.now()),
    Task(
      title: 'Team meeting at 3 PM',
      date: DateTime.now(),
      description: 'Discuss project timeline and deliverables',
    ),

    // Add overdue tasks for testing
    Task(
      title: 'Submit monthly report',
      date: DateTime.now().subtract(const Duration(days: 1)), // 1 day overdue
      description: 'Financial summary for last month',
      priority: 2, // Medium priority
    ),
    Task(
      title: 'Client proposal deadline',
      date: DateTime.now().subtract(const Duration(days: 3)), // 3 days overdue
      description: 'Final proposal for the XYZ project',
      priority: 3, // High priority
    ),
    Task(
      title: 'Renew domain registration',
      date: DateTime.now().subtract(const Duration(days: 7)), // 7 days overdue
      description: 'Company website domain is expiring',
      priority: 3, // High priority
      hasNotification: true, // With notification
    ),

    // Future tasks
    Task(
      title: 'Review project requirements',
      date: DateTime.now().add(const Duration(days: 1)),
      description: 'Check all project specifications',
    ),
    Task(
      title: 'Doctor appointment at 10 AM',
      date: DateTime.now().add(const Duration(days: 1)),
    ),
  ];

  // Add a variable to store the profile image path
  String? _profileImagePath;

  // Add this variable for bottom navigation
  int _selectedIndex = 1; // Default to middle tab (Add Task)

  // Add state to track if we're viewing overdue tasks
  bool _showingOverdueTasks = false;

  // Add a timer for checking task status
  Timer? _taskStatusTimer;

  @override
  void initState() {
    super.initState();
    // Schedule notifications for existing tasks
    for (var task in _tasks) {
      if (task.hasNotification) {
        NotificationService.scheduleNotification(task);
      }
    }
    // Load profile image if available
    _loadProfileImage();

    // Reset selected index when returning to dashboard
    setState(() {
      _selectedIndex = 1; // Always ensure Add Task (Home) is selected
    });

    // Start timer for checking task status periodically
    _startTaskStatusCheckTimer();
  }

  @override
  void dispose() {
    // Cancel timer to prevent memory leaks
    _taskStatusTimer?.cancel();
    super.dispose();
  }

  // Start a timer to periodically check for overdue tasks
  void _startTaskStatusCheckTimer() {
    // Check every 10 seconds if any task has become overdue
    _taskStatusTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final now = DateTime.now();
      bool needsUpdate = false;

      // Check if any tasks have become overdue since last check
      for (final task in _tasks) {
        if (!task.isCompleted && task.date.isBefore(now)) {
          needsUpdate = true;
          break;
        }
      }

      // Trigger UI update if needed
      if (needsUpdate) {
        setState(() {
          // This empty setState will trigger a rebuild with updated overdue status
        });
      }
    });
  }

  // Load profile image from SharedPreferences
  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('profileImagePath');
    if (savedPath != null && savedPath.isNotEmpty) {
      setState(() {
        _profileImagePath = savedPath;
      });
    }
  }

  // Helper method to build profile image based on path type
  Widget _buildProfileImage() {
    if (_profileImagePath != null) {
      // Check if it's a file path (starts with / or file:)
      if (_profileImagePath!.startsWith('/') ||
          _profileImagePath!.startsWith('file:')) {
        return Image.file(
          File(_profileImagePath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fall back to default image on error
            return Image.asset('assets/images/logo.png', fit: BoxFit.cover);
          },
        );
      } else {
        // It's an asset path
        return Image.asset(
          _profileImagePath!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset('assets/images/logo.png', fit: BoxFit.cover);
          },
        );
      }
    } else {
      // Default fallback image
      return Image.asset('assets/images/logo.png', fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group tasks by date
    final groupedTasks = _groupTasksByDate();

    // Count overdue tasks (1+ days)
    final overdueTasksCount = _getOverdueTasksCount();

    // Fix: ensure Scaffold doesn't have positional arguments
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: AppColors.darkBackground,
          child: Column(
            children: [
              // Main content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(color: AppColors.background),
                  child: Column(
                    children: [
                      // Logo and profile section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Replace text with logo image
                            GestureDetector(
                              onLongPress: () =>
                                  _resetNotificationPermissionRequest(),
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 40.0,
                                width: 40.0,
                              ),
                            ),
                            // Profile picture - properly styled as circular avatar
                            GestureDetector(
                              onTap: () {
                                AppTransitions.push(
                                  context,
                                  const ProfileScreen(),
                                ).then((_) =>
                                    _loadProfileImage()); // Reload when returning from profile
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFD9D9D9),
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: _buildProfileImage(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tagline
                      Container(
                        padding: const EdgeInsets.only(bottom: 16),
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                        ),
                        child: const Center(
                          child: Text(
                            "Let's turn your ideas into action!",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Lexend',
                            ),
                          ),
                        ),
                      ),
                      // Divider
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey,
                      ),
                      // Todo list items
                      Expanded(
                        child: Container(
                          color: const Color.fromARGB(255, 230, 230, 230),
                          child: ListView(
                            padding: const EdgeInsets.all(12),
                            children: [
                              // Today/Overdue section with toggle functionality
                              if (_showingOverdueTasks) ...[
                                // Overdue tasks view
                                _buildOverdueHeader(overdueTasksCount),
                                ...getOverdueTasks().map(
                                  (index) => _buildTaskCard(index),
                                ),
                              ] else ...[
                                // Today section with overdue badge if needed
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildDateHeader('Today', isToday: true),
                                    if (overdueTasksCount > 0)
                                      _buildOverdueCounter(overdueTasksCount),
                                  ],
                                ),
                                if (groupedTasks['Today']!.isNotEmpty) ...[
                                  ...groupedTasks['Today']!.map(
                                    (index) => _buildTaskCard(index),
                                  ),
                                ],
                              ],

                              // Only show these sections when not in overdue view
                              if (!_showingOverdueTasks) ...[
                                // Tomorrow section
                                if (groupedTasks['Tomorrow']!.isNotEmpty) ...[
                                  _buildDateHeader('Tomorrow'),
                                  ...groupedTasks['Tomorrow']!.map(
                                    (index) => _buildTaskCard(index),
                                  ),
                                ],

                                // Upcoming section - Modified to show specific dates
                                for (var entry in groupedTasks.entries)
                                  if (entry.key != 'Today' &&
                                      entry.key != 'Tomorrow' &&
                                      entry.value.isNotEmpty) ...[
                                    _buildDateHeader(entry.key),
                                    ...entry.value.map(
                                      (index) => _buildTaskCard(index),
                                    ),
                                  ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Replace the custom navigation with WhatsApp style bottom navigation bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, -1),
              blurRadius: 5,
              color: Colors.black.withOpacity(0.1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });

            // Handle navigation based on the selected tab
            switch (index) {
              case 0: // Assistant
                AppTransitions.push(
                  context,
                  const ChatbotScreen(),
                ).then((_) {
                  // Reset to middle tab when returning from Assistant
                  setState(() {
                    _selectedIndex = 1;
                  });
                });
                break;
              case 2: // Completed
                AppTransitions.push(
                  context,
                  CompletedTasksScreen(
                    completedTasks: _completedTasks,
                    onTaskRestored: _handleTaskRestored,
                  ),
                ).then((_) {
                  // Reset to middle tab when returning from Completed
                  setState(() {
                    _selectedIndex = 1;
                  });
                });
                break;
              // Case 1 (Add Task) is handled in the dashboard itself
              case 1:
                _showAddTaskDialog();
                break;
            }
          },
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.accent, // Green color for selected item
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.normal,
            fontSize: 11,
          ),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology),
              label: 'Assistant',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'Add Task',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              activeIcon: Icon(Icons.check_circle),
              label: 'Completed',
            ),
          ],
        ),
      ),
    );
  }

  // Build date section headers (with green color for Today)
  Widget _buildDateHeader(String text, {bool isToday = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isToday ? AppColors.todayHeader : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isToday ? AppColors.lightText : Colors.grey,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lexend',
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // Format date to a readable string for headers
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate.compareTo(today) == 0) {
      return 'Today';
    } else if (taskDate.compareTo(tomorrow) == 0) {
      return 'Tomorrow';
    } else {
      // Use a more human-readable format with day name and date
      // Define weekdays list for day name
      final List<String> weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      // Months for a more readable format
      final List<String> months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      final weekday = weekdays[date.weekday - 1]; // weekday is 1-7 in Dart
      final day = date.day;
      final month = months[date.month - 1];

      // For both overdue and upcoming tasks, show day name and date
      return '$weekday, $day $month';
    }
  }

  // Build overdue header with back button
  Widget _buildOverdueHeader(int count) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16, right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: const Text(
              "Overdue Tasks", // Changed from just "Overdue" to be more descriptive
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lexend',
                fontSize: 14,
              ),
            ),
          ),
          // Back to today button
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showingOverdueTasks = false;
              });
            },
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text(
              "Back to Today",
              style: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  // Build overdue counter widget
  Widget _buildOverdueCounter(int count) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showingOverdueTasks = true;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(top: 16, right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              "Overdue: $count",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lexend',
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get count of tasks overdue by 1+ days
  int _getOverdueTasksCount() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _tasks.where((task) {
      if (task.isCompleted) return false;

      final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
      final daysDifference = today.difference(taskDate).inDays;

      return daysDifference >= 1; // One or more days overdue
    }).length;
  }

  // Get list of tasks overdue by 1+ days, sorted by days overdue, priority, and time
  List<int> getOverdueTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    List<int> overdueTasks = [];

    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].isCompleted) continue;

      final taskDate = DateTime(
          _tasks[i].date.year, _tasks[i].date.month, _tasks[i].date.day);
      final daysDifference = today.difference(taskDate).inDays;

      if (daysDifference >= 1) {
        overdueTasks.add(i);
      }
    }

    // Sort overdue tasks by days overdue, then by priority, then by time
    overdueTasks.sort((a, b) {
      final taskDateA = DateTime(
          _tasks[a].date.year, _tasks[a].date.month, _tasks[a].date.day);
      final taskDateB = DateTime(
          _tasks[b].date.year, _tasks[b].date.month, _tasks[b].date.day);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final daysOverdueA = today.difference(taskDateA).inDays;
      final daysOverdueB = today.difference(taskDateB).inDays;

      // Compare days overdue first (most overdue first)
      final daysComparison = daysOverdueB.compareTo(daysOverdueA);

      if (daysComparison == 0) {
        // If same days overdue, compare by priority (high priority first)
        final priorityComparison =
            _tasks[b].priority.compareTo(_tasks[a].priority);

        if (priorityComparison == 0) {
          // If same priority, sort by time (earlier times first)
          final timeA = _tasks[a].date.hour * 60 + _tasks[a].date.minute;
          final timeB = _tasks[b].date.hour * 60 + _tasks[b].date.minute;

          return timeA.compareTo(timeB);
        }

        return priorityComparison;
      }

      return daysComparison;
    });

    return overdueTasks;
  }

  // Modified to group upcoming tasks by specific dates and sort by priority and time
  Map<String, List<int>> _groupTasksByDate() {
    Map<String, List<int>> groupedTasks = {'Today': [], 'Tomorrow': []};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    for (int i = 0; i < _tasks.length; i++) {
      final taskDate = DateTime(
        _tasks[i].date.year,
        _tasks[i].date.month,
        _tasks[i].date.day,
      );

      // Skip overdue tasks - these will be shown separately in the overdue section
      final daysDifference = today.difference(taskDate).inDays;
      if (daysDifference >= 1) {
        continue; // Skip overdue tasks (1+ days)
      }

      // Build date section headers (with green color for Today)
      if (taskDate.compareTo(today) == 0) {
        groupedTasks['Today']!.add(i);
      } else if (taskDate.compareTo(tomorrow) == 0) {
        groupedTasks['Tomorrow']!.add(i);
      } else {
        // Format specific dates for upcoming tasks
        final dateKey = _formatDate(taskDate);
        if (!groupedTasks.containsKey(dateKey)) {
          groupedTasks[dateKey] = [];
        }
        groupedTasks[dateKey]!.add(i);
      }
    }

    // Sort each group by priority, and then by time for tasks with the same priority
    groupedTasks.forEach((key, indexList) {
      indexList.sort((a, b) {
        final taskA = _tasks[a];
        final taskB = _tasks[b];

        // Check if tasks are overdue but less than a day
        final isOverdueA = taskA.date.isBefore(now) && !taskA.isCompleted;
        final isOverdueB = taskB.date.isBefore(now) && !taskB.isCompleted;

        // Place same-day overdue tasks above non-overdue tasks
        if (isOverdueA && !isOverdueB) return -1;
        if (!isOverdueA && isOverdueB) return 1;

        // Compare priorities
        final priorityComparison = taskB.priority.compareTo(taskA.priority);

        // If priorities are equal, sort by time (earlier times first)
        if (priorityComparison == 0) {
          final timeA = taskA.date.hour * 60 + taskA.date.minute;
          final timeB = taskB.date.hour * 60 + taskB.date.minute;

          return timeA.compareTo(timeB); // Earlier times first
        }

        return priorityComparison; // If priorities are different, sort by priority
      });
    });

    return groupedTasks;
  }

  // Build task card with overdue indicator - now with date display for overdue section
  Widget _buildTaskCard(int index) {
    Task task = _tasks[index];

    // Check if task is overdue (deadline has passed)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
    final bool isOverdue = task.date.isBefore(now) && !task.isCompleted;
    final int daysOverdue = today.difference(taskDate).inDays;

    // Add a formatted date string for overdue tasks
    final String formattedDate = _getFormattedTaskDate(task.date);
    final bool showInOverdueSection = _showingOverdueTasks && daysOverdue >= 1;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Add a red border for overdue tasks
        side: isOverdue
            ? const BorderSide(color: Colors.red, width: 2.0)
            : BorderSide.none,
      ),
      color: task.color, // Use the task's color
      // Add InkWell to handle taps
      child: InkWell(
        onTap: () => _showTaskDetailsDialog(index),
        child: Opacity(
          opacity: task.isCompleted ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display date for overdue tasks at the top
                if (showInOverdueSection) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'Lexend',
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Task information column - moved to first position
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Priority indicator - changed to circle without text
                              if (task.priority > 1)
                                Container(
                                  width: 12,
                                  height: 12,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: task.priority == 3
                                        ? Colors.red
                                        : Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Lexend',
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Add time display to task card
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                // Show time of day with the task
                                TimeOfDay.fromDateTime(task.date)
                                    .format(context),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Lexend',
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              // Add overdue indicator
                              if (isOverdue) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'OVERDUE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Lexend',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (task.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              task.description,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Lexend',
                                color: Colors.grey,
                                fontWeight: FontWeight.w300,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Notification indicator
                    if (task.hasNotification)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),

                    // Checkbox for task completion - moved to last position
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          task.isCompleted = !task.isCompleted;
                          if (task.isCompleted) {
                            // Move to completed tasks list
                            _completedTasks.add(task);
                            _tasks.removeAt(index);
                            // Cancel notification if task is completed
                            if (task.hasNotification) {
                              NotificationService.cancelNotification(task);
                            }
                          }
                        });
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(
                          left: 12,
                        ), // Changed right margin to left
                        decoration: BoxDecoration(
                          color: task.isCompleted
                              ? Colors.green
                              : Colors.transparent,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: task.isCompleted
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),

                // Add days overdue text for significantly overdue tasks
                if (isOverdue && daysOverdue >= 1) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$daysOverdue days overdue',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Lexend',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Add task button (center)
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isMain = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMain ? 30 : 26, color: AppColors.primaryText),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: isMain ? 12 : 11,
              fontFamily: 'Lexend',
              fontWeight: isMain ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Update navigation to completed tasks with custom transition
  void _navigateToCompletedTasks() {
    AppTransitions.push(
      context,
      CompletedTasksScreen(
        completedTasks: _completedTasks,
        onTaskRestored: _handleTaskRestored,
      ),
    );
  }

  // Update navigation to chatbot with custom transition
  void _navigateToChatbot() {
    AppTransitions.push(
      context,
      const ChatbotScreen(),
    );
  }

  // Add a separate list for completed tasks
  void _handleTaskRestored(Task restoredTask) {
    setState(() {
      _tasks.add(restoredTask);
    });
  }

  // Helper method to format date and time for display
  String _formatDateTime(DateTime dateTime) {
    final date = '${dateTime.toLocal().toString().split(' ')[0]}';
    final time = '${TimeOfDay.fromDateTime(dateTime).format(context)}';
    return '$date at $time';
  }

  // Debug function to reset notification permission prompt
  Future<void> _resetNotificationPermissionRequest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notification_permission_requested');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Notification permission request has been reset. Restart app to see prompt again.'),
      ),
    );
  }

  // Restore the full task details dialog with edit functionality
  Future<void> _showTaskDetailsDialog(int index) async {
    Task task = _tasks[index];
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    DateTime selectedDate = task.date;
    TimeOfDay selectedTime = TimeOfDay(
      hour: task.date.hour,
      minute: task.date.minute,
    );
    bool isEditing = false;
    int selectedPriority = task.priority;
    bool hasNotification = task.hasNotification;
    int selectedNotificationTime = task.notificationMinutesBefore;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                isEditing ? 'Edit Task' : task.title,
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isEditing) ...[
                      // Editing UI
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Task Title',
                          labelStyle: TextStyle(fontFamily: 'Lexend'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description/Note',
                          labelStyle: TextStyle(fontFamily: 'Lexend'),
                        ),
                        maxLines: 2,
                        minLines: 1,
                      ),
                      const SizedBox(height: 16),

                      // Priority selector with new design
                      const Text(
                        'Priority Level:',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPriorityButton(
                            1,
                            'Low',
                            Colors.green,
                            selectedPriority,
                            (value) {
                              setState(() {
                                selectedPriority = value;
                              });
                            },
                          ),
                          _buildPriorityButton(
                            2,
                            'Medium',
                            Colors.orange,
                            selectedPriority,
                            (value) {
                              setState(() {
                                selectedPriority = value;
                              });
                            },
                          ),
                          _buildPriorityButton(
                            3,
                            'High',
                            Colors.red,
                            selectedPriority,
                            (value) {
                              setState(() {
                                selectedPriority = value;
                              });
                            },
                          ),
                        ],
                      ),

                      // Date picker
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(
                          'Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(
                            fontFamily: 'Lexend',
                            color: Colors.black87,
                          ),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(
                                days:
                                    365)), // Allow past dates for overdue tasks
                            lastDate: DateTime(2101),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF34A853),
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );
                            });
                          }
                        },
                      ),

                      // Time picker
                      ListTile(
                        title: Text(
                          'Time: ${selectedTime.format(context)}',
                          style: const TextStyle(
                            fontFamily: 'Lexend',
                            color: Colors.black87,
                          ),
                        ),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF34A853),
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              selectedTime = picked;
                              selectedDate = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );
                            });
                          }
                        },
                      ),

                      // Notification settings - Fix the setState to use setStateDialog
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Enable Notification:',
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: hasNotification,
                            onChanged: (value) {
                              setState(() {
                                // Fixed: use setStateDialog instead of setState
                                hasNotification = value;
                              });
                            },
                            activeColor: Colors.green,
                          ),
                        ],
                      ),

                      // Notification time selector (only shown when notifications are enabled)
                      if (hasNotification) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Notify me:',
                          style: TextStyle(fontFamily: 'Lexend'),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                          ),
                          value: selectedNotificationTime,
                          items: [
                            // Add short time options for testing
                            DropdownMenuItem(
                              value: 1,
                              child: Text(
                                '30 seconds before (testing)',
                                style: TextStyle(fontFamily: 'Lexend'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text(
                                '1 minute before (testing)',
                                style: TextStyle(fontFamily: 'Lexend'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 5,
                              child: Text(
                                '5 minutes before (testing)',
                                style: TextStyle(fontFamily: 'Lexend'),
                              ),
                            ),
                            // Original options
                            DropdownMenuItem(
                              value: 15,
                              child: Text(
                                '15 minutes before',
                                style: TextStyle(fontFamily: 'Lexend'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 30,
                              child: Text(
                                '30 minutes before',
                                style: TextStyle(fontFamily: 'Lexend'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 60,
                              child: Text(
                                '1 hour before',
                                style: TextStyle(fontFamily: 'Lexend'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 60 * 3,
                              child: Text(
                                '3 hours before',
                                style: TextStyle(fontFamily: 'Lexend'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 60 * 24,
                              child: Text(
                                '1 day before',
                                style: TextStyle(fontFamily: 'Lexend'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 60 * 24 * 2,
                              child: Text(
                                '2 days before',
                                style: TextStyle(fontFamily: 'Lexend'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 60 * 24 * 7,
                              child: Text(
                                '1 week before',
                                style: TextStyle(fontFamily: 'Lexend'),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                // Change from setState to setStateDialog
                                selectedNotificationTime = value;
                              });
                            }
                          },
                        ),
                      ],
                    ] else ...[
                      // View-only mode UI
                      Text(
                        'Title: ${task.title}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Lexend',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date & Time: ${_formatDateTime(task.date)}',
                        style: const TextStyle(fontFamily: 'Lexend'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Priority: ${task.priority == 1 ? 'Low' : task.priority == 2 ? 'Medium' : 'High'}',
                        style: const TextStyle(fontFamily: 'Lexend'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Notification: ${task.hasNotification ? _formatNotificationTime(task.notificationMinutesBefore) : 'Off'}',
                        style: const TextStyle(fontFamily: 'Lexend'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Description: ${task.description.isEmpty ? 'No description' : task.description}',
                        style: const TextStyle(fontFamily: 'Lexend'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (!isEditing) ...[
                  // View mode actions
                  TextButton(
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () {
                      _showDeleteConfirmationDialog(context, index);
                    },
                  ),
                  TextButton(
                    child: const Text(
                      'Edit',
                      style: TextStyle(color: Colors.blue),
                    ),
                    onPressed: () {
                      setState(() {
                        isEditing = true;
                      });
                    },
                  ),
                  TextButton(
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.black87),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ] else ...[
                  // Edit mode actions
                  TextButton(
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black87),
                    ),
                    onPressed: () {
                      setState(() {
                        isEditing = false;
                      });
                    },
                  ),
                  TextButton(
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: AppColors.saveAction,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        _showSaveConfirmationDialog(context, () {
                          try {
                            // Create updated task
                            final updatedTask = Task(
                              title: titleController.text,
                              date: selectedDate,
                              description: descriptionController.text,
                              isCompleted: task.isCompleted,
                              priority: selectedPriority,
                              color: task.color,
                              hasNotification: hasNotification,
                              notificationMinutesBefore:
                                  selectedNotificationTime,
                            );

                            // Update using the parent widget's setState instead of the dialog's setState
                            this.setState(() {
                              _tasks[index] = updatedTask;
                            });

                            // Schedule notification if enabled - with error handling
                            if (hasNotification) {
                              try {
                                NotificationService.updateNotification(
                                    updatedTask);
                              } catch (e) {
                                debugPrint('Error updating notification: $e');
                                // Continue with task update even if notification fails
                              }
                            }

                            Navigator.of(context).pop(); // Close dialog
                          } catch (e) {
                            // Show error message if task update fails
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error updating task: $e')),
                            );
                          }
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Task title cannot be empty')),
                        );
                      }
                    },
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  // New method: Confirmation dialog for saving edits - properly typed callback
  Future<void> _showSaveConfirmationDialog(
    BuildContext dialogContext,
    VoidCallback onSaveConfirm,
  ) async {
    return showDialog<void>(
      context: dialogContext,
      builder: (BuildContext innerContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Save Changes',
            style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Do you want to save your changes?',
            style: TextStyle(fontFamily: 'Lexend'),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black87),
              ),
              onPressed: () {
                Navigator.of(innerContext)
                    .pop(); // Close the confirmation dialog
              },
            ),
            TextButton(
              child: const Text(
                'Save',
                style: TextStyle(color: AppColors.saveAction),
              ),
              onPressed: () {
                Navigator.of(innerContext)
                    .pop(); // Close the confirmation dialog
                onSaveConfirm(); // Call the provided callback
              },
            ),
          ],
        );
      },
    );
  }

  // Modified to show priority selection as buttons
  Widget _buildPriorityButton(int value, String label, Color color,
      int groupValue, ValueChanged<int> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: groupValue == value ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: groupValue == value ? Colors.white : color,
            fontFamily: 'Lexend',
          ),
        ),
      ),
    );
  }

  // Fix notification time formatter for null safety
  String _formatNotificationTime(int? minutes) {
    // Handle null case
    if (minutes == null) return 'Off';

    // Continue with existing logic
    if (minutes < 60) {
      return '$minutes minutes before';
    } else if (minutes < 60 * 24) {
      return '${minutes ~/ 60} hour${minutes ~/ 60 > 1 ? "s" : ""} before';
    } else if (minutes < 60 * 24 * 7) {
      return '${minutes ~/ (60 * 24)} day${minutes ~/ (60 * 24) > 1 ? "s" : ""} before';
    } else {
      return '${minutes ~/ (60 * 24 * 7)} week${minutes ~/ (60 * 24 * 7) > 1 ? "s" : ""} before';
    }
  }

  // Add method to show the add task dialog
  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    int selectedPriority = 1;
    bool hasNotification = false;
    int selectedNotificationTime = 24 * 60; // Default 1 day before
    Color selectedColor = Colors.white;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Add New Task',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                        labelStyle: TextStyle(fontFamily: 'Lexend'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description/Note',
                        labelStyle: TextStyle(fontFamily: 'Lexend'),
                      ),
                      maxLines: 2,
                      minLines: 1,
                    ),
                    const SizedBox(height: 16),

                    // Priority selector
                    const Text(
                      'Priority Level:',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPriorityButton(
                          1,
                          'Low',
                          Colors.green,
                          selectedPriority,
                          (value) {
                            setState(() {
                              selectedPriority = value;
                            });
                          },
                        ),
                        _buildPriorityButton(
                          2,
                          'Medium',
                          Colors.orange,
                          selectedPriority,
                          (value) {
                            setState(() {
                              selectedPriority = value;
                            });
                          },
                        ),
                        _buildPriorityButton(
                          3,
                          'High',
                          Colors.red,
                          selectedPriority,
                          (value) {
                            setState(() {
                              selectedPriority = value;
                            });
                          },
                        ),
                      ],
                    ),

                    // Date picker
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        'Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          color: Colors.black87,
                        ),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF34A853),
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                          });
                        }
                      },
                    ),

                    // Time picker
                    ListTile(
                      title: Text(
                        'Time: ${selectedTime.format(context)}',
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          color: Colors.black87,
                        ),
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF34A853),
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTime = picked;
                            selectedDate = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                          });
                        }
                      },
                    ),

                    // Notification settings
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Enable Notification:',
                          style: TextStyle(
                            fontFamily: 'Lexend',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Switch(
                          value: hasNotification,
                          onChanged: (value) {
                            setState(() {
                              hasNotification = value;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),

                    // Notification time selector (only shown when notifications are enabled)
                    if (hasNotification) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Notify me:',
                        style: TextStyle(fontFamily: 'Lexend'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                        ),
                        value: selectedNotificationTime,
                        items: [
                          // Add short time options for testing
                          DropdownMenuItem(
                            value: 1,
                            child: Text(
                              '30 seconds before (testing)',
                              style: TextStyle(fontFamily: 'Lexend'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text(
                              '1 minute before (testing)',
                              style: TextStyle(fontFamily: 'Lexend'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 5,
                            child: Text(
                              '5 minutes before (testing)',
                              style: TextStyle(fontFamily: 'Lexend'),
                            ),
                          ),
                          // Original options
                          DropdownMenuItem(
                            value: 15,
                            child: Text(
                              '15 minutes before',
                              style: TextStyle(fontFamily: 'Lexend'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 30,
                            child: Text(
                              '30 minutes before',
                              style: TextStyle(fontFamily: 'Lexend'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 60,
                            child: Text(
                              '1 hour before',
                              style: TextStyle(fontFamily: 'Lexend'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 60 * 3,
                            child: Text(
                              '3 hours before',
                              style: TextStyle(fontFamily: 'Lexend'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 60 * 24,
                            child: Text(
                              '1 day before',
                              style: TextStyle(fontFamily: 'Lexend'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 60 * 24 * 2,
                            child: Text(
                              '2 days before',
                              style: TextStyle(fontFamily: 'Lexend'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 60 * 24 * 7,
                            child: Text(
                              '1 week before',
                              style: TextStyle(fontFamily: 'Lexend'),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedNotificationTime = value;
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black87),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text(
                    'Add',
                    style: TextStyle(
                      color: AppColors.saveAction,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      // Create new task
                      final newTask = Task(
                        title: titleController.text,
                        date: selectedDate,
                        description: descriptionController.text,
                        priority: selectedPriority,
                        color: selectedColor,
                        hasNotification: hasNotification,
                        notificationMinutesBefore: selectedNotificationTime,
                      );

                      // Add to task list
                      this.setState(() {
                        _tasks.add(newTask);
                      });

                      // Schedule notification if enabled
                      if (hasNotification) {
                        try {
                          NotificationService.scheduleNotification(newTask);
                        } catch (e) {
                          debugPrint('Error scheduling notification: $e');
                        }
                      }

                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Task title cannot be empty')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Fix the delete confirmation dialog to properly handle context
  Future<void> _showDeleteConfirmationDialog(
    BuildContext dialogContext,
    int index,
  ) async {
    return showDialog(
      context: dialogContext,
      builder: (BuildContext innerContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Confirm Deletion',
            style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to delete this task?',
            style: TextStyle(fontFamily: 'Lexend'),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black87),
              ),
              onPressed: () {
                Navigator.of(innerContext)
                    .pop(); // Close the confirmation dialog
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                setState(() {
                  _tasks.removeAt(index);
                });
                Navigator.of(innerContext)
                    .pop(); // Close the confirmation dialog
                Navigator.of(dialogContext)
                    .pop(); // Close the task details dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Helper method to format task date in a readable format
  String _getFormattedTaskDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Define weekdays and months for formatting
    final List<String> weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    final weekday = weekdays[date.weekday - 1];
    final day = date.day;
    final month = months[date.month - 1];

    return '$weekday, $day $month';
  }
}
