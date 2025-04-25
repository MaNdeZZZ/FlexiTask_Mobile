import 'package:flutter/material.dart';
import 'dart:async'; // For delayed responses
import 'profile.dart';
import 'completed.dart'; // Add this import
import 'dashboard.dart'; // Add this import to access _completedTasks
import 'theme_constants.dart'; // Add this import
import 'transitions.dart'; // Add this import
import 'package:shared_preferences/shared_preferences.dart'; // Add this import
import 'dart:io'; // Add this import for File class

// Message model to handle chat data
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
  final List<ChatMessage> _messages = [];
  bool _isBotTyping = false;

  // Add a variable to store the profile image path
  String? _profileImagePath;

  // Set the active index for this screen
  final int _selectedIndex = 0; // Assistant tab is active

  // Reference to completed tasks from dashboard
  final List<Task> _localCompletedTasks =
      []; // Create a local empty list for ChatbotScreen

  @override
  void initState() {
    super.initState();

    // Add initial welcome message
    _addBotMessage("Hello! I'm your task assistant. How can I help you today?");

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
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Add a message from the user
  void _addUserMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUserMessage: true, timestamp: DateTime.now()),
      );
      _isBotTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    // Simulate bot thinking and responding
    _simulateBotResponse(text);
  }

  // Add a message from the bot
  void _addBotMessage(String text) {
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUserMessage: false,
          timestamp: DateTime.now(),
        ),
      );
    });

    _scrollToBottom();
  }

  // Scroll to the bottom of the chat
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

  // Simulate bot responses based on user input
  void _simulateBotResponse(String userMessage) {
    // Simulate typing delay for realism
    Future.delayed(const Duration(seconds: 1), () {
      String botResponse = '';
      final lowerUserMessage = userMessage.toLowerCase();

      if (lowerUserMessage.contains('hello') ||
          lowerUserMessage.contains('hi')) {
        botResponse = "Hello! How can I help you with your tasks today?";
      } else if (lowerUserMessage.contains('task') &&
          lowerUserMessage.contains('today')) {
        botResponse = "Based on your schedule, you have 3 tasks for today:\n\n"
            "1. Attend webinar on Flutter development at 2 PM\n"
            "2. Complete prototype for FlexiTask\n"
            "3. Team meeting at 3 PM\n\n"
            "Would you like me to prioritize these for you?";
      } else if (lowerUserMessage.contains('prioritize') ||
          lowerUserMessage.contains('priority')) {
        botResponse = "Here's the suggested priority order:\n\n"
            "1. Complete prototype for FlexiTask (High priority)\n"
            "2. Attend webinar on Flutter development at 2 PM (Medium priority)\n"
            "3. Team meeting at 3 PM (Medium priority)";
      } else if (lowerUserMessage.contains('tomorrow')) {
        botResponse = "You have 2 tasks scheduled for tomorrow:\n\n"
            "1. Review project requirements\n"
            "2. Doctor appointment at 10 AM\n\n"
            "Would you like me to add another task for tomorrow?";
      } else if (lowerUserMessage.contains('add')) {
        botResponse =
            "What task would you like to add? Please provide a title, date, and optional description.";
      } else if (lowerUserMessage.contains('thank')) {
        botResponse =
            "You're welcome! Let me know if there's anything else I can help you with.";
      } else {
        botResponse =
            "I'm here to help organize your tasks. You can ask me about your schedule, add new tasks, or prioritize existing ones.";
      }

      setState(() {
        _isBotTyping = false;
        _addBotMessage(botResponse);
      });
    });
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
                      // Logo, back button and profile section
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
                                  child: _buildProfileImage(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Prompt text
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: const BoxDecoration(color: Colors.white),
                        child: const Center(
                          child: Text(
                            'Ask anything regarding your task!',
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

                      // Chat area with messages
                      Expanded(
                        child: Container(
                          color: const Color.fromARGB(255, 230, 230, 230),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount:
                                _messages.length + (_isBotTyping ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Show typing indicator as the last item when bot is typing
                              if (_isBotTyping && index == _messages.length) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                      top: 8.0,
                                      bottom: 8.0,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[400],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 40,
                                          child: _buildTypingIndicator(),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final message = _messages[index];
                              return _buildMessageBubble(message);
                            },
                          ),
                        ),
                      ),

                      // Input field - now part of the main container (not floating)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 3,
                              offset: const Offset(0, -1),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            // New Chat button
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFD9D9D9),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.add_comment,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _messages.clear(); // Clear chat history
                                    // Add welcome message again
                                    _addBotMessage(
                                      "Hello! I'm your task assistant. How can I help you today?",
                                    );
                                  });
                                },
                                tooltip: 'New Chat',
                                iconSize: 20,
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                            ),

                            // Text input
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(
                                    255,
                                    245,
                                    245,
                                    245,
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: TextField(
                                  controller: _controller,
                                  decoration: const InputDecoration(
                                    hintText: 'Ask about your tasks...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                      fontFamily: 'Lexend',
                                      fontSize: 15,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontFamily: 'Lexend',
                                    fontSize: 15,
                                  ),
                                  maxLines: null,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (value) =>
                                      _addUserMessage(value),
                                ),
                              ),
                            ),

                            // Send button
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFD9D9D9),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.send,
                                    color: Colors.black,
                                  ),
                                  onPressed: () =>
                                      _addUserMessage(_controller.text),
                                  tooltip: 'Send message',
                                ),
                              ),
                            ),
                          ],
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
              case 1: // Home/Add Task
                // Just pop back to dashboard instead of creating a new navigation
                Navigator.pop(context);
                break;
              case 2: // Completed
                // Use a clean navigation approach to prevent stacking
                AppTransitions.pushReplacement(
                  context,
                  CompletedTasksScreen(
                    completedTasks: _localCompletedTasks,
                    onTaskRestored: (task) {}, // Empty handler
                  ),
                );
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
              icon: Icon(Icons.check_circle_outline),
              label: 'Completed',
            ),
          ],
        ),
      ),
    );
  }

  // Build a message bubble based on the message type
  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment:
          message.isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUserMessage ? Colors.white : Colors.grey[400],
          borderRadius: BorderRadius.circular(12),
          border:
              message.isUserMessage ? Border.all(color: Colors.black12) : null,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontFamily: 'Lexend',
            color: message.isUserMessage ? Colors.black87 : Colors.black,
          ),
        ),
      ),
    );
  }

  // Build a typing indicator animation
  Widget _buildTypingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPulsingDot(300),
        const SizedBox(width: 4),
        _buildPulsingDot(500),
        const SizedBox(width: 4),
        _buildPulsingDot(700),
      ],
    );
  }

  // Individual pulsing dot with animation
  Widget _buildPulsingDot(int delay) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: delay),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color.fromARGB(
              255,
              70,
              70,
              70,
            ).withOpacity(value as double),
          ),
        );
      },
      child: const SizedBox(),
    );
  }
}
