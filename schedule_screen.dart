// lib/screens/schedule_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheduler_app/task.dart';
import 'package:scheduler_app/providers/task_provider.dart';
import 'dart:io'; // For Platform.isIOS
import 'package:flutter/cupertino.dart'; // For Cupertino widgets

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final TextEditingController _taskController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  // --- Date/Time Selection Methods (for new task input) ---
  // Adapted to show Cupertino pickers on iOS
  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate;
    if (Platform.isIOS) {
      // Show Cupertino Date Picker for iOS
      await showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 250,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _selectedDate ?? DateTime.now(),
                    minimumDate: DateTime(2000),
                    maximumDate: DateTime(2101),
                    onDateTimeChanged: (DateTime newDate) {
                      pickedDate = newDate;
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Show Material Date Picker for Android/others
      pickedDate = await showDatePicker(
        context: context,
        initialDate: _selectedDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
        helpText: 'Select Task Date',
        confirmText: 'SELECT',
        cancelText: 'CANCEL',
      );
    }

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // Adapted to show Cupertino pickers on iOS
  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? pickedTime;
    if (Platform.isIOS) {
      // Show Cupertino Time Picker for iOS
      await showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 250,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: DateTime(2000, 1, 1, _selectedTime?.hour ?? TimeOfDay.now().hour, _selectedTime?.minute ?? TimeOfDay.now().minute),
                    onDateTimeChanged: (DateTime newDateTime) {
                      pickedTime = TimeOfDay.fromDateTime(newDateTime);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Show Material Time Picker for Android/others
      pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedTime ?? TimeOfDay.now(),
        helpText: 'Select Task Time',
        confirmText: 'SELECT',
        cancelText: 'CANCEL',
      );
    }

    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  // --- Date/Time Picker Helper for Dialog (also adapted) ---
  Future<DateTime?> _pickDateForDialog(BuildContext context, DateTime? initialDate) async {
    if (Platform.isIOS) {
      DateTime? pickedDate;
      await showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 250,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate ?? DateTime.now(),
                    minimumDate: DateTime(2000),
                    maximumDate: DateTime(2101),
                    onDateTimeChanged: (DateTime newDate) {
                      pickedDate = newDate;
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
      return pickedDate;
    } else {
      return await showDatePicker(
        context: context,
        initialDate: initialDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
    }
  }

  Future<TimeOfDay?> _pickTimeForDialog(BuildContext context, TimeOfDay? initialTime) async {
    if (Platform.isIOS) {
      TimeOfDay? pickedTime;
      await showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 250,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: DateTime(2000, 1, 1, initialTime?.hour ?? TimeOfDay.now().hour, initialTime?.minute ?? TimeOfDay.now().minute),
                    onDateTimeChanged: (DateTime newDateTime) {
                      pickedTime = TimeOfDay.fromDateTime(newDateTime);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
      return pickedTime;
    } else {
      return await showTimePicker(
        context: context,
        initialTime: initialTime ?? TimeOfDay.now(),
      );
    }
  }


  // --- Adaptive Dialogs ---
  // _confirmRemoveTask (modified to use adaptive dialog)
  Future<bool> _confirmRemoveTask(int index) async {
    final taskTitle = context.read<TaskProvider>().tasks[index].title;
    final bool confirm = await (Platform.isIOS
        ? showCupertinoDialog( // Cupertino dialog for iOS
            context: context,
            builder: (BuildContext context) {
              return CupertinoAlertDialog(
                title: const Text('Confirm Deletion'),
                content: Text('Are you sure you want to delete "$taskTitle"?'),
                actions: <Widget>[
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(context).pop(true),
                    isDestructiveAction: true, // Red text for destructive action
                    child: const Text('Delete'),
                  ),
                ],
              );
            },
          )
        : showDialog( // Material dialog for Android/others
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Confirm Deletion'),
                content: Text('Are you sure you want to delete "$taskTitle"?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              );
            },
          )) ??
        false;

    if (confirm) {
      // ignore: use_build_context_synchronously
      context.read<TaskProvider>().removeTask(index);
    }
    return confirm;
  }

  // _showTaskDetailsDialog (modified to use adaptive dialog)
  Future<void> _showTaskDetailsDialog(Task task, int originalIndex, TaskProvider taskProvider) async {
    final TextEditingController titleController = TextEditingController(text: task.title);
    DateTime? dialogSelectedDate = task.scheduledDate;
    TimeOfDay? dialogSelectedTime = task.scheduledTime;
    bool dialogIsCompleted = task.isCompleted;

    await (Platform.isIOS
        ? showCupertinoDialog( // Cupertino dialog for iOS
            context: context,
            builder: (BuildContext dialogContext) {
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setDialogState) {
                  return CupertinoAlertDialog( // Cupertino style
                    title: const Text('Edit Task'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoTextField( // Cupertino TextField
                          controller: titleController,
                          placeholder: 'Task Title',
                          decoration: BoxDecoration(
                            border: Border.all(color: CupertinoColors.lightBackgroundGray),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Date and Time fields adapted for Cupertino
                        _buildCupertinoDateTimePickers(context, setDialogState, dialogSelectedDate, dialogSelectedTime, (date) => dialogSelectedDate = date, (time) => dialogSelectedTime = time),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center, // Center the checkbox
                          children: [
                            CupertinoSwitch( // Cupertino Switch
                              value: dialogIsCompleted,
                              onChanged: (bool value) {
                                setDialogState(() {
                                  dialogIsCompleted = value;
                                });
                              },
                              activeColor: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text('Mark as Completed'),
                          ],
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      CupertinoDialogAction(
                        onPressed: () {
                          if (titleController.text.trim().isNotEmpty) {
                            final updatedTask = Task(
                              title: titleController.text.trim(),
                              scheduledDate: dialogSelectedDate,
                              scheduledTime: dialogSelectedTime,
                              isCompleted: dialogIsCompleted,
                            );
                            taskProvider.updateTask(originalIndex, updatedTask);
                            Navigator.of(context).pop();
                          } else {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(
                                 content: Text('Task title cannot be empty!'),
                                 duration: Duration(seconds: 1),
                                 backgroundColor: Colors.orange,
                               ),
                             );
                          }
                        },
                        child: const Text('Save Changes'),
                      ),
                    ],
                  );
                },
              );
            },
          )
        : showDialog( // Material dialog for Android/others
            context: context,
            builder: (BuildContext dialogContext) {
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setDialogState) {
                  return AlertDialog(
                    title: const Text('Edit Task'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              labelText: 'Task Title',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final picked = await _pickDateForDialog(context, dialogSelectedDate);
                                    if (picked != null) {
                                      setDialogState(() {
                                        dialogSelectedDate = picked;
                                      });
                                    }
                                  },
                                  child: AbsorbPointer(
                                    child: TextField(
                                      controller: TextEditingController(
                                        text: Task(title: '', scheduledDate: dialogSelectedDate).formattedDate,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Date',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.calendar_today),
                                        suffixIcon: dialogSelectedDate != null ? IconButton(
                                          icon: const Icon(Icons.clear, size: 20),
                                          onPressed: () {
                                            setDialogState(() {
                                              dialogSelectedDate = null;
                                            });
                                          },
                                        ) : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final picked = await _pickTimeForDialog(context, dialogSelectedTime);
                                    if (picked != null) {
                                      setDialogState(() {
                                        dialogSelectedTime = picked;
                                      });
                                    }
                                  },
                                  child: AbsorbPointer(
                                    child: TextField(
                                      controller: TextEditingController(
                                        text: Task(title: '', scheduledTime: dialogSelectedTime).formattedTime,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Time',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.access_time),
                                        suffixIcon: dialogSelectedTime != null ? IconButton(
                                          icon: const Icon(Icons.clear, size: 20),
                                          onPressed: () {
                                            setDialogState(() {
                                              dialogSelectedTime = null;
                                            });
                                          },
                                        ) : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Checkbox(
                                value: dialogIsCompleted,
                                onChanged: (bool? value) {
                                  setDialogState(() {
                                    dialogIsCompleted = value ?? false;
                                  });
                                },
                                activeColor: Theme.of(context).primaryColor,
                              ),
                              const Text('Mark as Completed'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (titleController.text.trim().isNotEmpty) {
                            final updatedTask = Task(
                              title: titleController.text.trim(),
                              scheduledDate: dialogSelectedDate,
                              scheduledTime: dialogSelectedTime,
                              isCompleted: dialogIsCompleted,
                            );
                            taskProvider.updateTask(originalIndex, updatedTask);
                            Navigator.of(context).pop();
                          } else {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(
                                 content: Text('Task title cannot be empty!'),
                                 duration: Duration(seconds: 1),
                                 backgroundColor: Colors.orange,
                               ),
                             );
                          }
                        },
                        child: const Text('Save Changes'),
                      ),
                    ],
                  );
                },
              );
            },
          )) ??
        false;

    titleController.dispose();
  }

  // NEW Helper: Builds platform-adaptive date/time input fields for dialog
  Widget _buildCupertinoDateTimePickers(
    BuildContext context,
    StateSetter setDialogState,
    DateTime? dialogSelectedDate,
    TimeOfDay? dialogSelectedTime,
    Function(DateTime?) onDateChanged,
    Function(TimeOfDay?) onTimeChanged,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            final picked = await _pickDateForDialog(context, dialogSelectedDate);
            if (picked != null) {
              setDialogState(() {
                onDateChanged(picked);
              });
            }
          },
          child: AbsorbPointer(
            child: CupertinoTextField( // Cupertino TextField
              placeholder: 'Select Date',
              controller: TextEditingController(
                text: Task(title: '', scheduledDate: dialogSelectedDate).formattedDate,
              ),
              readOnly: true, // Make it read-only for tap
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.lightBackgroundGray),
                borderRadius: BorderRadius.circular(5.0),
              ),
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(CupertinoIcons.calendar), // Cupertino icon
              ),
              suffix: dialogSelectedDate != null
                  ? CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.clear_circled_solid, size: 20),
                      onPressed: () {
                        setDialogState(() {
                          onDateChanged(null);
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final picked = await _pickTimeForDialog(context, dialogSelectedTime);
            if (picked != null) {
              setDialogState(() {
                onTimeChanged(picked);
              });
            }
          },
          child: AbsorbPointer(
            child: CupertinoTextField( // Cupertino TextField
              placeholder: 'Select Time',
              controller: TextEditingController(
                text: Task(title: '', scheduledTime: dialogSelectedTime).formattedTime,
              ),
              readOnly: true, // Make it read-only for tap
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.lightBackgroundGray),
                borderRadius: BorderRadius.circular(5.0),
              ),
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(CupertinoIcons.time), // Cupertino icon
              ),
              suffix: dialogSelectedTime != null
                  ? CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.clear_circled_solid, size: 20),
                      onPressed: () {
                        setDialogState(() {
                          onTimeChanged(null);
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (rest of build method is largely unchanged, but uses the adaptive elements) ...
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = taskProvider.tasks;
        final isLoadingTasks = taskProvider.isLoadingTasks;
        final groupedTasks = taskProvider.groupedTasks;
        final sortedHeaders = taskProvider.sortedHeaders;

        // Define _addTask here (now calls provider)
        void _addTask() {
          if (_taskController.text.trim().isNotEmpty) {
            taskProvider.addTask(
              Task(
                title: _taskController.text.trim(),
                scheduledDate: _selectedDate,
                scheduledTime: _selectedTime,
              ),
            );
            _taskController.clear();
            setState(() { // setState for local UI state (input fields)
              _selectedDate = null;
              _selectedTime = null;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Task title cannot be empty!'),
                duration: Duration(seconds: 1),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        // Define _toggleTaskCompletion here (now calls provider)
        void _toggleTaskCompletion(int index, bool? value) {
          taskProvider.toggleTaskCompletion(index, value); // Call provider's toggle method
        }

        return Column(
          children: <Widget>[
            // ... (Input Section is mostly unchanged, uses regular Material widgets,
            // but the date/time pickers are now adaptive via _selectDate/_selectTime) ...
            Card(
              margin: const EdgeInsets.all(16.0),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Task',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _taskController,
                      decoration: InputDecoration(
                        labelText: 'Task Title',
                        hintText: 'e.g., Study Flutter, Call Mom',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: const Icon(Icons.edit_note),
                      ),
                      onSubmitted: (_) => _addTask(),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: Tooltip(
                            message: _selectedDate?.formattedDate ?? 'Tap to select date',
                            child: GestureDetector(
                              onTap: () => _selectDate(context),
                              child: AbsorbPointer(
                                child: TextField(
                                  controller: TextEditingController(
                                    text: _selectedDate?.formattedDate ?? 'Select Date',
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Date',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                                    prefixIcon: const Icon(Icons.calendar_today),
                                    suffixIcon: _selectedDate != null ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _selectedDate = null;
                                        });
                                      },
                                    ) : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Tooltip(
                            message: _selectedTime?.formattedTime ?? 'Tap to select time',
                            child: GestureDetector(
                              onTap: () => _selectTime(context),
                              child: AbsorbPointer(
                                child: TextField(
                                  controller: TextEditingController(
                                    text: _selectedTime?.formattedTime ?? 'Select Time',
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Time',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                                    prefixIcon: const Icon(Icons.access_time),
                                    suffixIcon: _selectedTime != null ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _selectedTime = null;
                                        });
                                      },
                                    ) : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addTask,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Task'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: isLoadingTasks
                  ? const Center(child: CircularProgressIndicator.adaptive())
                  : tasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.checklist, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 10),
                              Text(
                                'Your schedule is clear!',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Add your first task above.',
                                style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: sortedHeaders.length,
                          itemBuilder: (context, headerIndex) {
                            final header = sortedHeaders[headerIndex];
                            final tasksInGroup = groupedTasks[header]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  child: Text(
                                    header,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: tasksInGroup.length,
                                  separatorBuilder: (context, index) => const Divider(
                                    indent: 20,
                                    endIndent: 20,
                                    height: 1,
                                  ),
                                  itemBuilder: (context, taskIndex) {
                                    final task = tasksInGroup[taskIndex];
                                    final originalIndex = tasks.indexOf(task);

                                    return Dismissible(
                                      key: Key(task.title + task.hashCode.toString()),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        color: Colors.red,
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        child: const Icon(Icons.delete, color: Colors.white),
                                      ),
                                      confirmDismiss: (direction) async {
                                        return await _confirmRemoveTask(originalIndex);
                                      },
                                      onDismissed: (direction) {
                                        // Task is already removed by _confirmRemoveTask if confirmed
                                      },
                                      child: Card(
                                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        elevation: 1,
                                        color: task.isCompleted ? Colors.green[50] : Theme.of(context).cardColor,
                                        child: ListTile(
                                          leading: Checkbox(
                                            value: task.isCompleted,
                                            onChanged: (bool? value) {
                                              _toggleTaskCompletion(originalIndex, value);
                                            },
                                            activeColor: Theme.of(context).primaryColor,
                                          ),
                                          title: Text(
                                            task.title,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                                              color: task.isCompleted ? Colors.grey[600] : Colors.black,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${task.formattedDate} ${task.formattedTime}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: task.isCompleted ? Colors.grey[500] : Colors.grey[700],
                                              decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                                            ),
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                            onPressed: () => _confirmRemoveTask(originalIndex),
                                          ),
                                          onTap: () {
                                            _showTaskDetailsDialog(task, originalIndex, taskProvider);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}