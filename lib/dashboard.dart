import 'dart:async';
import 'package:flexitask_updated/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chatbot.dart';
import 'profile.dart';
import 'completed.dart';
import 'theme_constants.dart';
import 'local_notification.dart';
import 'dart:io';
import 'transitions.dart';

class Task {
  String title;
  DateTime date;
  String description;
  bool isCompleted;
  int priority;
  Color color;
  bool hasNotification;
  int notificationMinutesBefore;

  Task({
    required this.title,
    required this.date,
    this.description = '',
    this.isCompleted = false,
    this.priority = 1,
    this.color = Colors.white,
    this.hasNotification = false,
    this.notificationMinutesBefore = 24 * 60,
  });
}

class NotificationService {
  static final List<Map<String, dynamic>> _scheduledNotifications = [];

  static Future<void> initialize() async {
    await LocalNotificationService.initialize();
    debugPrint('Mock notification service redirecting to real service');
  }

  static Future<void> scheduleNotification(Task task) async {
    await LocalNotificationService.scheduleNotification(task);
    if (!task.hasNotification) return;
    final scheduledTime =
        task.date.subtract(Duration(minutes: task.notificationMinutesBefore));
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

  static Future<void> cancelNotification(Task task) async {
    await LocalNotificationService.cancelNotification(task);
    _scheduledNotifications
        .removeWhere((notification) => notification['id'] == task.hashCode);
  }

  static Future<void> updateNotification(Task task) async {
    await LocalNotificationService.updateNotification(task);
    await cancelNotification(task);
    if (task.hasNotification) {
      await scheduleNotification(task);
    }
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _profileImagePath;
  int _selectedIndex = 1;
  bool _showingOverdueTasks = false;
  Timer? _taskStatusTimer;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    setState(() {
      _selectedIndex = 1;
    });
    _startTaskStatusCheckTimer();
  }

  @override
  void dispose() {
    _taskStatusTimer?.cancel();
    super.dispose();
  }

  void _startTaskStatusCheckTimer() {
    _taskStatusTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      setState(() {});
    });
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('profileImagePath');
    if (savedPath != null && savedPath.isNotEmpty) {
      setState(() {
        _profileImagePath = savedPath;
      });
    }
  }

  Widget _buildProfileImage() {
    if (_profileImagePath != null) {
      if (_profileImagePath!.startsWith('/') ||
          _profileImagePath!.startsWith('file:')) {
        return Image.file(
          File(_profileImagePath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset('assets/images/logo.png', fit: BoxFit.cover);
          },
        );
      } else {
        return Image.asset(
          _profileImagePath!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset('assets/images/logo.png', fit: BoxFit.cover);
          },
        );
      }
    } else {
      return Image.asset('assets/images/logo.png', fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: AppColors.darkBackground,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(color: AppColors.background),
                  child: Column(
                    children: [
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
                            GestureDetector(
                              onLongPress: () =>
                                  _resetNotificationPermissionRequest(),
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 40.0,
                                width: 40.0,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                AppTransitions.push(
                                        context, const ProfileScreen())
                                    .then((_) => _loadProfileImage());
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFFD9D9D9), width: 2),
                                ),
                                child: ClipOval(child: _buildProfileImage()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 16),
                        decoration:
                            const BoxDecoration(color: AppColors.background),
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
                      const Divider(
                          height: 1, thickness: 1, color: Colors.grey),
                      Expanded(
                        child: Container(
                          color: const Color.fromARGB(255, 230, 230, 230),
                          child: StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _firestoreService.getTasksStream(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              }
                              final tasks = snapshot.data ?? [];
                              final groupedTasks = _groupTasksByDate(tasks);
                              final overdueTasksCount =
                                  _getOverdueTasksCount(tasks);
                              return ListView(
                                padding: const EdgeInsets.all(12),
                                children: [
                                  if (_showingOverdueTasks) ...[
                                    _buildOverdueHeader(overdueTasksCount),
                                    ...getOverdueTasks(tasks).map((index) =>
                                        _buildTaskCard(tasks[index], index)),
                                  ] else ...[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildDateHeader('Today',
                                            isToday: true),
                                        if (overdueTasksCount > 0)
                                          _buildOverdueCounter(
                                              overdueTasksCount),
                                      ],
                                    ),
                                    if (groupedTasks['Today']!.isNotEmpty) ...[
                                      ...groupedTasks['Today']!.map((index) =>
                                          _buildTaskCard(tasks[index], index)),
                                    ],
                                  ],
                                  if (!_showingOverdueTasks) ...[
                                    if (groupedTasks['Tomorrow']!
                                        .isNotEmpty) ...[
                                      _buildDateHeader('Tomorrow'),
                                      ...groupedTasks['Tomorrow']!.map(
                                          (index) => _buildTaskCard(
                                              tasks[index], index)),
                                    ],
                                    for (var entry in groupedTasks.entries)
                                      if (entry.key != 'Today' &&
                                          entry.key != 'Tomorrow' &&
                                          entry.value.isNotEmpty) ...[
                                        _buildDateHeader(entry.key),
                                        ...entry.value.map((index) =>
                                            _buildTaskCard(
                                                tasks[index], index)),
                                      ],
                                  ],
                                ],
                              );
                            },
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                offset: const Offset(0, -1),
                blurRadius: 5,
                color: Colors.black.withOpacity(0.1)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            switch (index) {
              case 0:
                AppTransitions.push(context, const ChatbotScreen()).then((_) {
                  setState(() {
                    _selectedIndex = 1;
                  });
                });
                break;
              case 2:
                AppTransitions.push(
                  context,
                  CompletedTasksScreen(
                    onTaskRestored: _handleTaskRestored,
                  ),
                ).then((_) {
                  setState(() {
                    _selectedIndex = 1;
                  });
                });
                break;
              case 1:
                _showAddTaskDialog();
                break;
            }
          },
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
              fontFamily: 'Lexend', fontWeight: FontWeight.w500, fontSize: 12),
          unselectedLabelStyle: const TextStyle(
              fontFamily: 'Lexend',
              fontWeight: FontWeight.normal,
              fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.psychology), label: 'Assistant'),
            BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                activeIcon: Icon(Icons.add_circle),
                label: 'Add Task'),
            BottomNavigationBarItem(
                icon: Icon(Icons.check_circle_outline),
                activeIcon: Icon(Icons.check_circle),
                label: 'Completed'),
          ],
        ),
      ),
    );
  }

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
                borderRadius: BorderRadius.all(Radius.circular(12))),
            child: const Text(
              "Overdue Tasks",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lexend',
                  fontSize: 14),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showingOverdueTasks = false;
              });
            },
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text("Back to Today",
                style: TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
          ),
        ],
      ),
    );
  }

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
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text("Overdue: $count",
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lexend',
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  int _getOverdueTasksCount(List<Map<String, dynamic>> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return tasks.where((taskMap) {
      final task = taskMap['task'] as Task;
      if (task.isCompleted) return false;
      final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
      final daysDifference = today.difference(taskDate).inDays;
      return daysDifference >= 1;
    }).length;
  }

  List<int> getOverdueTasks(List<Map<String, dynamic>> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    List<int> overdueTasks = [];
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i]['task'] as Task;
      if (task.isCompleted) continue;
      final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
      final daysDifference = today.difference(taskDate).inDays;
      if (daysDifference >= 1) {
        overdueTasks.add(i);
      }
    }
    overdueTasks.sort((a, b) {
      final taskA = tasks[a]['task'] as Task;
      final taskB = tasks[b]['task'] as Task;
      final taskDateA =
          DateTime(taskA.date.year, taskA.date.month, taskA.date.day);
      final taskDateB =
          DateTime(taskB.date.year, taskB.date.month, taskB.date.day);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final daysOverdueA = today.difference(taskDateA).inDays;
      final daysOverdueB = today.difference(taskDateB).inDays;
      final daysComparison = daysOverdueB.compareTo(daysOverdueA);
      if (daysComparison == 0) {
        final priorityComparison = taskB.priority.compareTo(taskA.priority);
        if (priorityComparison == 0) {
          final timeA = taskA.date.hour * 60 + taskA.date.minute;
          final timeB = taskB.date.hour * 60 + taskB.date.minute;
          return timeA.compareTo(timeB);
        }
        return priorityComparison;
      }
      return daysComparison;
    });
    return overdueTasks;
  }

  Map<String, List<int>> _groupTasksByDate(List<Map<String, dynamic>> tasks) {
    Map<String, List<int>> groupedTasks = {'Today': [], 'Tomorrow': []};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i]['task'] as Task;
      final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
      final daysDifference = today.difference(taskDate).inDays;
      if (daysDifference >= 1) {
        continue;
      }
      if (taskDate.compareTo(today) == 0) {
        groupedTasks['Today']!.add(i);
      } else if (taskDate.compareTo(tomorrow) == 0) {
        groupedTasks['Tomorrow']!.add(i);
      } else {
        final dateKey = _formatDate(taskDate);
        if (!groupedTasks.containsKey(dateKey)) {
          groupedTasks[dateKey] = [];
        }
        groupedTasks[dateKey]!.add(i);
      }
    }
    groupedTasks.forEach((key, indexList) {
      indexList.sort((a, b) {
        final taskA = tasks[a]['task'] as Task;
        final taskB = tasks[b]['task'] as Task;
        final isOverdueA = taskA.date.isBefore(now) && !taskA.isCompleted;
        final isOverdueB = taskB.date.isBefore(now) && !taskB.isCompleted;
        if (isOverdueA && !isOverdueB) return -1;
        if (!isOverdueA && isOverdueB) return 1;
        final priorityComparison = taskB.priority.compareTo(taskA.priority);
        if (priorityComparison == 0) {
          final timeA = taskA.date.hour * 60 + taskA.date.minute;
          final timeB = taskB.date.hour * 60 + taskB.date.minute;
          return timeA.compareTo(timeB);
        }
        return priorityComparison;
      });
    });
    return groupedTasks;
  }

  Widget _buildTaskCard(Map<String, dynamic> taskMap, int index) {
    Task task = taskMap['task'] as Task;
    String taskId = taskMap['id'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
    final bool isOverdue = task.date.isBefore(now) && !task.isCompleted;
    final int daysOverdue = today.difference(taskDate).inDays;
    final String formattedDate = _getFormattedTaskDate(task.date);
    final bool showInOverdueSection = _showingOverdueTasks && daysOverdue >= 1;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue
            ? const BorderSide(color: Colors.red, width: 2.0)
            : BorderSide.none,
      ),
      color: task.color,
      child: InkWell(
        onTap: () => _showTaskDetailsDialog(taskId, task),
        child: Opacity(
          opacity: task.isCompleted ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
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
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                TimeOfDay.fromDateTime(task.date)
                                    .format(context),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Lexend',
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isOverdue) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4)),
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
                    if (task.hasNotification)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.notifications_active,
                            color: Colors.white, size: 10),
                      ),
                    GestureDetector(
                      onTap: () async {
                        try {
                          await _firestoreService.completeTask(taskId, task);
                          if (task.hasNotification) {
                            await NotificationService.cancelNotification(task);
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Error completing task: $e')));
                        }
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                          color: task.isCompleted
                              ? Colors.green
                              : Colors.transparent,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: task.isCompleted
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                  ],
                ),
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

  Widget _buildNavItem(
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool isMain = false}) {
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

  void _navigateToCompletedTasks() {
    AppTransitions.push(
        context, CompletedTasksScreen(onTaskRestored: _handleTaskRestored));
  }

  void _navigateToChatbot() {
    AppTransitions.push(context, const ChatbotScreen());
  }

  void _handleTaskRestored(Task restoredTask) {
    // No need to call _firestoreService.addTask, as it's handled in completed.dart
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task restored to your list')),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final date = '${dateTime.toLocal().toString().split(' ')[0]}';
    final time = '${TimeOfDay.fromDateTime(dateTime).format(context)}';
    return '$date at $time';
  }

  Future<void> _resetNotificationPermissionRequest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notification_permission_requested');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Notification permission request has been reset. Restart app to see prompt again.')),
    );
  }

  Future<void> _showTaskDetailsDialog(String taskId, Task task) async {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    DateTime selectedDate = task.date;
    TimeOfDay selectedTime =
        TimeOfDay(hour: task.date.hour, minute: task.date.minute);
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
                    fontFamily: 'Lexend', fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isEditing) ...[
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                            labelText: 'Task Title',
                            labelStyle: TextStyle(fontFamily: 'Lexend')),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                            labelText: 'Description/Note',
                            labelStyle: TextStyle(fontFamily: 'Lexend')),
                        maxLines: 2,
                        minLines: 1,
                      ),
                      const SizedBox(height: 16),
                      const Text('Priority Level:',
                          style: TextStyle(
                              fontFamily: 'Lexend',
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPriorityButton(
                              1, 'Low', Colors.green, selectedPriority,
                              (value) {
                            setState(() {
                              selectedPriority = value;
                            });
                          }),
                          _buildPriorityButton(
                              2, 'Medium', Colors.orange, selectedPriority,
                              (value) {
                            setState(() {
                              selectedPriority = value;
                            });
                          }),
                          _buildPriorityButton(
                              3, 'High', Colors.red, selectedPriority, (value) {
                            setState(() {
                              selectedPriority = value;
                            });
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(
                            'Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
                            style: const TextStyle(
                                fontFamily: 'Lexend', color: Colors.black87)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate: DateTime(2101),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF34A853),
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black)),
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
                                  selectedTime.minute);
                            });
                          }
                        },
                      ),
                      ListTile(
                        title: Text('Time: ${selectedTime.format(context)}',
                            style: const TextStyle(
                                fontFamily: 'Lexend', color: Colors.black87)),
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
                                        onSurface: Colors.black)),
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
                                  selectedTime.minute);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Enable Notification:',
                              style: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontWeight: FontWeight.bold)),
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
                      if (hasNotification) ...[
                        const SizedBox(height: 8),
                        const Text('Notify me:',
                            style: TextStyle(fontFamily: 'Lexend')),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10)),
                          value: selectedNotificationTime,
                          items: [
                            DropdownMenuItem(
                                value: 1,
                                child: Text('30 seconds before (testing)',
                                    style: TextStyle(fontFamily: 'Lexend'))),
                            DropdownMenuItem(
                                value: 2,
                                child: Text('1 minute before (testing)',
                                    style: TextStyle(fontFamily: 'Lexend'))),
                            DropdownMenuItem(
                                value: 5,
                                child: Text('5 minutes before (testing)',
                                    style: TextStyle(fontFamily: 'Lexend'))),
                            DropdownMenuItem(
                                value: 15,
                                child: Text('15 minutes before',
                                    style: TextStyle(fontFamily: 'Lexend'))),
                            DropdownMenuItem(
                                value: 30,
                                child: Text('30 minutes before',
                                    style: TextStyle(fontFamily: 'Lexend'))),
                            DropdownMenuItem(
                                value: 60,
                                child: Text('1 hour before',
                                    style: TextStyle(fontFamily: 'Lexend'))),
                            DropdownMenuItem(
                                value: 60 * 3,
                                child: Text('3 hours before',
                                    style: TextStyle(fontFamily: 'Lexend'))),
                            DropdownMenuItem(
                                value: 60 * 24,
                                child: Text('1 day before',
                                    style: TextStyle(fontFamily: 'Lexend'))),
                            DropdownMenuItem(
                                value: 60 * 24 * 2,
                                child: Text('2 days before',
                                    style: TextStyle(fontFamily: 'Lexend'))),
                            DropdownMenuItem(
                                value: 60 * 24 * 7,
                                child: Text('1 week before',
                                    style: TextStyle(fontFamily: 'Lexend'))),
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
                    ] else ...[
                      Text('Title: ${task.title}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'Lexend')),
                      const SizedBox(height: 8),
                      Text('Date & Time: ${_formatDateTime(task.date)}',
                          style: const TextStyle(fontFamily: 'Lexend')),
                      const SizedBox(height: 8),
                      Text(
                          'Priority: ${task.priority == 1 ? 'Low' : task.priority == 2 ? 'Medium' : 'High'}',
                          style: const TextStyle(fontFamily: 'Lexend')),
                      const SizedBox(height: 8),
                      Text(
                          'Notification: ${task.hasNotification ? _formatNotificationTime(task.notificationMinutesBefore) : 'Off'}',
                          style: const TextStyle(fontFamily: 'Lexend')),
                      const SizedBox(height: 8),
                      Text(
                          'Description: ${task.description.isEmpty ? 'No description' : task.description}',
                          style: const TextStyle(fontFamily: 'Lexend')),
                    ],
                  ],
                ),
              ),
              actions: [
                if (!isEditing) ...[
                  TextButton(
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      _showDeleteConfirmationDialog(context, taskId);
                    },
                  ),
                  TextButton(
                    child: const Text('Edit',
                        style: TextStyle(color: Colors.blue)),
                    onPressed: () {
                      setState(() {
                        isEditing = true;
                      });
                    },
                  ),
                  TextButton(
                    child: const Text('Close',
                        style: TextStyle(color: Colors.black87)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ] else ...[
                  TextButton(
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.black87)),
                    onPressed: () {
                      setState(() {
                        isEditing = false;
                      });
                    },
                  ),
                  TextButton(
                    child: const Text('Save',
                        style: TextStyle(
                            color: AppColors.saveAction,
                            fontWeight: FontWeight.bold)),
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        _showSaveConfirmationDialog(context, () async {
                          try {
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
                            await _firestoreService.updateTask(
                                taskId, updatedTask);
                            if (hasNotification) {
                              try {
                                await NotificationService.updateNotification(
                                    updatedTask);
                              } catch (e) {
                                debugPrint('Error updating notification: $e');
                              }
                            }
                            Navigator.of(context).pop();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Error updating task: $e')));
                          }
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Task title cannot be empty')));
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

  Future<void> _showSaveConfirmationDialog(
      BuildContext dialogContext, VoidCallback onSaveConfirm) async {
    return showDialog<void>(
      context: dialogContext,
      builder: (BuildContext innerContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Save Changes',
              style:
                  TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.bold)),
          content: const Text('Do you want to save your changes?',
              style: TextStyle(fontFamily: 'Lexend')),
          actions: [
            TextButton(
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.black87)),
              onPressed: () {
                Navigator.of(innerContext).pop();
              },
            ),
            TextButton(
              child: const Text('Save',
                  style: TextStyle(color: AppColors.saveAction)),
              onPressed: () {
                Navigator.of(innerContext).pop();
                onSaveConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPriorityButton(int value, String label, Color color,
      int groupValue, ValueChanged<int> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: groupValue == value ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: groupValue == value ? Colors.white : color,
              fontFamily: 'Lexend'),
        ),
      ),
    );
  }

  String _formatNotificationTime(int? minutes) {
    if (minutes == null) return 'Off';
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

  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    int selectedPriority = 1;
    bool hasNotification = false;
    int selectedNotificationTime = 24 * 60;
    Color selectedColor = Colors.white;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Add New Task',
                  style: TextStyle(
                      fontFamily: 'Lexend', fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                          labelText: 'Task Title',
                          labelStyle: TextStyle(fontFamily: 'Lexend')),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                          labelText: 'Description/Note',
                          labelStyle: TextStyle(fontFamily: 'Lexend')),
                      maxLines: 2,
                      minLines: 1,
                    ),
                    const SizedBox(height: 16),
                    const Text('Priority Level:',
                        style: TextStyle(
                            fontFamily: 'Lexend', fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPriorityButton(
                            1, 'Low', Colors.green, selectedPriority, (value) {
                          setState(() {
                            selectedPriority = value;
                          });
                        }),
                        _buildPriorityButton(
                            2, 'Medium', Colors.orange, selectedPriority,
                            (value) {
                          setState(() {
                            selectedPriority = value;
                          });
                        }),
                        _buildPriorityButton(
                            3, 'High', Colors.red, selectedPriority, (value) {
                          setState(() {
                            selectedPriority = value;
                          });
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                          'Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(
                              fontFamily: 'Lexend', color: Colors.black87)),
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
                                      onSurface: Colors.black)),
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
                                selectedTime.minute);
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: Text('Time: ${selectedTime.format(context)}',
                          style: const TextStyle(
                              fontFamily: 'Lexend', color: Colors.black87)),
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
                                      onSurface: Colors.black)),
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
                                selectedTime.minute);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Enable Notification:',
                            style: TextStyle(
                                fontFamily: 'Lexend',
                                fontWeight: FontWeight.bold)),
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
                    if (hasNotification) ...[
                      const SizedBox(height: 8),
                      const Text('Notify me:',
                          style: TextStyle(fontFamily: 'Lexend')),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 10)),
                        value: selectedNotificationTime,
                        items: [
                          DropdownMenuItem(
                              value: 1,
                              child: Text('30 seconds before (testing)',
                                  style: TextStyle(fontFamily: 'Lexend'))),
                          DropdownMenuItem(
                              value: 2,
                              child: Text('1 minute before (testing)',
                                  style: TextStyle(fontFamily: 'Lexend'))),
                          DropdownMenuItem(
                              value: 5,
                              child: Text('5 minutes before (testing)',
                                  style: TextStyle(fontFamily: 'Lexend'))),
                          DropdownMenuItem(
                              value: 15,
                              child: Text('15 minutes before',
                                  style: TextStyle(fontFamily: 'Lexend'))),
                          DropdownMenuItem(
                              value: 30,
                              child: Text('30 minutes before',
                                  style: TextStyle(fontFamily: 'Lexend'))),
                          DropdownMenuItem(
                              value: 60,
                              child: Text('1 hour before',
                                  style: TextStyle(fontFamily: 'Lexend'))),
                          DropdownMenuItem(
                              value: 60 * 3,
                              child: Text('3 hours before',
                                  style: TextStyle(fontFamily: 'Lexend'))),
                          DropdownMenuItem(
                              value: 60 * 24,
                              child: Text('1 day before',
                                  style: TextStyle(fontFamily: 'Lexend'))),
                          DropdownMenuItem(
                              value: 60 * 24 * 2,
                              child: Text('2 days before',
                                  style: TextStyle(fontFamily: 'Lexend'))),
                          DropdownMenuItem(
                              value: 60 * 24 * 7,
                              child: Text('1 week before',
                                  style: TextStyle(fontFamily: 'Lexend'))),
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
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.black87)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Add',
                      style: TextStyle(
                          color: AppColors.saveAction,
                          fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    if (titleController.text.isNotEmpty) {
                      final newTask = Task(
                        title: titleController.text,
                        date: selectedDate,
                        description: descriptionController.text,
                        priority: selectedPriority,
                        color: selectedColor,
                        hasNotification: hasNotification,
                        notificationMinutesBefore: selectedNotificationTime,
                      );
                      try {
                        await _firestoreService.addTask(newTask);
                        if (hasNotification) {
                          try {
                            await NotificationService.scheduleNotification(
                                newTask);
                          } catch (e) {
                            debugPrint('Error scheduling notification: $e');
                          }
                        }
                        Navigator.of(context).pop();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error adding task: $e')));
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Task title cannot be empty')));
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

  Future<void> _showDeleteConfirmationDialog(
      BuildContext dialogContext, String taskId) async {
    return showDialog(
      context: dialogContext,
      builder: (BuildContext innerContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Confirm Deletion',
              style:
                  TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to delete this task?',
              style: TextStyle(fontFamily: 'Lexend')),
          actions: [
            TextButton(
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.black87)),
              onPressed: () {
                Navigator.of(innerContext).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  await _firestoreService.deleteTask(taskId);
                  Navigator.of(innerContext).pop();
                  Navigator.of(dialogContext).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting task: $e')));
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _getFormattedTaskDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
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
