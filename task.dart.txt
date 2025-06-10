// lib/task.dart

import 'package:flutter/material.dart'; // Required for TimeOfDay and DateTime

/// A simple data model for our Task/Event.
/// This class will hold all the relevant information for a single task.
class Task {
  String title; // The main description of the task
  DateTime? scheduledDate; // Optional date for the task (null if not set)
  TimeOfDay? scheduledTime; // Optional time for the task (null if not set)
  bool isCompleted; // To track if the task is done (default to false)

  /// Constructor for the Task class.
  /// `required` ensures these properties must be provided when creating a Task.
  Task({
    required this.title,
    this.scheduledDate, // Optional parameters
    this.scheduledTime, // Optional parameters
    this.isCompleted = false, // Default value if not provided
  });

  // --- New: Methods for JSON serialization/deserialization ---

  /// Converts a Task object into a Map<String, dynamic> (JSON-serializable format).
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      // Convert DateTime to ISO 8601 string for storage
      'scheduledDate': scheduledDate?.toIso8601String(),
      // Store TimeOfDay as hour and minute integers
      'scheduledTimeHour': scheduledTime?.hour,
      'scheduledTimeMinute': scheduledTime?.minute,
      'isCompleted': isCompleted,
    };
  }

  /// Creates a Task object from a Map<String, dynamic>.
  /// This is a factory constructor, which means it can return an instance
  /// from a map, rather than always creating a new one directly.
  factory Task.fromJson(Map<String, dynamic> json) {
    // Parse DateTime string back to DateTime object
    DateTime? date = json['scheduledDate'] != null
        ? DateTime.parse(json['scheduledDate'] as String)
        : null;
    // Reconstruct TimeOfDay from hour and minute
    TimeOfDay? time = (json['scheduledTimeHour'] != null && json['scheduledTimeMinute'] != null)
        ? TimeOfDay(hour: json['scheduledTimeHour'] as int, minute: json['scheduledTimeMinute'] as int)
        : null;

    return Task(
      title: json['title'] as String,
      scheduledDate: date,
      scheduledTime: time,
      isCompleted: json['isCompleted'] as bool,
    );
  }

  // --- Helper Methods for Display ---
  /// A helper method to format the date for display (e.g., "Mon, Jan 1").
  String get formattedDate {
    if (scheduledDate == null) {
      return 'No Date';
    }
    return '${_getWeekdayName(scheduledDate!.weekday)}, '
           '${_getMonthAbbreviation(scheduledDate!.month)} ${scheduledDate!.day}';
  }

  /// A helper method to format the time for display (e.g., "10:30 AM").
  String get formattedTime {
    if (scheduledTime == null) {
      return 'No Time';
    }
    final hour = scheduledTime!.hourOfPeriod == 0 ? 12 : scheduledTime!.hourOfPeriod;
    final minute = scheduledTime!.minute.toString().padLeft(2, '0');
    final amPm = scheduledTime!.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $amPm';
  }

  /// Helper to get weekday name abbreviation (e.g., Mon, Tue).
  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'Mon';
      case DateTime.tuesday: return 'Tue';
      case DateTime.wednesday: return 'Wed';
      case DateTime.thursday: return 'Thu';
      case DateTime.friday: return 'Fri';
      case DateTime.saturday: return 'Sat';
      case DateTime.sunday: return 'Sun';
      default: return '';
    }
  }

  /// Helper to get month abbreviation (e.g., Jan, Feb).
  String _getMonthAbbreviation(int month) {
    switch (month) {
      case DateTime.january: return 'Jan';
      case DateTime.february: return 'Feb';
      case DateTime.march: return 'Mar';
      case DateTime.april: return 'Apr';
      case DateTime.may: return 'May';
      case DateTime.june: return 'Jun';
      case DateTime.july: return 'Jul';
      case DateTime.august: return 'Aug';
      case DateTime.september: return 'Sep';
      case DateTime.october: return 'Oct';
      case DateTime.november: return 'Nov';
      case DateTime.december: return 'Dec';
      default: return '';
    }
  }
}