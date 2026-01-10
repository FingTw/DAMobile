// HƯỚNG DẪN TÍCH HỢP NHANH CHO SPRINT DETAILS SCREEN
// Copy và paste code này vào sprint_details_screen.dart

// 1. THÊM IMPORTS (sau các imports hiện có):
import 'package:untitled3/screens/retrospective_screen.dart';
import 'package:untitled3/screens/daily_standup_screen.dart';

// 2. THÊM VÀO APPBAR ACTIONS (trong build method, AppBar widget):
// Tìm dòng: actions: [
// Thêm code này TRƯỚC các actions hiện có:

if (widget.sprint.status == SprintStatus.inProgress)
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

// 3. THÊM SPRINT GOAL BANNER (trong build method, sau AppBar):
// Tìm: body: StreamBuilder<List<ProjectTask>>(
// Thay bằng:

body: Column(
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
        // ... rest of existing code
      ),
    ),
  ],
),

// 4. CẬP NHẬT CREATE SPRINT DIALOG (trong project_details_screen.dart):
// Thêm controllers:
final _goalController = TextEditingController();
final _goalDescriptionController = TextEditingController();

// Thêm fields trong dialog:
TextField(
  controller: _goalController,
  decoration: InputDecoration(
    labelText: 'Sprint Goal *',
    hintText: 'e.g., Complete user authentication',
    prefixIcon: const Icon(Icons.flag),
  ),
),
const SizedBox(height: 16),
TextField(
  controller: _goalDescriptionController,
  maxLines: 2,
  decoration: InputDecoration(
    labelText: 'Goal Description',
    hintText: 'Detailed description of what we aim to achieve',
    prefixIcon: const Icon(Icons.description),
  ),
),

// Thay đổi save method:
// TÌM: await DatabaseService().addSprint(
// THAY BẰNG: await DatabaseService().addSprintWithGoal(
// VÀ THÊM 2 PARAMETERS:
_goalController.text.trim(),
_goalDescriptionController.text.trim(),

// VÍ DỤ:
await DatabaseService().addSprintWithGoal(
  widget.project.id,
  nameController.text,
  startDate!,
  endDate!,
  _goalController.text.trim(),
  _goalDescriptionController.text.trim(),
);
