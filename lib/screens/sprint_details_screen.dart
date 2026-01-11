import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:intl/intl.dart';
import 'package:untitled3/models/project_model.dart';
import 'package:untitled3/models/sprint_model.dart';
import 'package:untitled3/models/user_story_model.dart';
import 'package:untitled3/models/project_task_model.dart';
import 'package:untitled3/screens/user_story_detail_screen.dart';
import 'package:untitled3/screens/retrospective_screen.dart';
import 'package:untitled3/screens/daily_standup_screen.dart';
import 'package:untitled3/models/user_model.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/services/toast_service.dart';
import 'package:untitled3/widgets/custom_notification_widget.dart';
import 'package:untitled3/widgets/countdown_timer_widget.dart';

class SprintDetailsScreen extends StatefulWidget {
  final Project project;
  final Sprint sprint;
  const SprintDetailsScreen({
    super.key,
    required this.project,
    required this.sprint,
  });

  @override
  State<SprintDetailsScreen> createState() => _SprintDetailsScreenState();
}

class _SprintDetailsScreenState extends State<SprintDetailsScreen> {
  late Future<List<UserModel>> _projectMembers;

  @override
  void initState() {
    super.initState();
    _projectMembers = DatabaseService().getProjectMembers(
      widget.project.members.keys.toList(),
    );
    // Auto-check and update sprint status
    _checkSprintStatus();
  }

  Future<void> _checkSprintStatus() async {
    await DatabaseService().checkAndUpdateSprintStatuses(widget.project.id);
  }

