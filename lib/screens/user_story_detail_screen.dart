import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled3/models/user_story_model.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/services/toast_service.dart';
import 'package:untitled3/widgets/custom_notification_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.story.title);
    _descriptionController = TextEditingController(text: widget.story.description);
    _pointsController = TextEditingController(text: widget.story.points.toString());
    _currentStatus = widget.story.status;
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
        type: NotificationType.info);
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
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
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
          ],
        ),
      ),
    );
  }
}
