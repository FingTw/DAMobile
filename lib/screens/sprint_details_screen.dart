
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:untitled3/models/project_model.dart';
import 'package:untitled3/models/sprint_model.dart';
import 'package:untitled3/models/user_story_model.dart';
import 'package:untitled3/models/project_task_model.dart';
import 'package:untitled3/models/user_model.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SprintDetailsScreen extends StatefulWidget {
  final Project project;
  final Sprint sprint;

  const SprintDetailsScreen({super.key, required this.project, required this.sprint});

  @override
  State<SprintDetailsScreen> createState() => _SprintDetailsScreenState();
}

class _SprintDetailsScreenState extends State<SprintDetailsScreen> {
  late Future<List<UserModel>> _projectMembers;

  @override
  void initState() {
    super.initState();
    _projectMembers = DatabaseService().getProjectMembers(widget.project.members);
  }

  void _onItemReorder(int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex, List<DragAndDropList> contents) {
    if (newListIndex >= 2) return;
    
    final db = DatabaseService();
    final taskCard = contents[oldListIndex].children[oldItemIndex].child as _TaskCard;
    final task = taskCard.task;

    ProjectTaskStatus newStatus = (newListIndex == 0) ? ProjectTaskStatus.todo : ProjectTaskStatus.inProgress;
    db.updateProjectTaskStatus(widget.project.id, widget.sprint.id, task.id, newStatus);
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    String? selectedStoryId;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: StreamBuilder<List<UserStory>>(
            stream: DatabaseService().getStoriesForSprint(widget.project.id, widget.sprint.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final stories = snapshot.data!;
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Task Title'), autofocus: true),
                      DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text("Select User Story"),
                        value: selectedStoryId,
                        items: stories.map((story) => DropdownMenuItem(value: story.id, child: Text(story.title))).toList(),
                        onChanged: (value) {
                           setState(() => selectedStoryId = value);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(onPressed: () {
              if (titleController.text.isNotEmpty && selectedStoryId != null) {
                DatabaseService().addProjectTask(widget.project.id, widget.sprint.id, selectedStoryId!, titleController.text);
                Navigator.of(context).pop();
              }
            }, child: const Text('Add')),
          ],
        );
      },
    );
  }

  void _showTaskDetailsDialog(ProjectTask task, List<UserModel> members) {
    final evidenceLinkController = TextEditingController(text: task.evidenceLink);
    final evidenceNotesController = TextEditingController(text: task.evidenceNotes);
    String? selectedAssigneeId = task.assigneeId.isNotEmpty ? task.assigneeId : null;
    final isOwner = widget.project.ownerId == FirebaseAuth.instance.currentUser?.uid;
    final isDone = task.status == ProjectTaskStatus.done;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(task.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Assign To:"),
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedAssigneeId,
                  hint: const Text("Unassigned"),
                  items: members.map((member) => DropdownMenuItem(value: member.uid, child: Text(member.name))).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      DatabaseService().updateTaskDetails(widget.project.id, widget.sprint.id, task.id, assigneeId: value, evidenceLink: evidenceLinkController.text, evidenceNotes: evidenceNotesController.text);
                    }
                  },
                ),
                const SizedBox(height: 20),
                const Text("Evidence Link (Git, URL, etc.):"),
                TextField(controller: evidenceLinkController, decoration: const InputDecoration(hintText: 'Paste link here...')),
                 const SizedBox(height: 20),
                const Text("Evidence Notes:"),
                TextField(controller: evidenceNotesController, decoration: const InputDecoration(hintText: 'Describe your work...'), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
            if (isDone && isOwner)
              ElevatedButton(
                onPressed: () {
                  DatabaseService().updateProjectTaskStatus(widget.project.id, widget.sprint.id, task.id, ProjectTaskStatus.verified);
                  Navigator.of(context).pop();
                },
                child: const Text("Verify & Close"),
              )
            else if (!isDone)
              ElevatedButton(
                onPressed: () {
                  if (evidenceLinkController.text.trim().isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide an evidence link.")));
                     return;
                  }
                  DatabaseService().submitTaskForReview(
                    widget.project.id, 
                    widget.sprint.id, 
                    task.id, 
                    evidenceLink: evidenceLinkController.text.trim(),
                    evidenceNotes: evidenceNotesController.text.trim(),
                  );
                  Navigator.of(context).pop();
                }, 
                child: const Text('Submit for Review')
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sprint.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _projectMembers,
        builder: (context, membersSnapshot) {
          if (!membersSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final members = membersSnapshot.data!;

          return StreamBuilder<List<ProjectTask>>(
            stream: DatabaseService().getTasksForSprint(widget.project.id, widget.sprint.id),
            builder: (context, taskSnapshot) {
              if (!taskSnapshot.hasData) return const Center(child: CircularProgressIndicator());
              final tasks = taskSnapshot.data!;

              List<DragAndDropList> contents = [
                _buildTaskList("To Do", tasks.where((t) => t.status == ProjectTaskStatus.todo).toList(), members),
                _buildTaskList("In Progress", tasks.where((t) => t.status == ProjectTaskStatus.inProgress).toList(), members),
                _buildTaskList("Done (Review)", tasks.where((t) => t.status == ProjectTaskStatus.done).toList(), members),
                _buildTaskList("Verified", tasks.where((t) => t.status == ProjectTaskStatus.verified).toList(), members),
              ];

              return DragAndDropLists(
                children: contents,
                onItemReorder: (oldItemIndex, oldListIndex, newItemIndex, newListIndex) => _onItemReorder(oldItemIndex, oldListIndex, newItemIndex, newListIndex, contents),
                onListReorder: (int oldListIndex, int newListIndex) {},
                listPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                listDecoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]),
                listInnerDecoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[200]),
                axis: Axis.horizontal,
                listWidth: 320, // FIX: Provide a finite width for each list
              );
            },
          );
        },
      ),
       floatingActionButton: FloatingActionButton(onPressed: _showAddTaskDialog, child: const Icon(Icons.add)),
    );
  }

  DragAndDropList _buildTaskList(String header, List<ProjectTask> tasks, List<UserModel> members) {
    return DragAndDropList(
      header: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(header, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      children: tasks.map((task) {
        final assignee = members.firstWhere((m) => m.uid == task.assigneeId, orElse: () => UserModel(uid: '', name: 'Unassigned', email: ''));
        return DragAndDropItem(child: _TaskCard(task: task, assignee: assignee, onTap: () => _showTaskDetailsDialog(task, members)));
      }).toList(),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final ProjectTask task;
  final UserModel assignee;
  final VoidCallback onTap;
  const _TaskCard({required this.task, required this.assignee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(radius: 12, backgroundImage: assignee.avatarUrl.isNotEmpty ? NetworkImage(assignee.avatarUrl) : null, child: assignee.avatarUrl.isEmpty ? const Icon(Icons.person, size: 14) : null),
                  const SizedBox(width: 8),
                  Expanded(child: Text(assignee.name, style: GoogleFonts.poppins(), overflow: TextOverflow.ellipsis)),
                  if(task.evidenceLink.isNotEmpty || task.evidenceNotes.isNotEmpty) 
                    const Icon(Icons.attachment, color: Colors.grey, size: 16)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