  void _navigateToTaskDetail(BuildContext context, ProjectTask task) {
    // Tìm User Story của task này
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StreamBuilder<List<UserStory>>(
          stream: DatabaseService().getStoriesForSprint(
            widget.project.id,
            widget.sprint.id,
          ),
          builder: (context, storySnapshot) {
            if (!storySnapshot.hasData) {
              return Scaffold(
                appBar: AppBar(title: const Text('Loading...')),
                body: const Center(child: CircularProgressIndicator()),
              );
            }
            final story = storySnapshot.data!.firstWhere(
              (s) => s.id == task.storyId,
              orElse: () => UserStory(
                id: '',
                projectId: widget.project.id,
                title: 'Unknown Story',
              ),
            );
            if (story.id.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Story not found')),
              );
            }
            return UserStoryDetailScreen(
              story: story,
              projectId: widget.project.id,
            );
          },
        ),
      ),
    );
  }

  void _onProjectTaskReorder(
    int oldItemIndex,
    int oldListIndex,
    int newItemIndex,
    int newListIndex,
    List<DragAndDropList> contents,
    List<ProjectTask> allTasks,
  ) {
    if (oldListIndex == newListIndex && oldItemIndex == newItemIndex) return;

    // Get the task being moved
    final item = contents[oldListIndex].children[oldItemIndex];
    final taskCard = item.child as _ProjectTaskCard;
    final task = taskCard.task;

    // Determine new status based on newListIndex
    ProjectTaskStatus newStatus;
    switch (newListIndex) {
      case 0:
        newStatus = ProjectTaskStatus.todo;
        break;
      case 1:
        newStatus = ProjectTaskStatus.inProgress;
        break;
      case 2:
        newStatus = ProjectTaskStatus.done;
        break;
      case 3:
        newStatus = ProjectTaskStatus.verified;
        break;
      default:
        newStatus = ProjectTaskStatus.todo;
    }

    if ((newStatus == ProjectTaskStatus.done ||
            newStatus == ProjectTaskStatus.verified) &&
        !task.isDoDComplete) {
      ToastService.show(
        title: "DoD Incomplete",
        message:
            "Please complete the Definition of Done checklist for this task.",
        type: NotificationType.warning,
      );
    }

    DatabaseService().updateProjectTaskStatus(task.id, newStatus);

    ToastService.show(
      title: "Task Updated",
      message: "Moved to ${newStatus.toString().split('.').last.toUpperCase()}",
      type: NotificationType.success,
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    String? selectedStoryId;
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
          child: StreamBuilder<List<UserStory>>(
            stream: DatabaseService().getStoriesForSprint(
              widget.project.id,
              widget.sprint.id,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final stories = snapshot.data!;
              if (stories.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text("Vui lòng thêm User Story vào Sprint trước."),
                );
              }

              return FutureBuilder<List<UserModel>>(
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
                              "Tạo hạng mục công việc",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: "Chọn User Story *",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              value: selectedStoryId,
                              items: stories
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s.id,
                                      child: Text(s.title),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => selectedStoryId = v),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: titleController,
                              decoration: InputDecoration(
                                labelText: "Tên công việc *",
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
                                  initialDate:
                                      selectedStartDate ?? DateTime.now(),
                                  firstDate:
                                      selectedStartDate ?? DateTime.now(),
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  if (titleController.text.isNotEmpty &&
                                      selectedStoryId != null &&
                                      selectedAssigneeId != null &&
                                      selectedStartDate != null &&
                                      selectedDueDate != null &&
                                      selectedDueDate!.isAfter(
                                        selectedStartDate!,
                                      )) {
                                    final navigator = Navigator.of(context);
                                    DatabaseService().addProjectTask(
                                      widget.project.id,
                                      widget.sprint.id,
                                      selectedStoryId!,
                                      titleController.text,
                                      selectedStartDate!,
                                      selectedDueDate!,
                                      selectedAssigneeId!,
                                    );
                                    navigator.pop();
                                    ToastService.show(
                                      title: "Task Created",
                                      message:
                                          "New task added to the current sprint.",
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
                                child: const Text(
                                  "Tạo",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showCompleteSprintDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn thành Sprint?'),
        content: const Text(
          'Hành động này sẽ chuyển trạng thái Sprint thành Kết thúc (Completed) và kích hoạt tính năng Retrospective. Bạn không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              await DatabaseService().completeSprint(
                widget.project.id,
                widget.sprint.id,
              );
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to project details to refresh
                ToastService.show(
                  title: "Thành công",
                  message:
                      "Sprint đã hoàn thành và Task tồn đọng đã về Backlog!",
                  type: NotificationType.success,
                );
              }
            },
            child: const Text(
              'Hoàn thành',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.sprint.name,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
                fontSize: 18,
              ),
            ),
            Text(
              '${DateFormat('dd/MM/yyyy').format(widget.sprint.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.sprint.endDate)}',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.sprint.status == SprintStatus.inProgress) ...[
            IconButton(
              icon: const Icon(Icons.today, color: Color(0xFF10B981)),
              tooltip: 'Daily Standup',
              onPressed: () async {
                final members = await _projectMembers;
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DailyStandupScreen(
                        sprint: widget.sprint,
                        projectId: widget.project.id,
                        members: members,
                      ),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.blue),
              tooltip: 'Hoàn thành Sprint',
              onPressed: _showCompleteSprintDialog,
            ),
          ],
          if (widget.sprint.status == SprintStatus.completed)
            IconButton(
              icon: const Icon(Icons.feedback, color: Color(0xFF8B5CF6)),
              tooltip: 'Retrospective',
              onPressed: () async {
                final members = await _projectMembers;
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RetrospectiveScreen(
                        sprint: widget.sprint,
                        projectId: widget.project.id,
                        members: members,
                      ),
                    ),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            tooltip: 'Chế độ xem - Không thể chỉnh sửa',
            onPressed: () {
              ToastService.show(
                title: "Chế độ xem",
                message:
                    "Bạn đang ở chế độ xem. Vui lòng vào User Story để chỉnh sửa task.",
                type: NotificationType.info,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _projectMembers,
        builder: (context, membersSnapshot) {
          if (!membersSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final members = membersSnapshot.data!;

          return Column(
            children: [
              // Sprint Goal Banner
              if (widget.sprint.goal.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2563EB),
                        const Color(0xFF3B82F6),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flag, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Sprint Goal',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.sprint.goal,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.sprint.goalDescription.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.sprint.goalDescription,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Existing StreamBuilder
              Expanded(
                child: StreamBuilder<List<ProjectTask>>(
                  stream: DatabaseService().getProjectTasks(widget.sprint.id),
                  builder: (context, taskSnapshot) {
                    if (taskSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final tasks = taskSnapshot.data ?? [];

                    List<DragAndDropList> contents = [
                      _buildTaskList(
                        "TO DO",
                        tasks
                            .where((t) => t.status == ProjectTaskStatus.todo)
                            .toList(),
                        members,
                      ),
                      _buildTaskList(
                        "IN PROGRESS",
                        tasks
                            .where(
                              (t) => t.status == ProjectTaskStatus.inProgress,
                            )
                            .toList(),
                        members,
                      ),
                      _buildTaskList(
                        "DONE",
                        tasks
                            .where((t) => t.status == ProjectTaskStatus.done)
                            .toList(),
                        members,
                      ),
                      _buildTaskList(
                        "VERIFIED",
                        tasks
                            .where(
                              (t) => t.status == ProjectTaskStatus.verified,
                            )
                            .toList(),
                        members,
                      ),
                    ];

                    // Disable drag and drop - chỉ xem
                    return DragAndDropLists(
                      children: contents,
                      onItemReorder: (oldItem, oldList, newItem, newList) {
                        _onProjectTaskReorder(
                          oldItem,
                          oldList,
                          newItem,
                          newList,
                          contents,
                          tasks,
                        );
                      },
                      onListReorder: (int oldListIndex, int newListIndex) {
                        // Normally we don't reorder Scrum columns
                      },
                      listPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      listDecoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      listInnerDecoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      axis: Axis.horizontal,
                      listWidth: 300,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: "add_sprint_task_fab",
            backgroundColor: const Color(0xFF1F2937),
            onPressed: _showAddTaskDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'Thêm Task',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Text(
                  'Chế độ xem',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DragAndDropList _buildTaskList(
    String header,
    List<ProjectTask> tasks,
    List<UserModel> members,
  ) {
    Color headerColor;
    IconData headerIcon;

    switch (header) {
      case "TO DO":
        headerColor = Colors.grey.shade600;
        headerIcon = Icons.radio_button_unchecked;
        break;
      case "IN PROGRESS":
        headerColor = Colors.blue.shade600;
        headerIcon = Icons.refresh;
        break;
      case "DONE":
        headerColor = Colors.green.shade600;
        headerIcon = Icons.check_circle;
        break;
      case "VERIFIED":
        headerColor = Colors.purple.shade600;
        headerIcon = Icons.verified;
        break;
      default:
        headerColor = Colors.grey.shade600;
        headerIcon = Icons.list;
    }

    return DragAndDropList(
      header: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: headerColor.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(headerIcon, size: 18, color: headerColor),
                const SizedBox(width: 8),
                Text(
                  header,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: headerColor,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tasks.length.toString(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      children: tasks.map((task) {
        final assignee = members.firstWhere(
          (m) => m.uid == task.assigneeId,
          orElse: () => UserModel(uid: '', name: 'Unassigned', email: ''),
        );
        return DragAndDropItem(
          canDrag: true, // Re-enabled drag
          child: _ProjectTaskCard(
            task: task,
            assignee: assignee,
            onTap: () {
              // Navigate to User Story Detail để chỉnh sửa task
              _navigateToTaskDetail(context, task);
            },
          ),
        );
      }).toList(),
    );
  }
}

class _ProjectTaskCard extends StatelessWidget {
  final ProjectTask task;
  final UserModel assignee;
  final VoidCallback onTap;
  const _ProjectTaskCard({
    required this.task,
    required this.assignee,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task.isOverdue ? Colors.red.shade300 : Colors.grey.shade200,
            width: task.isOverdue ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: task.isOverdue
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Colors.grey,
                  ),
                  onSelected: (value) {
                    if (value == 'view') {
                      // Navigate to task detail
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Text('Xem chi tiết'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Assignee
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
                Expanded(
                  child: Text(
                    assignee.name,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
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
                            value: loadingProgress.expectedTotalBytes != null
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
          ],
        ),
      ),
    );
  }
}
