import 'package:flexitask_updated/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile.dart';
import 'completed.dart';
import 'dashboard.dart';
import 'theme_constants.dart';
import 'transitions.dart';

class ChatMessage {
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
  });
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ChatbotScreen(),
    );
  }
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isBotTyping = false;
  String? _profileImagePath;
  final int _selectedIndex = 0;
  final String _ollamaUrl = 'https://b513-125-164-25-110.ngrok-free.app/chat';

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
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
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addUserMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _isBotTyping = true;
    });
    try {
      await _firestoreService.addChatMessage(text, true);
      _controller.clear();
      _scrollToBottom();
      _getBotResponse(text);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      setState(() {
        _isBotTyping = false;
      });
    }
  }

  void _addBotMessage(String text) async {
    try {
      await _firestoreService.addChatMessage(text, false);
      setState(() {
        _isBotTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending bot message: $e')));
      setState(() {
        _isBotTyping = false;
      });
    }
  }

  void _scrollToBottom() {
    Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _getBotResponse(String userMessage) async {
    final lowerMessage = userMessage.toLowerCase();
    String response;

    // Check if the query is task-related
    if (lowerMessage.contains('task') ||
        lowerMessage.contains('todo') ||
        lowerMessage.contains('due') ||
        lowerMessage.contains('priority') ||
        lowerMessage.contains('overdue')) {
      try {
        final tasksSnapshot = await _firestoreService.getTasksStream().first;
        final completedTasks =
            await _firestoreService.getWeeklyCompletedTasks();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final weekEnd = today.add(const Duration(days: 7));

        // Handle specific task queries
        if (lowerMessage.contains('today')) {
          final todayTasks = tasksSnapshot.where((taskMap) {
            final task = taskMap['task'] as Task;
            final taskDate =
                DateTime(task.date.year, task.date.month, task.date.day);
            return taskDate == today && !task.isCompleted;
          }).toList();
          if (todayTasks.isEmpty) {
            response = "You have no tasks scheduled for today.";
          } else {
            response = "Here are your tasks for today:\n" +
                todayTasks.map((taskMap) {
                  final task = taskMap['task'] as Task;
                  return "- ${task.title} (Priority: ${task.priority == 3 ? 'High' : task.priority == 2 ? 'Medium' : 'Low'}, Time: ${TimeOfDay.fromDateTime(task.date).format(context)})";
                }).join('\n');
          }
        } else if (lowerMessage.contains('tomorrow')) {
          final tomorrowTasks = tasksSnapshot.where((taskMap) {
            final task = taskMap['task'] as Task;
            final taskDate =
                DateTime(task.date.year, task.date.month, task.date.day);
            return taskDate == tomorrow && !task.isCompleted;
          }).toList();
          if (tomorrowTasks.isEmpty) {
            response = "You have no tasks scheduled for tomorrow.";
          } else {
            response = "Here are your tasks for tomorrow:\n" +
                tomorrowTasks.map((taskMap) {
                  final task = taskMap['task'] as Task;
                  return "- ${task.title} (Priority: ${task.priority == 3 ? 'High' : task.priority == 2 ? 'Medium' : 'Low'}, Time: ${TimeOfDay.fromDateTime(task.date).format(context)})";
                }).join('\n');
          }
        } else if (lowerMessage.contains('week')) {
          final weekTasks = tasksSnapshot.where((taskMap) {
            final task = taskMap['task'] as Task;
            final taskDate =
                DateTime(task.date.year, task.date.month, task.date.day);
            return taskDate.isAfter(today.subtract(const Duration(days: 1))) &&
                taskDate.isBefore(weekEnd.add(const Duration(days: 1))) &&
                !task.isCompleted;
          }).toList();
          if (weekTasks.isEmpty) {
            response = "You have no tasks scheduled for this week.";
          } else {
            response = "Here are your tasks for this week:\n" +
                weekTasks.map((taskMap) {
                  final task = taskMap['task'] as Task;
                  return "- ${task.title} (Due: ${_formatDate(task.date)}, Priority: ${task.priority == 3 ? 'High' : task.priority == 2 ? 'Medium' : 'Low'})";
                }).join('\n');
          }
        } else if (lowerMessage.contains('overdue')) {
          final overdueTasks = tasksSnapshot.where((taskMap) {
            final task = taskMap['task'] as Task;
            final taskDate =
                DateTime(task.date.year, task.date.month, task.date.day);
            return taskDate.isBefore(today) && !task.isCompleted;
          }).toList();
          if (overdueTasks.isEmpty) {
            response = "You have no overdue tasks.";
          } else {
            response = "Here are your overdue tasks:\n" +
                overdueTasks.map((taskMap) {
                  final task = taskMap['task'] as Task;
                  final daysOverdue = today
                      .difference(DateTime(
                          task.date.year, task.date.month, task.date.day))
                      .inDays;
                  return "- ${task.title} (Due: ${_formatDate(task.date)}, ${daysOverdue} days overdue, Priority: ${task.priority == 3 ? 'High' : task.priority == 2 ? 'Medium' : 'Low'})";
                }).join('\n');
          }
        } else if (lowerMessage.contains('high') &&
            lowerMessage.contains('priority')) {
          final highPriorityTasks = tasksSnapshot.where((taskMap) {
            final task = taskMap['task'] as Task;
            return task.priority == 3 && !task.isCompleted;
          }).toList();
          if (highPriorityTasks.isEmpty) {
            response = "You have no high-priority tasks.";
          } else {
            response = "Here are your high-priority tasks:\n" +
                highPriorityTasks.map((taskMap) {
                  final task = taskMap['task'] as Task;
                  return "- ${task.title} (Due: ${_formatDate(task.date)}, Time: ${TimeOfDay.fromDateTime(task.date).format(context)})";
                }).join('\n');
          }
        } else if (lowerMessage.contains('completed')) {
          if (completedTasks.isEmpty) {
            response = "You haven't completed any tasks in the past week.";
          } else {
            response = "Here are your completed tasks from the past week:\n" +
                completedTasks.map((task) {
                  return "- ${task.title} (Completed on ${_formatDate(task.date)})";
                }).join('\n');
          }
        } else {
          // Fallback for generic task queries
          final allTasks = tasksSnapshot.where((taskMap) {
            final task = taskMap['task'] as Task;
            return !task.isCompleted;
          }).toList();
          if (allTasks.isEmpty) {
            response = "You have no active tasks.";
          } else {
            response = "Here are all your active tasks:\n" +
                allTasks.map((taskMap) {
                  final task = taskMap['task'] as Task;
                  return "- ${task.title} (Due: ${_formatDate(task.date)}, Priority: ${task.priority == 3 ? 'High' : task.priority == 2 ? 'Medium' : 'Low'})";
                }).join('\n');
          }
        }
      } catch (e) {
        response =
            "Sorry, I couldn't fetch your tasks. Please try again later. Error: $e";
      }
    } else {
      // Query Ollama for non-task-related queries
      try {
        final ollamaResponse = await _queryOllama(userMessage);
        response = ollamaResponse;
      } catch (e) {
        response =
            "Sorry, I couldn't connect to the AI service. Try again later. Error: $e";
      }
    }

    Timer(const Duration(seconds: 1), () {
      _addBotMessage(response);
    });
  }

  Future<String> _queryOllama(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_ollamaUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['response'] != null) {
          return data['response'].toString();
        } else {
          throw Exception('Invalid response format from Ollama');
        }
      } else {
        throw Exception(
            'Failed to get response from Ollama: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error querying Ollama: $e');
      rethrow;
    }
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.black,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Column(
                    children: [
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
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () =>
                                      AppTransitions.pushReplacement(
                                          context, const DashboardScreen()),
                                ),
                                const SizedBox(width: 12),
                                Image.asset('assets/images/logo.png',
                                    height: 40.0, width: 40.0),
                              ],
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
                        decoration: const BoxDecoration(color: Colors.white),
                        child: const Center(
                          child: Text(
                            "Task Assistant",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Lexend'),
                          ),
                        ),
                      ),
                      const Divider(
                          height: 1, thickness: 1, color: Colors.grey),
                      Expanded(
                        child: Container(
                          color: Colors.grey[200],
                          child: StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _firestoreService.getChatMessagesStream(),
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
                              final messages = snapshot.data ?? [];
                              return ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(12),
                                itemCount:
                                    messages.length + (_isBotTyping ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (_isBotTyping &&
                                      index == messages.length) {
                                    return _buildTypingIndicator();
                                  }
                                  final message = messages[index];
                                  return _buildMessageBubble(
                                    message['message'],
                                    message['isUser'],
                                    message['timestamp'],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildInputArea(),
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
            if (index == _selectedIndex) return;
            switch (index) {
              case 1:
                AppTransitions.pushReplacement(
                    context, const DashboardScreen());
                break;
              case 2:
                AppTransitions.pushReplacement(
                  context,
                  CompletedTasksScreen(
                    onTaskRestored: (task) {
                      // Handle task restored if needed
                    },
                  ),
                );
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
                icon: Icon(Icons.add_circle_outline), label: 'Add Task'),
            BottomNavigationBarItem(
                icon: Icon(Icons.check_circle_outline), label: 'Completed'),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
      String message, bool isUserMessage, DateTime timestamp) {
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isUserMessage ? AppColors.accent : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isUserMessage ? Colors.white : Colors.black87,
                fontFamily: 'Lexend',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(timestamp),
              style: TextStyle(
                color: isUserMessage ? Colors.white70 : Colors.black54,
                fontFamily: 'Lexend',
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Typing...',
          style: TextStyle(
            color: Colors.black87,
            fontFamily: 'Lexend',
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle:
                    const TextStyle(fontFamily: 'Lexend', color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (value) => _addUserMessage(value),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.accent),
            onPressed: () => _addUserMessage(_controller.text),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);
    final time = TimeOfDay.fromDateTime(timestamp).format(context);
    if (messageDate == today) {
      return time;
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} $time';
    }
  }
}
