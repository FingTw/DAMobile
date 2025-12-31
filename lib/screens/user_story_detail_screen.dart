import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled3/models/user_story_model.dart';
import 'package:untitled3/services/database_service.dart';

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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  // Cập nhật Status
  void _updateStatus() {
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
            children: [
              Text(
                "Chọn trạng thái",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Backlog
              ListTile(
                title: const Text("Backlog"),
                onTap: () {
                  DatabaseService().updateUserStory(
                    widget.projectId,
                    widget.story.id,
                    status: UserStoryStatus.backlog,
                  );
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
              // Done
              ListTile(
                title: const Text("Done"), // Hoặc trạng thái khác nếu có
                onTap: () {
                  DatabaseService().updateUserStory(
                    widget.projectId,
                    widget.story.id,
                    status: UserStoryStatus.done,
                  );
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
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
            // Title
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

            // Points & Status Row
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
                  onTap: _updateStatus,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      widget.story.status
                          .toString()
                          .split('.')
                          .last
                          .toUpperCase(),
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

            // Description
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
