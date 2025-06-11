// lib/providers/task_provider.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_app/task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_analytics/firebase_analytics.dart'; // New import for analytics

/// TaskProvider: Manages the state and logic for tasks.
/// It extends ChangeNotifier to notify its listeners (UI widgets) about changes.
class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = []; // The private list of tasks
  bool _isLoadingTasks = false; // Loading state for tasks

  // Public getters to access tasks and loading state
  List<Task> get tasks => _tasks;
  bool get isLoadingTasks => _isLoadingTasks;

  // Pre-computed grouped tasks and sorted headers for efficient UI rendering
  Map<String, List<Task>> _groupedTasks = {};
  List<String> _sortedHeaders = [];

  Map<String, List<Task>> get groupedTasks => _groupedTasks;
  List<String> get sortedHeaders => _sortedHeaders;

  static const String _tasksKey = 'tasks_list'; // Key for SharedPreferences

  TaskProvider() {
    // Constructor: Load tasks when the provider is created
    _loadTasks();
  }

  // --- Persistence Methods ---
  /// Loads tasks from SharedPreferences.
  Future<void> _loadTasks() async {
    _isLoadingTasks = true;
    notifyListeners(); // Notify listeners that loading has started

    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString(_tasksKey);

    if (tasksString != null) {
      final List<dynamic> taskMaps = jsonDecode(tasksString);
      _tasks.addAll(taskMaps.map((map) => Task.fromJson(map as Map<String, dynamic>)).toList());
      _sortTasks(); // Sort after loading
      _updateGroupedTasks(); // Group and sort headers after loading
    }
    _isLoadingTasks = false;
    notifyListeners(); // Notify listeners that loading has finished
  }

  /// Saves the current list of tasks to SharedPreferences.
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String tasksString = jsonEncode(_tasks.map((task) => task.toJson()).toList());
    await prefs.setString(_tasksKey, tasksString);
  }

  // --- Task Management Methods ---
  /// Adds a new task.
  void addTask(Task newTask) {
    _tasks.add(newTask);
    _sortTasks();
    _updateGroupedTasks(); // Update grouped tasks after adding
    _saveTasks();
    FirebaseAnalytics.instance.logEvent( // Analytics event
      name: 'task_added',
      parameters: {'task_title': newTask.title},
    );
    print('Analytics: Logged task_added');
    notifyListeners(); // Notify listeners about the change
  }

  /// Removes a task at a given index.
  void removeTask(int index) {
    final taskTitle = _tasks[index].title;
    _tasks.removeAt(index);
    _updateGroupedTasks(); // Update grouped tasks after removing
    _saveTasks();
    FirebaseAnalytics.instance.logEvent( // Analytics event
      name: 'task_deleted',
      parameters: {'task_title': taskTitle},
    );
    print('Analytics: Logged task_deleted');
    notifyListeners(); // Notify listeners about the change
  }

  /// Toggles the completion status of a task.
  void toggleTaskCompletion(int index, bool? value) {
    final task = _tasks[index];
    task.isCompleted = value ?? false;
    _sortTasks();
    _updateGroupedTasks(); // Update grouped tasks after toggling completion
    _saveTasks();
    FirebaseAnalytics.instance.logEvent( // Analytics event
      name: value == true ? 'task_completed' : 'task_reopened',
      parameters: {'task_title': task.title, 'is_completed': value},
    );
    print('Analytics: Logged task completion status change');
    notifyListeners(); // Notify listeners about the change
  }

  /// Updates an existing task.
  void updateTask(int index, Task updatedTask) {
    _tasks[index] = updatedTask;
    _sortTasks();
    _updateGroupedTasks(); // Update grouped tasks after updating
    _saveTasks();
    FirebaseAnalytics.instance.logEvent( // Analytics event
      name: 'task_updated',
      parameters: {'task_title': updatedTask.title},
    );
    print('Analytics: Logged task_updated');
    notifyListeners(); // Notify listeners about the change
  }

  /// Sorts the internal _tasks list based on completion, date, time, and title.
  void _sortTasks() {
    _tasks.sort((a, b) {
      // Logic from previous _sortTasks
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;

      if (a.scheduledDate != null && b.scheduledDate != null) {
        final dateComparison = a.scheduledDate!.compareTo(b.scheduledDate!);
        if (dateComparison != 0) return dateComparison;
      } else if (a.scheduledDate != null) {
        return -1;
      } else if (b.scheduledDate != null) {
        return 1;
      }

      if (a.scheduledTime != null && b.scheduledTime != null) {
        final timeA = a.scheduledTime!.hour * 60 + a.scheduledTime!.minute;
        final timeB = b.scheduledTime!.hour * 60 + b.scheduledTime!.minute;
        final timeComparison = timeA.compareTo(timeB);
        if (timeComparison != 0) return timeComparison;
      } else if (a.scheduledTime != null) {
        return -1;
      } else if (b.scheduledTime != null) {
        return 1;
      }

      return a.title.compareTo(b.title);
    });
  }

  /// Groups tasks by date and sorts the headers for display.
  void _updateGroupedTasks() {
    final Map<String, List<Task>> tempGroupedTasks = {};
    for (var task in _tasks) {
      String header;
      if (task.scheduledDate == null) {
        header = 'No Date';
      } else {
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        final tomorrowOnly = DateTime(today.year, today.month, today.day).add(const Duration(days: 1));
        final taskDateOnly = DateTime(task.scheduledDate!.year, task.scheduledDate!.month, task.scheduledDate!.day);

        final DateFormat formatter = DateFormat('EEE, MMM d');

        if (taskDateOnly == todayOnly) {
          header = 'Today';
        } else if (taskDateOnly == tomorrowOnly) {
          header = 'Tomorrow';
        } else if (taskDateOnly.isBefore(todayOnly)) {
          header = 'Past';
        } else {
          header = formatter.format(task.scheduledDate!);
        }
      }
      tempGroupedTasks.putIfAbsent(header, () => []).add(task);
    }

    final List<String> tempSortedHeaders = tempGroupedTasks.keys.toList();
    tempSortedHeaders.sort((a, b) {
      final order = ['Today', 'Tomorrow', 'Past'];

      final indexA = order.indexOf(a);
      final indexB = order.indexOf(b);

      if (indexA != -1 && indexB != -1) {
        return indexA.compareTo(indexB);
      } else if (indexA != -1) {
        return -1;
      } else if (indexB != -1) {
        return 1;
      }

      if (a == 'No Date') return 1;
      if (b == 'No Date') return -1;

      try {
        final dateA = DateFormat('EEE, MMM d').parse(a);
        final dateB = DateFormat('EEE, MMM d').parse(b);
        return dateA.compareTo(dateB);
      } catch (e) {
        return a.compareTo(b);
      }
    });

    _groupedTasks = tempGroupedTasks;
    _sortedHeaders = tempSortedHeaders;
  }
}