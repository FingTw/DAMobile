import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as storage;
import 'package:untitled3/models/task_model.dart' as tm;
import 'package:untitled3/data/repositories/task_repository.dart';
import 'package:collection/collection.dart';
import 'package:untitled3/services/toast_service.dart';
import 'package:untitled3/widgets/custom_notification_widget.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _uploadEvidence(BuildContext context, tm.Task task) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile == null) return;

    try {
      final ref = storage.FirebaseStorage.instance.ref(
        'task_evidence/${user.uid}/${task.id}.jpg',
      );
      await ref.putFile(File(pickedFile.path));
      final downloadUrl = await ref.getDownloadURL();

      await TaskRepository(
        uid: user.uid,
      ).updatePersonalTaskEvidence(task.id, downloadUrl);

      if (context.mounted) {
        ToastService.show(
          title: "Evidence Uploaded",
          message: "Image uploaded successfully",
          type: NotificationType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.show(
          title: "Upload Failed",
          message: "Failed to upload image: $e",
          type: NotificationType.error,
        );
      }
    }
  }

  void _showAddTaskDialog() {
    final TextEditingController titleController = TextEditingController();
    int selectedPriority = 1;
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Add New Personal Task",
                style: GoogleFonts.poppins(),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Title *',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      selectedDate == null
                          ? "Chọn hạn chót *"
                          : "Hạn: ${DateFormat('dd/MM/yyyy HH:mm').format(selectedDate!)}",
                    ),
                    trailing: const Icon(
                      Icons.calendar_today,
                      color: Colors.blue,
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        if (!context.mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                  if (selectedDate == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Vui lòng chọn hạn chót",
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  DropdownButton<int>(
                    value: selectedPriority,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('High Priority')),
                      DropdownMenuItem(
                        value: 2,
                        child: Text('Medium Priority'),
                      ),
                      DropdownMenuItem(value: 3, child: Text('Low Priority')),
                    ],
                    onChanged: (value) =>
                        setState(() => selectedPriority = value!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Add'),
                  onPressed: () {
                    if (titleController.text.isNotEmpty &&
                        selectedDate != null) {
                      final user = auth.FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        TaskRepository(uid: user.uid).addPersonalTask(
                          titleController.text,
                          selectedPriority,
                          selectedDate!,
                          user.uid,
                        );
                        ToastService.show(
                          title: "Task Added",
                          message: "Success",
                          type: NotificationType.success,
                        );
                        Navigator.of(context).pop();
                      }
                    } else {
                      ToastService.show(
                        title: "Missing Information",
                        message: "Please fill in all required fields",
                        type: NotificationType.warning,
                      );
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

  @override
  Widget build(BuildContext context) {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please log in."));

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<tm.Task>>(
        stream: TaskRepository(uid: user.uid).personalTasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No personal tasks yet. Press '+' to add one!",
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            );
          }

          final List<tm.Task> tasks = snapshot.data!;

          final todoTasks = tasks
              .where((t) => t.status == tm.TaskStatus.todo)
              .toList();
          final inProgressTasks = tasks
              .where((t) => t.status == tm.TaskStatus.inProgress)
              .toList();
          final doneTasks = tasks
              .where((t) => t.status == tm.TaskStatus.done)
              .toList();

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    child: TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.black,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(25.0),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      tabs: [
                        Tab(
                          child: Text(
                            "To Do",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Tab(
                          child: Text(
                            "In Progress",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Tab(
                          child: Text(
                            "Completed",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTaskList(
                        todoTasks,
                        "No tasks to do.",
                        _uploadEvidence,
                      ),
                      _buildTaskList(
                        inProgressTasks,
                        "No tasks in progress.",
                        _uploadEvidence,
                      ),
                      _buildTaskList(
                        doneTasks,
                        "No completed tasks yet.",
                        _uploadEvidence,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: const Color(0xFF4A00E0),
        elevation: 5,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _getGroupTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return "Today";
    } else if (taskDate == yesterday) {
      return "Yesterday";
    } else {
      return DateFormat.yMMMd().format(taskDate);
    }
  }

  Widget _buildTaskList(
    List<tm.Task> tasks,
    String emptyMessage,
    Future<void> Function(BuildContext, tm.Task) uploadEvidence,
  ) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    final sortedTasks = List<tm.Task>.from(tasks);
    sortedTasks.sort((a, b) {
      final now = DateTime.now();
      final aOverdue =
          a.dueDate != null &&
          a.dueDate!.isBefore(now) &&
          a.status != tm.TaskStatus.done;
      final bOverdue =
          b.dueDate != null &&
          b.dueDate!.isBefore(now) &&
          b.status != tm.TaskStatus.done;

      if (aOverdue && !bOverdue) return -1;
      if (!aOverdue && bOverdue) return 1;

      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      if (a.dueDate != null) return -1;
      if (b.dueDate != null) return 1;

      return a.createdAt.compareTo(b.createdAt);
    });

    final groupedTasks = groupBy(
      sortedTasks,
      (tm.Task task) => _getGroupTitle(task.createdAt),
    );

    return ListView.builder(
      padding: const EdgeInsets.all(20.0),
      itemCount: groupedTasks.keys.length,
      itemBuilder: (context, index) {
        final String title = groupedTasks.keys.elementAt(index);
        final List<tm.Task> tasksInGroup = groupedTasks[title]!;
        return _buildTaskSection(title, tasksInGroup, uploadEvidence);
      },
    );
  }

  Widget _buildTaskSection(
    String title,
    List<tm.Task> tasks,
    Future<void> Function(BuildContext, tm.Task) uploadEvidence,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 15.0, top: 10.0),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ...tasks.map(
          (task) => _TaskListItem(task: task, uploadEvidence: uploadEvidence),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

class _TaskListItem extends StatelessWidget {
  final tm.Task task;
  final Future<void> Function(BuildContext, tm.Task) uploadEvidence;
  const _TaskListItem({required this.task, required this.uploadEvidence});

  Color _getPriorityColor() {
    switch (task.priority) {
      case 1:
        return const Color(0xFF29B6F6);
      case 2:
        return const Color(0xFFAB47BC);
      case 3:
        return const Color(0xFFFF7043);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.FirebaseAuth.instance.currentUser;
    final isDone = task.status == tm.TaskStatus.done;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          if (user != null) {
            tm.TaskStatus newStatus;
            if (isDone) {
              newStatus = tm.TaskStatus.inProgress;
            } else if (task.status == tm.TaskStatus.todo) {
              newStatus = tm.TaskStatus.inProgress;
            } else {
              newStatus = tm.TaskStatus.done;
            }

            TaskRepository(
              uid: user.uid,
            ).updatePersonalTaskStatus(task.id, newStatus);

            if (newStatus == tm.TaskStatus.done) {
              ToastService.show(
                title: "Task Completed!",
                message: "'${task.title}' marked as done.",
                type: NotificationType.success,
              );
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 15.0),
          child: Row(
            children: [
              Icon(
                isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isDone ? Colors.green.shade400 : _getPriorityColor(),
                size: 26,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: isDone ? Colors.grey.shade500 : Colors.black87,
                      ),
                    ),
                    if (task.dueDate != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              task.dueDate!.isBefore(DateTime.now()) && !isDone
                              ? Colors.red.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color:
                                task.dueDate!.isBefore(DateTime.now()) &&
                                    !isDone
                                ? Colors.red
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color:
                                  task.dueDate!.isBefore(DateTime.now()) &&
                                      !isDone
                                  ? Colors.red
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(task.dueDate!),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight:
                                    task.dueDate!.isBefore(DateTime.now()) &&
                                        !isDone
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color:
                                    task.dueDate!.isBefore(DateTime.now()) &&
                                        !isDone
                                    ? Colors.red
                                    : Colors.grey.shade700,
                              ),
                            ),
                            if (task.dueDate!.isBefore(DateTime.now()) &&
                                !isDone) ...[
                              const SizedBox(width: 4),
                              Text(
                                "QUÁ HẠN",
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (isDone &&
                        task.evidenceLink != null &&
                        task.evidenceLink!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          task.evidenceLink!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.broken_image,
                                size: 30,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isDone &&
                  (task.evidenceLink == null || task.evidenceLink!.isEmpty))
                IconButton(
                  icon: Icon(Icons.camera_alt, color: Colors.blue.shade400),
                  onPressed: () => uploadEvidence(context, task),
                  tooltip: "Upload Evidence",
                ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.grey.shade400),
                onPressed: () {
                  if (user != null) {
                    TaskRepository(uid: user.uid).deletePersonalTask(task.id);
                    ToastService.show(
                      title: "Task Deleted",
                      message: "'${task.title}' has been removed.",
                      type: NotificationType.warning,
                    );
                  }
                },
                tooltip: "Delete Task",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
