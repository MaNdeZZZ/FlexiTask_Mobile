import 'package:flutter/material.dart';
import 'chatbot.dart';
import 'profile.dart'; // Add this import

void main() {
  runApp(const MyApp());
}

// Task model to store task information
class Task {
  String title;
  DateTime date;
  String description;
  bool isCompleted;

  Task({
    required this.title,
    required this.date,
    this.description = '',
    this.isCompleted = false,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({Key? key}) : super(key: key);

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  // Task list to store all tasks
  final List<Task> _tasks = [
    Task(
      title: 'Attend webinar on Flutter development',
      date: DateTime.now(),
      description: 'Join the Zoom meeting at 2 PM',
    ),
    Task(
      title: 'Complete prototype for FlexiTask',
      date: DateTime.now(),
    ),
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
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
                                );
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
                                  child: Container(
                                    color: Colors.black,
                                  ),
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
                          color: Colors.white,
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
                          height: 1, thickness: 1, color: Colors.grey),

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
                                ...groupedTasks['Today']!
                                    .map((index) => _buildTaskCard(index)),
                              ],

                              // Tomorrow section
                              if (groupedTasks['Tomorrow']!.isNotEmpty) ...[
                                _buildDateHeader('Tomorrow'),
                                ...groupedTasks['Tomorrow']!
                                    .map((index) => _buildTaskCard(index)),
                              ],

                              // Upcoming section - Modified to show specific dates
                              for (var entry in groupedTasks.entries)
                                if (entry.key != 'Today' &&
                                    entry.key != 'Tomorrow' &&
                                    entry.value.isNotEmpty) ...[
                                  _buildDateHeader(entry.key),
                                  ...entry.value
                                      .map((index) => _buildTaskCard(index)),
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

      // Floating action buttons
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // AI button (left) - Updated to navigate to ChatbotScreen
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ChatbotScreen()),
                  );
                },
                backgroundColor: const Color(0xFFD9D9D9),
                child: const Icon(Icons.psychology, color: Colors.black),
              ),
            ),

            // Add task button (right) - now connected to the add task dialog
            FloatingActionButton(
              onPressed: _showAddTaskDialog,
              backgroundColor: const Color(0xFFD9D9D9),
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // Modified to group upcoming tasks by specific dates
  Map<String, List<int>> _groupTasksByDate() {
    Map<String, List<int>> groupedTasks = {
      'Today': [],
      'Tomorrow': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    for (int i = 0; i < _tasks.length; i++) {
      final taskDate = DateTime(
          _tasks[i].date.year, _tasks[i].date.month, _tasks[i].date.day);

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

    final weekday = weekdays[date.weekday - 1]; // weekday is 1-7 in Dart
    final day = date.day;
    final month = months[date.month - 1];

    return '$weekday, $day $month';
  }

  // Build date section headers (with green color for Today)
  Widget _buildDateHeader(String text, {bool isToday = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
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
    );
  }

  // Build task card with tap functionality and status tracking
  Widget _buildTaskCard(int index) {
    Task task = _tasks[index];
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Lexend',
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
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
                    child: task.isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
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

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add New Task'),
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
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    // Date picker
                    ListTile(
                      title: Text(
                        'Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(fontFamily: 'Lexend'),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null && picked != selectedDate) {
                          setStateDialog(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Add'),
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      setState(() {
                        _tasks.add(Task(
                          title: titleController.text,
                          date: selectedDate,
                          description: descriptionController.text,
                        ));
                      });
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

  // Dialog to view, edit, or delete a task
  Future<void> _showTaskDetailsDialog(int index) async {
    Task task = _tasks[index];
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    DateTime selectedDate = task.date;
    bool isEditing = false;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Task' : 'Task Details',
                  style: const TextStyle(fontFamily: 'Lexend')),
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
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(
                          'Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(fontFamily: 'Lexend'),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null && picked != selectedDate) {
                            setStateDialog(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
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
                    child: const Text('Delete'),
                    onPressed: () {
                      setState(() {
                        _tasks.removeAt(index);
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Edit'),
                    onPressed: () {
                      setStateDialog(() {
                        isEditing = true;
                      });
                    },
                  ),
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ] else ...[
                  // Editing mode actions
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      setStateDialog(() {
                        isEditing = false;
                      });
                    },
                  ),
                  TextButton(
                    child: const Text('Save'),
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        setState(() {
                          _tasks[index] = Task(
                            title: titleController.text,
                            date: selectedDate,
                            description: descriptionController.text,
                            isCompleted: task.isCompleted,
                          );
                        });
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
}
