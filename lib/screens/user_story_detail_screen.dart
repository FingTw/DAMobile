import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled3/models/user_story_model.dart';
import 'package:untitled3/models/project_task_model.dart';
import 'package:untitled3/models/user_model.dart';
import 'package:untitled3/models/definition_of_done_model.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/services/toast_service.dart';
import 'package:untitled3/widgets/custom_notification_widget.dart';
import 'package:untitled3/widgets/countdown_timer_widget.dart';

class UserStoryDetailScreen extends StatefulWidget {
  final UserStory story;
  final String projectId;

  const UserStoryDetailScreen({
    super.key,
    required this.story,
    required this.projectId,
  });

  @override
  State<UserStoryDetailScreen> createState() => _UserStoryDetailScreenState();
}

class _UserStoryDetailScreenState extends State<UserStoryDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _pointsController;
  late UserStoryStatus _currentStatus;
  late Future<List<UserModel>> _projectMembers;
  bool _isPO = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.story.title);
    _descriptionController = TextEditingController(
      text: widget.story.description,
    );
    _pointsController = TextEditingController(
      text: widget.story.points.toString(),
    );
    _currentStatus = widget.story.status;
    // Get project members for task assignment
    _projectMembers = _getProjectMembers();
  }

  Future<List<UserModel>> _getProjectMembers() async {
    final project = await DatabaseService().getProjectById(widget.projectId);
    if (project == null) return [];

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final role = project.members[currentUser.uid];
      setState(() {
        _isPO = role == 'PO' || project.ownerId == currentUser.uid;
      });
    }

    return DatabaseService().getProjectMembers(project.members.keys.toList());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _updateStatus(UserStoryStatus newStatus) {
    DatabaseService().updateUserStory(
      widget.projectId,
      widget.story.id,
      status: newStatus,
    );
    setState(() {
      _currentStatus = newStatus;
    });
    Navigator.pop(context);
    ToastService.show(
      title: "Status Updated",
      message: "Story status changed to ${newStatus.name}.",
      type: NotificationType.info,
    );
  }

  void _showStatusMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Change Status",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ...UserStoryStatus.values.map((status) {
                return ListTile(
                  title: Text(status.name),
                  onTap: () => _updateStatus(status),
                  trailing: _currentStatus == status
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _saveChanges() {
    DatabaseService().updateUserStory(
      widget.projectId,
      widget.story.id,
      title: _titleController.text,
      description: _descriptionController.text,
      points: int.tryParse(_pointsController.text) ?? 0,
    );
    ToastService.show(
      title: "Story Saved",
      message: "Your changes have been saved successfully.",
      type: NotificationType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "User Story Detail",
          style: GoogleFonts.inter(color: Colors.black, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.blue),
            onPressed: () {
              _saveChanges();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Enter title",
              ),
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              maxLines: null,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40,
                        child: TextField(
                          controller: _pointsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text("Points", style: GoogleFonts.inter(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _showStatusMenu,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _currentStatus.name.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (_isPO && _currentStatus == UserStoryStatus.done) ...[
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _updateStatus(
                      UserStoryStatus.done,
                    ), // Keep as done but could be 'accepted'
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Accept Story"),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 30),
            Text(
              "Description",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: "Add a description...",
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                ),
                maxLines: null,
                minLines: 3,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tasks",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                StreamBuilder<List<ProjectTask>>(
                  stream: DatabaseService().getProjectTasksByStory(
                    widget.story.id,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty)
                      return const SizedBox.shrink();
                    final tasks = snapshot.data!;
                    final done = tasks
                        .where(
                          (t) =>
                              t.status == ProjectTaskStatus.done ||
                              t.status == ProjectTaskStatus.verified,
                        )
                        .length;
                    final progress = tasks.isEmpty ? 0.0 : done / tasks.length;
                    return Text(
                      "${(progress * 100).toInt()}% Hoàn thành",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<ProjectTask>>(
              stream: DatabaseService().getProjectTasksByStory(widget.story.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tasks = snapshot.data!;
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Text(
                          "Chưa có task nào",
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _showAddTaskDialog,
                          icon: const Icon(Icons.add),
                          label: const Text("Thêm Task"),
                        ),
                      ],
                    ),
                  );
                }
                final done = tasks
                    .where(
                      (t) =>
                          t.status == ProjectTaskStatus.done ||
                          t.status == ProjectTaskStatus.verified,
                    )
                    .length;
                final progress = tasks.isEmpty ? 0.0 : done / tasks.length;

                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...tasks.map((task) => _buildTaskCard(task)),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _showAddTaskDialog,
                      icon: const Icon(Icons.add),
                      label: const Text("Thêm Task"),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    String? selectedAssigneeId;
    DateTime? selectedStartDate;
    DateTime? selectedDueDate;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: FutureBuilder<List<UserModel>>(
            future: _projectMembers,
            builder: (context, membersSnapshot) {
              if (!membersSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final members = membersSnapshot.data!;

              return StatefulBuilder(
                builder: (context, setState) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Thêm Task vào User Story",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: "Tên task *",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "Chọn người thực hiện *",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          value: selectedAssigneeId,
                          items: members
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m.uid,
                                  child: Text(m.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => selectedAssigneeId = v),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            selectedStartDate == null
                                ? "Chọn thời gian bắt đầu *"
                                : "Bắt đầu: ${DateFormat('dd/MM/yyyy HH:mm').format(selectedStartDate!)}",
                          ),
                          trailing: const Icon(
                            Icons.play_circle_outline,
                            color: Colors.green,
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                setState(() {
                                  selectedStartDate = DateTime(
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
                        if (selectedStartDate == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "Vui lòng chọn thời gian bắt đầu",
                              style: GoogleFonts.inter(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            selectedDueDate == null
                                ? "Chọn hạn chót *"
                                : "Hạn: ${DateFormat('dd/MM/yyyy HH:mm').format(selectedDueDate!)}",
                          ),
                          trailing: const Icon(
                            Icons.calendar_today,
                            color: Colors.blue,
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedStartDate ?? DateTime.now(),
                              firstDate: selectedStartDate ?? DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                setState(() {
                                  selectedDueDate = DateTime(
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
                        if (selectedDueDate == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "Vui lòng chọn hạn chót",
                              style: GoogleFonts.inter(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (selectedStartDate != null &&
                            selectedDueDate != null &&
                            selectedDueDate!.isBefore(selectedStartDate!))
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "Hạn chót phải sau thời gian bắt đầu",
                              style: GoogleFonts.inter(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (titleController.text.isNotEmpty &&
                                  selectedAssigneeId != null &&
                                  selectedStartDate != null &&
                                  selectedDueDate != null &&
                                  selectedDueDate!.isAfter(
                                    selectedStartDate!,
                                  )) {
                                // Get sprint ID from story
                                final sprintId =
                                    widget.story.sprintId.isNotEmpty
                                    ? widget.story.sprintId
                                    : '';
                                DatabaseService().addProjectTask(
                                  widget.projectId,
                                  sprintId,
                                  widget.story.id,
                                  titleController.text,
                                  selectedStartDate!,
                                  selectedDueDate!,
                                  selectedAssigneeId!,
                                );
                                Navigator.pop(context);
                                ToastService.show(
                                  title: "Task Created",
                                  message: "New task added to user story.",
                                  type: NotificationType.success,
                                );
                              } else {
                                ToastService.show(
                                  title: "Missing Information",
                                  message:
                                      "Please fill in all required fields correctly",
                                  type: NotificationType.warning,
                                );
                              }
                            },
                            child: const Text("Tạo Task"),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(ProjectTask task) {
    return FutureBuilder<UserModel?>(
      future: task.assigneeId.isNotEmpty
          ? DatabaseService()
                .getProjectMembers([task.assigneeId])
                .then((list) => list.isNotEmpty ? list.first : null)
          : Future.value(null),
      builder: (context, assigneeSnapshot) {
        final assignee = assigneeSnapshot.data;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: task.isOverdue
                  ? Colors.red.shade300
                  : Colors.grey.shade200,
              width: task.isOverdue ? 1.5 : 1,
            ),
          ),
          elevation: task.isOverdue ? 2 : 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                    PopupMenuButton<ProjectTaskStatus>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      onSelected: (status) {
                        DatabaseService().updateProjectTaskStatus(
                          task.id,
                          status,
                        );
                      },
                      itemBuilder: (context) =>
                          ProjectTaskStatus.values.map((status) {
                            return PopupMenuItem(
                              value: status,
                              child: Text(status.toString().split('.').last),
                            );
                          }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Assignee
                if (assignee != null)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Người thực hiện: ${assignee.name}",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                // Start Date
                if (task.startDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.play_circle_outline,
                          size: 14,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Bắt đầu: ${DateFormat('dd/MM/yyyy HH:mm').format(task.startDate!)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
                // Due Date với Countdown
                if (task.dueDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: task.isOverdue
                              ? Colors.red.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.access_time,
                          size: 14,
                          color: task.isOverdue
                              ? Colors.red.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hạn: ${DateFormat('dd/MM/yyyy HH:mm').format(task.dueDate!)}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            CountdownTimerWidget(
                              dueDate: task.dueDate,
                              isOverdue: task.isOverdue,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                // Evidence Image
                if (task.status == ProjectTaskStatus.done &&
                    task.evidenceLink.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        task.evidenceLink,
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 120,
                            color: Colors.grey[300],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 30,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Không thể tải ảnh',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: double.infinity,
                            height: 120,
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
                  ),
                ],
                // Definition of Done Checklist
                StreamBuilder<DefinitionOfDone?>(
                  stream: DatabaseService().getDefinitionOfDone(
                    widget.projectId,
                  ),
                  builder: (context, dodSnapshot) {
                    if (!dodSnapshot.hasData ||
                        dodSnapshot.data == null ||
                        dodSnapshot.data!.items.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final dod = dodSnapshot.data!;
                    final checklist = task.dodChecklist;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Definition of Done',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: task.isDoDComplete
                                    ? Colors.green[100]
                                    : Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${task.dodCompletedCount}/${task.dodTotalCount}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: task.isDoDComplete
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: task.dodProgress,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(
                            task.isDoDComplete ? Colors.green : Colors.orange,
                          ),
                          minHeight: 4,
                        ),
                        const SizedBox(height: 12),
                        ...dod.items.map((item) {
                          final isChecked =
                              checklist[item.description] ?? false;

                          return InkWell(
                            onTap: () async {
                              final newChecklist = Map<String, bool>.from(
                                checklist,
                              );
                              newChecklist[item.description] = !isChecked;

                              await DatabaseService().updateTaskDoDChecklist(
                                task.id,
                                newChecklist,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: isChecked
                                          ? const Color(0xFF10B981)
                                          : Colors.white,
                                      border: Border.all(
                                        color: isChecked
                                            ? const Color(0xFF10B981)
                                            : Colors.grey[400]!,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: isChecked
                                        ? const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.description,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: isChecked
                                            ? Colors.grey[600]
                                            : const Color(0xFF1F2937),
                                        decoration: isChecked
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                  if (item.isMandatory)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Required',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
                // Upload evidence button
                if (task.status == ProjectTaskStatus.done &&
                    task.evidenceLink.isEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _uploadTaskEvidence(task),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Upload ảnh minh chứng'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadTaskEvidence(ProjectTask task) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile == null) return;

    try {
      final ref = FirebaseStorage.instance.ref('task_evidence/${task.id}.jpg');
      await ref.putFile(File(pickedFile.path));
      final downloadUrl = await ref.getDownloadURL();

      await DatabaseService().updateProjectTaskEvidence(
        task.id,
        downloadUrl,
        '',
      );

      if (mounted) {
        ToastService.show(
          title: "Evidence Uploaded",
          message: "Image uploaded successfully",
          type: NotificationType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        ToastService.show(
          title: "Upload Failed",
          message: "Failed to upload image: $e",
          type: NotificationType.error,
        );
      }
    }
  }
}
