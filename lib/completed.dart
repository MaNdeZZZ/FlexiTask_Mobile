import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io'; // Add this import for File class
import 'chatbot.dart'; // Add this import
import 'transitions.dart'; // Add this import
import 'theme_constants.dart'; // Add this import for AppColors

// Import the Task model defined in dashboard.dart
import 'dashboard.dart';

class CompletedTasksScreen extends StatefulWidget {
  final List<Task> completedTasks;
  final Function(Task)? onTaskRestored; // Callback function for restored tasks

  const CompletedTasksScreen({
    Key? key,
    required this.completedTasks,
    this.onTaskRestored,
  }) : super(key: key);

  @override
  State<CompletedTasksScreen> createState() => _CompletedTasksScreenState();
}

class _CompletedTasksScreenState extends State<CompletedTasksScreen> {
  // Add a variable to store the profile image path
  String? _profileImagePath;

  // Add selected index for bottom navigation
  final int _selectedIndex = 2; // Completed tab is active

  @override
  void initState() {
    super.initState();
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
                      // Logo and back button
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
                            // Back button and logo in a row
                            Row(
                              children: [
                                // Back button
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 12),
                                // Logo
                                Image.asset(
                                  'assets/images/logo.png',
                                  height: 40.0,
                                  width: 40.0,
                                ),
                              ],
                            ),
                            // Profile picture
                            Container(
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
                          ],
                        ),
                      ),

                      // Header text
                      Container(
                        padding: const EdgeInsets.only(bottom: 16),
                        decoration: const BoxDecoration(color: Colors.white),
                        child: const Center(
                          child: Text(
                            "Completed Tasks",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
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

                      // Completed tasks list
                      Expanded(
                        child: Container(
                          color: const Color.fromARGB(255, 230, 230, 230),
                          child: widget.completedTasks.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: widget.completedTasks.length,
                                  itemBuilder: (context, index) {
                                    return _buildCompletedTaskCard(index);
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
      // WhatsApp style bottom navigation
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
            if (index == _selectedIndex)
              return; // Don't navigate if already on this tab

            switch (index) {
              case 0: // Assistant
                // Use pushAndRemoveUntil to clear navigation stack and start fresh
                AppTransitions.pushReplacement(
                  context,
                  const ChatbotScreen(),
                );
                break;
              case 1: // Home - go back to dashboard
                Navigator.pop(context); // Go back to dashboard
                break;
            }
          },
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.accent,
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
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle),
              label: 'Completed',
            ),
          ],
        ),
      ),
    );
  }

  // Build a card for a completed task
  Widget _buildCompletedTaskCard(int index) {
    Task task = widget.completedTasks[index];
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.grey[200], // Use a lighter color for completed tasks
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
                      // Priority indicator as a circle
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
                  // Completion date
                  Text(
                    'Completed on ${_formatDate(DateTime.now())}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'Lexend',
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            // Restore button
            IconButton(
              icon: const Icon(Icons.restore, size: 20),
              onPressed: () {
                setState(() {
                  // Restore task to active tasks
                  Task restoredTask = widget.completedTasks[index];
                  restoredTask.isCompleted = false;

                  // Return the restored task to dashboard
                  if (widget.onTaskRestored != null) {
                    widget.onTaskRestored!(restoredTask);
                  }

                  // Remove from completed tasks list
                  widget.completedTasks.removeAt(index);
                });
              },
              tooltip: 'Restore task',
            ),
          ],
        ),
      ),
    );
  }

  // Empty state when no completed tasks
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No completed tasks yet',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Lexend',
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Completed tasks will appear here',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Lexend',
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Format date helper method
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
      'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
