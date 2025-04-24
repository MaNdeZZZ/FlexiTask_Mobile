import 'package:flutter/material.dart';
import 'chatbot.dart';
import 'profile.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this import

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

// The mock NotificationService is already implemented in this file and doesn't
// require the flutter_local_notifications package, so we keep it as is.
class NotificationService {
  // List to track scheduled notifications
  static final List<Map<String, dynamic>> _scheduledNotifications = [];

  static Future<void> initialize() async {
    // Mock initialization
    debugPrint('Mock notification service initialized');
  }

  // Schedule a notification for a task
  static Future<void> scheduleNotification(Task task) async {
    if (!task.hasNotification) {
      return; // Skip if notifications are disabled for this task
    }

    // Calculate notification time (task time minus notificationMinutesBefore)
    final scheduledTime = task.date.subtract(
      Duration(minutes: task.notificationMinutesBefore),
    );

    // Check if the notification time is in the future
    if (scheduledTime.isBefore(DateTime.now())) {
      return; // Skip if notification time has already passed
    }

    // Store notification info
    _scheduledNotifications.add({
      'id': task.hashCode,
      'title': 'Upcoming Task: ${task.title}',
      'body':
          task.description.isEmpty
              ? 'This task is due soon!'
              : task.description,
      'scheduledTime': scheduledTime,
    });

    debugPrint('Mock notification scheduled for: ${scheduledTime.toString()}');
    debugPrint('Active notifications: ${_scheduledNotifications.length}');
  }

  // Cancel notification for a task
  static Future<void> cancelNotification(Task task) async {
    _scheduledNotifications.removeWhere(
      (notification) => notification['id'] == task.hashCode,
    );
    debugPrint('Mock notification canceled for task: ${task.title}');
    debugPrint('Remaining notifications: ${_scheduledNotifications.length}');
  }

  // Update notification for a task (cancel and reschedule)
  static Future<void> updateNotification(Task task) async {
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
    NotificationService.initialize();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const DashboardScreen(), // Updated class name here
    );
  }
}

