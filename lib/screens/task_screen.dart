
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:untitled3/models/task_model.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:collection/collection.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {

  void _showAddTaskDialog() {
    final TextEditingController titleController = TextEditingController();
    int selectedPriority = 1;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Add New Personal Task", style: GoogleFonts.poppins()),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Task Title'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  DropdownButton<int>(
                    value: selectedPriority,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('High Priority')),
                      DropdownMenuItem(value: 2, child: Text('Medium Priority')),
                      DropdownMenuItem(value: 3, child: Text('Low Priority')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedPriority = value!;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    DatabaseService(uid: user.uid).addPersonalTask(titleController.text, selectedPriority);
                  }
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please log in."));

    return Scaffold(
        backgroundColor: Colors.white,
        body: StreamBuilder<List<Task>>(
          stream: DatabaseService(uid: user.uid).personalTasks,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text("No personal tasks yet. Press '+' to add one!", style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16)),
              );
            }

            final tasks = snapshot.data!;

            final draftTasks = tasks.where((t) => t.status == TaskStatus.inProgress).toList();
            final doneTasks = tasks.where((t) => t.status == TaskStatus.done).toList();

            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
                          gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
                          boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                        ),
                        tabs: [
                          Tab(child: Text("In Progress", style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                          Tab(child: Text("Completed", style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTaskList(draftTasks, "No tasks in progress."),
                        _buildTaskList(doneTasks, "No completed tasks yet."),
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

  Widget _buildTaskList(List<Task> tasks, String emptyMessage) {
    if (tasks.isEmpty) {
      return Center(child: Text(emptyMessage, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16)));
    }

    final groupedTasks = groupBy(tasks, (Task task) => _getGroupTitle(task.createdAt));

    return ListView.builder(
      padding: const EdgeInsets.all(20.0),
      itemCount: groupedTasks.keys.length,
      itemBuilder: (context, index) {
        final String title = groupedTasks.keys.elementAt(index);
        final List<Task> tasksInGroup = groupedTasks[title]!;
        return _buildTaskSection(title, tasksInGroup);
      },
    );
  }

  Widget _buildTaskSection(String title, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 15.0, top: 10.0),
          child: Text(title, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        ...tasks.map((task) => _TaskListItem(task: task)).toList(),
        const SizedBox(height: 30),
      ],
    );
  }
}

class _TaskListItem extends StatelessWidget {
  final Task task;
  const _TaskListItem({required this.task});

  Color _getPriorityColor() {
    switch (task.priority) {
      case 1: return const Color(0xFF29B6F6);
      case 2: return const Color(0xFFAB47BC);
      case 3: return const Color(0xFFFF7043);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDone = task.status == TaskStatus.done;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          if (user != null) {
            final newStatus = isDone ? TaskStatus.inProgress : TaskStatus.done;
            DatabaseService(uid: user.uid).updatePersonalTaskStatus(task.id, newStatus);
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
                child: Text(
                  task.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                    color: isDone ? Colors.grey.shade500 : Colors.black87,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.grey.shade400),
                onPressed: () {
                  if (user != null) {
                    DatabaseService(uid: user.uid).deletePersonalTask(task.id);
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
