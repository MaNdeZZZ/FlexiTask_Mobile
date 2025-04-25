import 'package:flutter/material.dart';

// App-wide theme constants
class AppColors {
  // Primary colors
  static const Color primary = Color(
    0xFFD9D9D9,
  ); // Light gray as main app theme color
  static const Color secondary = Color(
    0xFFD9D9D9,
  ); // Light gray for buttons/UI elements
  static const Color accent = Color(
    0xFF34A853,
  ); // Green accent color for specific elements

  // Background colors
  static const Color background = Colors.white;
  static const Color secondaryBackground = Color.fromARGB(255, 230, 230, 230);
  static const Color darkBackground = Colors.black;

  // Text colors
  static const Color primaryText = Colors.black;
  static const Color secondaryText = Colors.black54;
  static const Color lightText = Colors.white;

  // Status colors
  static const Color highPriority = Colors.red;
  static const Color mediumPriority = Colors.orange;
  static const Color lowPriority = Color(0xFF34A853); // Green for low priority
  static const Color notification = Colors.blue;

  // Action colors
  static const Color saveAction = Color(0xFF34A853); // Green for save actions
  static const Color editAction = Color(0xFF2196F3); // Blue
  static const Color deleteAction = Colors.red;
  static const Color cancelAction = Colors.black87;

  // Special elements
  static const Color todayHeader = Color(0xFF34A853); // Green for today header
}

// Common text styles
class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: 'Lexend',
    color: AppColors.primaryText,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: 'Lexend',
    color: AppColors.primaryText,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontFamily: 'Lexend',
    color: AppColors.primaryText,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    fontFamily: 'Lexend',
    color: AppColors.secondaryText,
  );
}

// Common button styles
class AppButtonStyles {
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.secondary,
    minimumSize: const Size.fromHeight(50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    elevation: 5,
    shadowColor: Colors.black45,
  );
}

// Add this class for consistent navigation styling
class AppNavigation {
  // Method to create a consistent WhatsApp style bottom navigation bar
  static BottomNavigationBar bottomNavigationBar({
    required int currentIndex,
    required Function(int) onTap,
    required bool showAddButton,
  }) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
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
      elevation: 8.0,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.psychology),
          activeIcon: Icon(Icons.psychology),
          label: 'Assistant',
        ),
        // Show either Add button or Home button based on the screen
        showAddButton
            ? const BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                activeIcon: Icon(Icons.add_circle),
                label: 'Add Task',
              )
            : const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.check_circle_outline),
          activeIcon: Icon(Icons.check_circle),
          label: 'Completed',
        ),
      ],
    );
  }
}
