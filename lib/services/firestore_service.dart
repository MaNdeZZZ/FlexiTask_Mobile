import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flexitask_updated/dashboard.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> _getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('Current user UID: ${user?.uid}');
    return user?.uid;
  }

  Future<void> addTask(Task task) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      final taskData = {
        'title': task.title,
        'date': Timestamp.fromDate(task.date),
        'description': task.description,
        'isCompleted': task.isCompleted,
        'priority': task.priority,
        'color': task.color.value.toRadixString(16).padLeft(8, '0'),
        'hasNotification': task.hasNotification,
        'notificationMinutesBefore': task.notificationMinutesBefore,
      };
      debugPrint('Adding task: $taskData');
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .add(taskData);
    } catch (e) {
      debugPrint('Error adding task: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getTasksStream() async* {
    final userId = await _getUserId();
    if (userId == null) {
      yield [];
      return;
    }
    yield* _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'task': Task(
                  title: data['title'],
                  date: (data['date'] as Timestamp).toDate(),
                  description: data['description'],
                  isCompleted: data['isCompleted'],
                  priority: data['priority'],
                  color: Color(int.parse(data['color'], radix: 16)),
                  hasNotification: data['hasNotification'],
                  notificationMinutesBefore: data['notificationMinutesBefore'],
                ),
              };
            }).toList());
  }

  Future<void> updateTask(String taskId, Task task) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      final taskData = {
        'title': task.title,
        'date': Timestamp.fromDate(task.date),
        'description': task.description,
        'isCompleted': task.isCompleted,
        'priority': task.priority,
        'color': task.color.value.toRadixString(16).padLeft(8, '0'),
        'hasNotification': task.hasNotification,
        'notificationMinutesBefore': task.notificationMinutesBefore,
      };
      debugPrint('Updating task $taskId: $taskData');
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .update(taskData);
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      debugPrint('Deleting task: $taskId');
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  Future<void> deleteCompletedTask(String taskId) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      debugPrint('Deleting completed task: $taskId');
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('completed_tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting completed task: $e');
      rethrow;
    }
  }

  Future<void> completeTask(String taskId, Task task) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      final completedTaskData = {
        'title': task.title,
        'date': Timestamp.fromDate(task.date),
        'description': task.description,
        'isCompleted': true,
        'priority': task.priority,
        'color': task.color.value.toRadixString(16).padLeft(8, '0'),
        'hasNotification': task.hasNotification,
        'notificationMinutesBefore': task.notificationMinutesBefore,
        'completedAt': Timestamp.now(),
      };
      debugPrint('Adding to completed_tasks: $completedTaskData');
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('completed_tasks')
          .add(completedTaskData);
      debugPrint('Deleting from tasks: $taskId');
      await deleteTask(taskId);
    } catch (e) {
      debugPrint('Error in completeTask: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getCompletedTasksStream() async* {
    final userId = await _getUserId();
    if (userId == null) {
      yield [];
      return;
    }
    yield* _firestore
        .collection('users')
        .doc(userId)
        .collection('completed_tasks')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'task': Task(
                  title: data['title'],
                  date: (data['date'] as Timestamp).toDate(),
                  description: data['description'],
                  isCompleted: data['isCompleted'],
                  priority: data['priority'],
                  color: Color(int.parse(data['color'], radix: 16)),
                  hasNotification: data['hasNotification'],
                  notificationMinutesBefore: data['notificationMinutesBefore'],
                ),
              };
            }).toList());
  }

  Future<List<Task>> getWeeklyCompletedTasks() async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('completed_tasks')
          .where('completedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(oneWeekAgo))
          .get();
      debugPrint(
          'Fetched ${querySnapshot.docs.length} completed tasks for the week');
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Task(
          title: data['title'],
          date: (data['date'] as Timestamp).toDate(),
          description: data['description'],
          isCompleted: data['isCompleted'],
          priority: data['priority'],
          color: Color(int.parse(data['color'], radix: 16)),
          hasNotification: data['hasNotification'],
          notificationMinutesBefore: data['notificationMinutesBefore'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching weekly completed tasks: $e');
      rethrow;
    }
  }

  Future<void> addChatMessage(String message, bool isUser) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      final messageData = {
        'message': message,
        'isUser': isUser,
        'timestamp': Timestamp.now(),
      };
      debugPrint('Adding chat message: $messageData');
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_messages')
          .add(messageData);
    } catch (e) {
      debugPrint('Error adding chat message: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getChatMessagesStream() async* {
    final userId = await _getUserId();
    if (userId == null) {
      yield [];
      return;
    }
    yield* _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'message': data['message'],
                'isUser': data['isUser'],
                'timestamp': (data['timestamp'] as Timestamp).toDate(),
              };
            }).toList());
  }
}
