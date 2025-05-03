import 'package:flexitask_updated/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'chatbot.dart';
import 'transitions.dart';
import 'theme_constants.dart';
import 'dashboard.dart';

class CompletedTasksScreen extends StatefulWidget {
  final Function(Task)? onTaskRestored;

  const CompletedTasksScreen({Key? key, this.onTaskRestored}) : super(key: key);

  @override
  State<CompletedTasksScreen> createState() => _CompletedTasksScreenState();
}

class _CompletedTasksScreenState extends State<CompletedTasksScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _profileImagePath;
  final int _selectedIndex = 2;

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
                              topRight: Radius.circular(20)),
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
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 12),
                                Image.asset('assets/images/logo.png',
                                    height: 40.0, width: 40.0),
                              ],
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFFD9D9D9), width: 2),
                              ),
                              child: ClipOval(child: _buildProfileImage()),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 16),
                        decoration: const BoxDecoration(color: Colors.white),
                        child: const Center(
                          child: Text(
                            "Completed Tasks",
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
                          color: const Color.fromARGB(255, 230, 230, 230),
                          child: StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _firestoreService.getCompletedTasksStream(),
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
                              final completedTasks = snapshot.data ?? [];
                              if (completedTasks.isEmpty) {
                                return _buildEmptyState();
                              }
                              return ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: completedTasks.length,
                                itemBuilder: (context, index) {
                                  return _buildCompletedTaskCard(
                                      completedTasks[index], index);
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
                color: Colors.black.withOpacity(0.1))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (index == _selectedIndex) return;
            switch (index) {
              case 0:
                AppTransitions.pushReplacement(context, const ChatbotScreen());
                break;
              case 1:
                Navigator.pop(context);
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
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.check_circle), label: 'Completed'),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedTaskCard(Map<String, dynamic> taskMap, int index) {
    Task task = taskMap['task'] as Task;
    String taskId = taskMap['id'];
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.grey[200],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
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
                                ? Colors.red.withOpacity(0.6)
                                : Colors.orange.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Lexend',
                            decoration: TextDecoration.lineThrough,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Lexend',
                        color: Colors.grey,
                        fontWeight: FontWeight.w300,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Completed on ${_formatDate(DateTime.now())}',
                    style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'Lexend',
                        color: Colors.grey,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.restore, size: 20),
              onPressed: () async {
                try {
                  Task restoredTask = Task(
                    title: task.title,
                    date: task.date,
                    description: task.description,
                    isCompleted: false,
                    priority: task.priority,
                    color: task.color,
                    hasNotification: task.hasNotification,
                    notificationMinutesBefore: task.notificationMinutesBefore,
                  );
                  // Add the task back to the tasks collection
                  await _firestoreService.addTask(restoredTask);
                  // Delete the task from completed_tasks collection
                  await _firestoreService.deleteCompletedTask(taskId);
                  // Notify DashboardScreen without adding the task again
                  if (widget.onTaskRestored != null) {
                    widget.onTaskRestored!(restoredTask);
                  }
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task restored successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error restoring task: $e')),
                  );
                }
              },
              tooltip: 'Restore task',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No completed tasks yet',
              style: TextStyle(
                  fontSize: 18, fontFamily: 'Lexend', color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Completed tasks will appear here',
              style: TextStyle(
                  fontSize: 14, fontFamily: 'Lexend', color: Colors.grey)),
        ],
      ),
    );
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
}
