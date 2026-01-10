import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:untitled3/models/project_model.dart';
import 'package:untitled3/models/sprint_model.dart';
import 'package:untitled3/models/user_story_model.dart';
import 'package:untitled3/screens/user_story_detail_screen.dart';
import 'package:untitled3/models/user_model.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/services/toast_service.dart';
import 'package:untitled3/widgets/custom_notification_widget.dart';

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
  }

  void _onItemReorder(
    int oldItemIndex,
    int oldListIndex,
    int newItemIndex,
    int newListIndex,
    List<DragAndDropList> contents,
  ) {
    if (oldListIndex == newListIndex && oldItemIndex == newItemIndex) return;

    final item = contents[oldListIndex].children[oldItemIndex];
    final storyCard = item.child as _StoryCard;
    final story = storyCard.story;

    UserStoryStatus newStatus;
    switch (newListIndex) {
      case 0:
        newStatus = UserStoryStatus.todo;
        break;
      case 1:
        newStatus = UserStoryStatus.inProgress;
        break;
      case 2:
        newStatus = UserStoryStatus.review;
        break;
      case 3:
        newStatus = UserStoryStatus.done;
        break;
      default:
        return;
    }

    if (story.status != newStatus) {
      DatabaseService().updateUserStory(
        widget.project.id,
        story.id,
        status: newStatus,
      );
      // Show notification on task completion
      if (newStatus == UserStoryStatus.done) {
        ToastService.show(
          title: "Story Completed!",
          message: "'${story.title}' moved to Done.",
          type: NotificationType.success,
        );
      }
    }
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    String? selectedStoryId;

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

              return StatefulBuilder(
                builder: (context, setState) {
                  return Column(
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
                          labelText: "Chọn User Story",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        // ignore: deprecated_member_use
                        value: selectedStoryId,
                        items: stories
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.title),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => selectedStoryId = v),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: "Tên công việc",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            if (titleController.text.isNotEmpty &&
                                selectedStoryId != null) {
                              final navigator = Navigator.of(context);
                              DatabaseService().addProjectTask(
                                widget.project.id,
                                widget.sprint.id,
                                selectedStoryId!,
                                titleController.text,
                                null,
                              );
                              navigator.pop();
                              ToastService.show(
                                title: "Task Created",
                                message:
                                    "New task added to the current sprint.",
                                type: NotificationType.success,
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
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          widget.sprint.name,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
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

          return StreamBuilder<List<UserStory>>(
            stream: DatabaseService().getStoriesForSprint(
              widget.project.id,
              widget.sprint.id,
            ),
            builder: (context, storySnapshot) {
              if (storySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final stories = storySnapshot.data ?? [];

              List<DragAndDropList> contents = [
                _buildTaskList(
                  "TO DO",
                  stories
                      .where(
                        (s) =>
                            s.status == UserStoryStatus.todo ||
                            s.status == UserStoryStatus.inSprint,
                      )
                      .toList(),
                  members,
                ),
                _buildTaskList(
                  "IN PROGRESS",
                  stories
                      .where((s) => s.status == UserStoryStatus.inProgress)
                      .toList(),
                  members,
                ),
                _buildTaskList(
                  "REVIEW",
                  stories
                      .where((s) => s.status == UserStoryStatus.review)
                      .toList(),
                  members,
                ),
                _buildTaskList(
                  "DONE",
                  stories
                      .where((s) => s.status == UserStoryStatus.done)
                      .toList(),
                  members,
                ),
              ];

              return DragAndDropLists(
                children: contents,
                onItemReorder:
                    (oldItemIndex, oldListIndex, newItemIndex, newListIndex) =>
                        _onItemReorder(
                          oldItemIndex,
                          oldListIndex,
                          newItemIndex,
                          newListIndex,
                          contents,
                        ),
                onListReorder: (int oldListIndex, int newListIndex) {},
                listPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                listDecoration: BoxDecoration(
                  color: Colors.transparent, // Transparent list background
                  borderRadius: BorderRadius.circular(8),
                ),
                listInnerDecoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB), // Very light grey for column
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                axis: Axis.horizontal,
                listWidth: 300,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "add_sprint_task_fab",
        backgroundColor: const Color(0xFF1F2937),
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  DragAndDropList _buildTaskList(
    String header,
    List<UserStory> stories,
    List<UserModel> members,
  ) {
    return DragAndDropList(
      header: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              header,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                stories.length.toString(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      children: stories.map((story) {
        // Find assignee logic if UserStory has assignee, current model does NOT support assignee on UserStory directly.
        // We will skip assignee for now or use "Unassigned" placeholder.
        // User said: "detail screen of userstory is task of sprint".

        return DragAndDropItem(
          child: _StoryCard(
            story: story,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserStoryDetailScreen(
                    story: story,
                    projectId: widget.project.id,
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final UserStory story;
  final VoidCallback onTap;
  const _StoryCard({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "${story.points} PTS",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const Icon(Icons.more_horiz, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              story.title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: const Color(0xFF111827),
              ),
            ),
            if (story.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                story.description,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