class DashboardScreen extends StatefulWidget {
  // Renamed from TodoListScreen
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState(); // Updated state class name
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Renamed from _TodoListScreenState
  // Task list to store all tasks
  final List<Task> _tasks = [
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

  @override
  Widget build(BuildContext context) {
    // Group tasks by date
    final groupedTasks = _groupTasksByDate();

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.black,
          child: Column(
            children: [
              // Main content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Column(
                    children: [
                      // Logo and profile section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Replace text with logo image
                            Image.asset(
                              'assets/images/logo.png',
                              height:
                                  40.0, // Smaller size appropriate for the header
                              width: 40.0,
                            ),

                            // Profile picture - made clickable
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileScreen(),
                                  ),
                                ).then(
                                  (_) => _loadProfileImage(),
                                ); // Reload when returning from profile
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
                                  child:
                                      _profileImagePath != null
                                          ? Image.asset(
                                            _profileImagePath!,
                                            fit: BoxFit.cover,
                                          )
                                          : Container(color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tagline
                      Container(
                        padding: const EdgeInsets.only(bottom: 16),
                        decoration: const BoxDecoration(color: Colors.white),
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
                              // Today section
                              if (groupedTasks['Today']!.isNotEmpty) ...[
                                _buildDateHeader('Today', isToday: true),
                                ...groupedTasks['Today']!.map(
                                  (index) => _buildTaskCard(index),
                                ),
                              ],

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

      // Floating action buttons - improved positioning
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // AI button (left)
            FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatbotScreen(),
                  ),
                );
              },
              backgroundColor: Colors.white, // Changed to white
              child: const Icon(Icons.psychology, color: Colors.black),
            ),

            // Add task button (right)
            FloatingActionButton(
              onPressed: _showAddTaskDialog,
              backgroundColor: Colors.white, // Changed to white
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // Modified to group upcoming tasks by specific dates and sort by priority
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

    // Sort each group by priority (highest first)
    groupedTasks.forEach((key, indexList) {
      indexList.sort(
        (a, b) => _tasks[b].priority.compareTo(_tasks[a].priority),
      );
    });

    return groupedTasks;
  }

  // Format date to a readable string for headers
  String _formatDate(DateTime date) {
    // Format: "Monday, 25 April"
    final List<String> weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
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
      'December',
    ];

    final weekday = weekdays[date.weekday - 1]; // weekday is 1-7 in Dart
    final day = date.day;
    final month = months[date.month - 1];

    return '$weekday, $day $month';
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
            color: isToday ? const Color(0xFF34A853) : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isToday ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lexend',
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // Build task card with tap functionality, status tracking, custom color and notification indicator
  Widget _buildTaskCard(int index) {
    Task task = _tasks[index];
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: task.color, // Use the task's color
      // Add InkWell to handle taps
      child: InkWell(
        onTap: () => _showTaskDetailsDialog(index),
        child: Opacity(
          opacity: task.isCompleted ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Task information column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Priority indicator
                          if (task.priority > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color:
                                    task.priority == 3
                                        ? Colors.red
                                        : Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "P${task.priority}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
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

                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Lexend',
                                decoration:
                                    task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                              ),
                            ),
                          ),
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
                // Checkbox
                GestureDetector(
                  onTap: () {
                    setState(() {
                      task.isCompleted = !task.isCompleted;
                    });
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color:
                          task.isCompleted ? Colors.grey : Colors.transparent,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child:
                        task.isCompleted
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
          ),
        ),
      ),
    );
  }

  // Dialog to add a new task
  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    int selectedPriority = 1;
    bool hasNotification = false;
    int selectedNotificationTime =
        24 * 60; // Default: 1 day before (in minutes)

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white, // Changed from Color(0xFFD9D9D9)
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
                      maxLines: 3, // Limit maximum lines for description
                      minLines: 1, // Set minimum lines
                    ),
                    const SizedBox(height: 16),
                    // Date picker
                    ListTile(
                      title: Text(
                        'Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          color:
                              Colors
                                  .black87, // Changed from white to black for visibility
                        ),
                      ),
                      trailing: const Icon(
                        Icons.calendar_today,
                        color:
                            Colors
                                .black87, // Changed from white to black for visibility
                      ),
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
                                  primary: Color(
                                    0xFF34A853,
                                  ), // Green color for selected date
                                  onPrimary:
                                      Colors
                                          .white, // White text for selected date
                                  onSurface:
                                      Colors.black, // Black text for calendar
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null && picked != selectedDate) {
                          setStateDialog(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),

                    // Priority selector
                    const SizedBox(height: 16),
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
                            setStateDialog(() {
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
                            setStateDialog(() {
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
                            setStateDialog(() {
                              selectedPriority = value;
                            });
                          },
                        ),
                      ],
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
                            setStateDialog(() {
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        value: selectedNotificationTime,
                        items: [
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
                            setStateDialog(() {
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
                      color: Color(0xFF34A853),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final newTask = Task(
                        title: titleController.text,
                        date: selectedDate,
                        description: descriptionController.text,
                        priority: selectedPriority,
                        color: Colors.white, // Set default color
                        hasNotification: hasNotification,
                        notificationMinutesBefore: selectedNotificationTime,
                      );

                      setState(() {
                        _tasks.add(newTask);
                      });

                      // Schedule notification if enabled
                      if (hasNotification) {
                        NotificationService.scheduleNotification(newTask);
                      }

                      Navigator.of(context).pop();
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

  // Helper method to build priority selection buttons
  Widget _buildPriorityButton(
    int value,
    String label,
    Color color,
    int selectedValue,
    Function(int) onSelect,
  ) {
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selectedValue == value ? color : Colors.transparent,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selectedValue == value ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // Dialog to view, edit, or delete a task
  Future<void> _showTaskDetailsDialog(int index) async {
    Task task = _tasks[index];
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    DateTime selectedDate = task.date;
    bool isEditing = false;
    int selectedPriority = task.priority;
    bool hasNotification = task.hasNotification;
    int selectedNotificationTime = task.notificationMinutesBefore;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white, // Changed from Color(0xFFD9D9D9)
              title: Text(
                isEditing ? 'Edit Task' : 'Task Details',
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
                      // Editing mode UI
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
                        maxLines: 2, // Limit maximum lines for description
                        minLines: 1, // Set minimum lines
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(
                          'Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(
                            fontFamily: 'Lexend',
                            color:
                                Colors
                                    .black87, // Changed from white to black for visibility
                          ),
                        ),
                        trailing: const Icon(
                          Icons.calendar_today,
                          color:
                              Colors
                                  .black87, // Changed from white to black for visibility
                        ),
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
                                    primary: Color(
                                      0xFF34A853,
                                    ), // Green color for selected date
                                    onPrimary:
                                        Colors
                                            .white, // White text for selected date
                                    onSurface:
                                        Colors.black, // Black text for calendar
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null && picked != selectedDate) {
                            setStateDialog(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),

                      // Priority selector for editing
                      const SizedBox(height: 16),
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
                              setStateDialog(() {
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
                              setStateDialog(() {
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
                              setStateDialog(() {
                                selectedPriority = value;
                              });
                            },
                          ),
                        ],
                      ),

                      // Notification settings for editing
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
                              setStateDialog(() {
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
                              setStateDialog(() {
                                selectedNotificationTime = value;
                              });
                            }
                          },
                        ),
                      ],
                    ] else ...[
                      // Viewing mode UI
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
                        'Date: ${task.date.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(fontFamily: 'Lexend'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Priority: ${task.priority == 1
                            ? 'Low'
                            : task.priority == 2
                            ? 'Medium'
                            : 'High'}',
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
                  // Viewing mode actions
                  TextButton(
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () {
                      // Show confirmation before deleting
                      _showDeleteConfirmationDialog(context, index);
                    },
                  ),
                  TextButton(
                    child: const Text(
                      'Edit',
                      style: TextStyle(color: Colors.blue),
                    ),
                    onPressed: () {
                      // Show confirmation before editing
                      _showEditConfirmationDialog(context, () {
                        setStateDialog(() {
                          isEditing = true;
                        });
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
                  TextButton(
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black87),
                    ),
                    onPressed: () {
                      setStateDialog(() {
                        isEditing = false;
                      });
                    },
                  ),
                  TextButton(
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: Color(0xFF34A853),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        // Cancel existing notification first
                        NotificationService.cancelNotification(_tasks[index]);

                        setState(() {
                          _tasks[index] = Task(
                            title: titleController.text,
                            date: selectedDate,
                            description: descriptionController.text,
                            isCompleted: task.isCompleted,
                            priority: selectedPriority,
                            color: task.color, // Keep the existing color
                            hasNotification: hasNotification,
                            notificationMinutesBefore: selectedNotificationTime,
                          );
                        });

                        // Schedule new notification if enabled
                        if (hasNotification) {
                          NotificationService.scheduleNotification(
                            _tasks[index],
                          );
                        }

                        Navigator.of(context).pop();
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

  // Helper method to format notification time for display
  String _formatNotificationTime(int minutes) {
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

  // New method: Confirmation dialog for deleting tasks
  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    int index,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white, // Changed from Color(0xFFD9D9D9)
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
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(); // Close the confirmation dialog
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                setState(() {
                  _tasks.removeAt(index);
                });
                Navigator.of(
                  dialogContext,
                ).pop(); // Close the confirmation dialog
                Navigator.of(context).pop(); // Close the task details dialog
              },
            ),
          ],
        );
      },
    );
  }

  // New method: Confirmation dialog for editing tasks
  Future<void> _showEditConfirmationDialog(
    BuildContext context,
    Function onConfirm,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white, // Changed from Color(0xFFD9D9D9)
          title: const Text(
            'Confirm Edit',
            style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Do you want to edit this task?',
            style: TextStyle(fontFamily: 'Lexend'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(); // Close the confirmation dialog
              },
            ),
            TextButton(
              child: const Text('Edit'),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(); // Close the confirmation dialog
                onConfirm(); // Proceed with edit mode
              },
            ),
          ],
        );
      },
    );
  }
}
