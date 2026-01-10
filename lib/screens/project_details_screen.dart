import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled3/models/project_model.dart';
import 'package:untitled3/models/user_story_model.dart';
import 'package:untitled3/models/sprint_model.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/screens/sprint_details_screen.dart';
import 'package:untitled3/screens/member_management_screen.dart';
import 'package:untitled3/screens/user_story_detail_screen.dart';
import 'package:untitled3/screens/definition_of_done_screen.dart';
import 'package:untitled3/services/toast_service.dart';
import 'package:untitled3/widgets/custom_notification_widget.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;
  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _isLocked;
  late bool _isPastDeadline;

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool get amIPO => widget.project.ownerId == currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _updateLockState();
  }

  void _updateLockState() {
    _isPastDeadline =
        widget.project.deadline?.isBefore(DateTime.now()) ?? false;
    _isLocked = widget.project.isLocked || _isPastDeadline;
  }

  Future<void> _toggleProjectLock() async {
    final newLockState = !widget.project.isLocked;
    await DatabaseService().toggleProjectLock(widget.project.id, newLockState);
    ToastService.show(
      title: newLockState ? "Project Locked" : "Project Unlocked",
      message: newLockState
          ? "Members can no longer make changes."
          : "Members can now resume work.",
      type: newLockState ? NotificationType.warning : NotificationType.success,
    );
    if (mounted) {
      setState(() {
        _isLocked = newLockState || _isPastDeadline;
      });
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Project"),
        content: Text(
          "This will permanently delete '${widget.project.name}' and all its data. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await DatabaseService().deleteProject(widget.project.id);
              if (mounted) {
                navigator.pop(); // Close dialog
                navigator.pop(); // Go back from details screen
              }
              ToastService.show(
                title: "Project Deleted",
                message: "'${widget.project.name}' was successfully deleted.",
                type: NotificationType.error,
              );
            },
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
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLocked)
              const Icon(Icons.lock, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.project.name,
              style: GoogleFonts.inter(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.verified, color: Color(0xFF2563EB)),
            tooltip: 'Definition of Done',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DefinitionOfDoneScreen(project: widget.project),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemberManagementScreen(project: widget.project),
              ),
            ),
          ),
          if (amIPO)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'lock') _toggleProjectLock();
                if (value == 'delete') _showDeleteConfirmationDialog();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'lock',
                  child: Text(
                    widget.project.isLocked
                        ? "Re-open Project"
                        : "Mark as Completed",
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    "Delete Project",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB), // Blue 600
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF2563EB),
          tabs: const [
            Tab(text: 'Tóm tắt'),
            Tab(text: 'Bảng thông tin'), // Sprints
            Tab(text: 'Công việc'), // Backlog
          ],
        ),
      ),
      body: Column(
        children: [
          if (_isLocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              color: _isPastDeadline
                  ? Colors.red.shade700
                  : Colors.amber.shade700,
              child: Text(
                _isPastDeadline
                    ? "Project is past its deadline and is now archived."
                    : "This project is marked as completed and is now read-only.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SummaryTab(project: widget.project, isLocked: _isLocked),
                SprintsTab(project: widget.project, isLocked: _isLocked),
                BacklogTab(project: widget.project, isLocked: _isLocked),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SUMMARY TAB
// ---------------------------------------------------------------------------
class SummaryTab extends StatelessWidget {
  final Project project;
  final bool isLocked;
  const SummaryTab({super.key, required this.project, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // This would need a stateful parent to be interactive
          _buildDropdownFilter(),
          const SizedBox(height: 16),

          // This section should ideally be refactored to be cleaner
          // and handle loading/error states more gracefully.
          StreamBuilder<List<Sprint>>(
            stream: DatabaseService(uid: uid).getSprints(project.id),
            builder: (context, sprintSnapshot) {
              if (!sprintSnapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final sprints = sprintSnapshot.data!;
              final now = DateTime.now();
              final activeSprint = sprints.firstWhere(
                (s) => s.startDate.isBefore(now) && s.endDate.isAfter(now),
                orElse: () =>
                    Sprint(id: 'dummy', name: '', startDate: now, endDate: now),
              );

              if (activeSprint.id == 'dummy') {
                return Center(
                  child: Text(
                    "No active sprint",
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                );
              }

              return StreamBuilder<List<UserStory>>(
                // Assuming tasks are user stories now
                stream: DatabaseService(
                  uid: uid,
                ).getStoriesForSprint(project.id, activeSprint.id),
                builder: (context, storySnapshot) {
                  if (!storySnapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final stories = storySnapshot.data!;

                  int done = stories
                      .where((t) => t.status == UserStoryStatus.done)
                      .length;
                  int inProgress = stories
                      .where((t) => t.status == UserStoryStatus.inProgress)
                      .length;
                  int total = stories.length;

                  return Column(
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        childAspectRatio: 1.4,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStatCard(
                            icon: Icons.check,
                            iconColor: const Color(0xFF10B981),
                            bgColor: const Color(0xFFD1FAE5),
                            count: "$done done",
                            label: "in current sprint",
                            hasSparkle: true,
                          ),
                          _buildStatCard(
                            icon: Icons.edit,
                            iconColor: const Color(0xFF3B82F6),
                            bgColor: const Color(0xFFDBEAFE),
                            count: "$inProgress in progress",
                            label: "current active tasks",
                            hasSparkle: false,
                          ),
                          _buildStatCard(
                            icon: Icons.add,
                            iconColor: const Color(0xFF8B5CF6),
                            bgColor: const Color(0xFFEDE9FE), // Violet 100
                            count: "$total total",
                            label: "in current sprint",
                            hasSparkle: false,
                          ),
                          _buildStatCard(
                            icon: Icons.calendar_today,
                            iconColor: const Color(0xFFEF4444), // Red 500
                            bgColor: const Color(0xFFFEE2E2), // Red 100
                            count: DateFormat.MMMd().format(
                              activeSprint.endDate,
                            ),
                            label: "Sprint End Date",
                            hasSparkle: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildOverallStatusChart(stories),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatusChart(List<UserStory> stories) {
    int todo = stories
        .where(
          (t) =>
              t.status == UserStoryStatus.todo ||
              t.status == UserStoryStatus.inSprint,
        )
        .length;
    int inProgress = stories
        .where((t) => t.status == UserStoryStatus.inProgress)
        .length;
    int done = stories.where((t) => t.status == UserStoryStatus.done).length;
    int total = stories.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tổng quan về trạng thái",
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            "Sprint hiện tại",
            style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 60,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        color: const Color(0xFF34D399),
                        value: done.toDouble(),
                        radius: 25,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        color: const Color(0xFF3B82F6),
                        value: inProgress.toDouble(),
                        radius: 25,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        color: Colors.grey[200],
                        value: todo.toDouble(),
                        radius: 25,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$total",
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Hạng mục\ncông việc",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildLegendItem(const Color(0xFFE5E7EB), "To Do", "$todo"),
          const SizedBox(height: 12),
          _buildLegendItem(
            const Color(0xFF3B82F6),
            "In Progress",
            "$inProgress",
          ),
          const SizedBox(height: 12),
          _buildLegendItem(const Color(0xFF34D399), "Done", "$done"),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Người được chỉ định",
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[600]),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String count,
    required String label,
    required bool hasSparkle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  count,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: count.contains("due")
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF111827),
                  ),
                ),
              ),
              if (hasSparkle) const Text(" 🎉"),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// BACKLOG TAB
// ---------------------------------------------------------------------------
class BacklogTab extends StatefulWidget {
  final Project project;
  final bool isLocked;
  const BacklogTab({super.key, required this.project, required this.isLocked});
  @override
  State<BacklogTab> createState() => _BacklogTabState();
}

class _BacklogTabState extends State<BacklogTab> {
  Set<String> expandedGroups = {"Backlog"};

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchAndFilter(),
            const SizedBox(height: 16),

            StreamBuilder<List<Sprint>>(
              stream: DatabaseService(uid: uid).getSprints(widget.project.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final sprints = snapshot.data!;
                if (sprints.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: sprints.map((sprint) {
                    return StreamBuilder<List<UserStory>>(
                      stream: DatabaseService(
                        uid: uid,
                      ).getStoriesForSprint(widget.project.id, sprint.id),
                      builder: (context, storySnap) {
                        final stories = storySnap.data ?? [];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildSprintGroup(
                            sprint.name,
                            "${stories.length} stories",
                            stories,
                            true,
                            sprint.id,
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),

            StreamBuilder<List<UserStory>>(
              stream: DatabaseService(uid: uid).getBacklog(widget.project.id),
              builder: (context, snapshot) {
                final stories = snapshot.data ?? [];
                return _buildBacklogGroup(
                  "Backlog",
                  "${stories.length} hạng mục",
                  stories,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            enabled: !widget.isLocked,
            decoration: InputDecoration(
              icon: const Icon(Icons.search, color: Colors.grey),
              hintText: "Tìm kiếm hạng mục công việc",
              border: InputBorder.none,
              hintStyle: GoogleFonts.inter(fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildFilterChip("Trạng thái"),
            const SizedBox(width: 8),
            _buildFilterChip("Người được chỉ định"),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
          ),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildSprintGroup(
    String title,
    String subtitle,
    List<UserStory> stories,
    bool isSprint,
    String docId,
  ) {
    bool isExpanded = expandedGroups.contains(docId);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  expandedGroups.remove(docId);
                } else {
                  expandedGroups.add(docId);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _buildBadge(
                    "${stories.where((s) => s.status == UserStoryStatus.todo || s.status == UserStoryStatus.inSprint).length}",
                    Colors.grey[200]!,
                  ),
                  const SizedBox(width: 4),
                  _buildBadge(
                    "${stories.where((s) => s.status == UserStoryStatus.inProgress).length}",
                    Colors.blue[100]!,
                  ),
                  const SizedBox(width: 4),
                  _buildBadge(
                    "${stories.where((s) => s.status == UserStoryStatus.done).length}",
                    Colors.green[100]!,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.more_horiz, color: Colors.grey),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Column(
              children: [
                if (stories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "No stories",
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  ),
                ...stories.map<Widget>((s) => _buildStoryItem(s)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBacklogGroup(
    String title,
    String subtitle,
    List<UserStory> stories,
  ) {
    bool isExpanded = expandedGroups.contains('Backlog');
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  expandedGroups.remove('Backlog');
                } else {
                  expandedGroups.add('Backlog');
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _buildBadge("${stories.length}", Colors.grey[200]!),
                  const SizedBox(width: 8),
                  const Icon(Icons.more_horiz, color: Colors.grey),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Column(
              children: [
                if (stories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "Backlog empty",
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  ),
                ...stories.map((s) => _buildStoryItem(s)),
                const Divider(height: 1),
                if (!widget.isLocked) _buildCreateTaskButton(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(String txt, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        txt,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildStoryItem(UserStory story) {
    return InkWell(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.check_box_outline_blank, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(story.title, style: GoogleFonts.inter(fontSize: 15)),
                  Text(
                    "${story.points} pts",
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (!widget.isLocked)
              IconButton(
                icon: const Icon(Icons.input, size: 16, color: Colors.blue),
                onPressed: () => _showAddToSprintDialog(story),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTaskButton() {
    return InkWell(
      onTap: _showAddStoryDialog,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              "+ Tạo yêu cầu (Story)",
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddToSprintDialog(UserStory story) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add '${story.title}' to Sprint?",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<Sprint>>(
                  stream: DatabaseService(
                    uid: FirebaseAuth.instance.currentUser?.uid,
                  ).getSprints(widget.project.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text("No active sprints found."),
                      );
                    }
                    final sprints = snapshot.data!;
                    return ListView.builder(
                      itemCount: sprints.length,
                      itemBuilder: (context, index) {
                        final sprint = sprints[index];
                        return ListTile(
                          title: Text(sprint.name),
                          onTap: () async {
                            final navigator = Navigator.of(context);
                            await DatabaseService(
                              uid: FirebaseAuth.instance.currentUser?.uid,
                            ).addStoryToSprint(
                              widget.project.id,
                              sprint.id,
                              story.id,
                            );
                            if (mounted) navigator.pop();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddStoryDialog() {
    final titleController = TextEditingController();
    final pointsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "New Story",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pointsController,
              decoration: InputDecoration(
                labelText: "Points",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
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
                  if (titleController.text.isNotEmpty) {
                    DatabaseService(
                      uid: FirebaseAuth.instance.currentUser?.uid,
                    ).addUserStory(
                      widget.project.id,
                      titleController.text,
                      "",
                      int.tryParse(pointsController.text) ?? 0,
                    );
                    Navigator.pop(ctx);
                  }
                },
                child: const Text(
                  "Add",
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SPRINTS TAB
// ---------------------------------------------------------------------------
class SprintsTab extends StatefulWidget {
  final Project project;
  final bool isLocked;
  const SprintsTab({super.key, required this.project, required this.isLocked});
  @override
  State<SprintsTab> createState() => _SprintsTabState();
}

class _SprintsTabState extends State<SprintsTab> {
  Future<void> _showAddSprintDialog() async {
    final nameController = TextEditingController();
    final goalController = TextEditingController();
    final goalDescriptionController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 14));

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Create Sprint",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Sprint Name *",
                    hintText: "e.g., Sprint 1",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: goalController,
                  decoration: InputDecoration(
                    labelText: "Sprint Goal *",
                    hintText: "e.g., Complete user authentication",
                    prefixIcon: const Icon(Icons.flag),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: goalDescriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Goal Description",
                    hintText: "Detailed description of what we aim to achieve",
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2040),
                          );
                          if (d != null) setState(() => startDate = d);
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(DateFormat.yMMMd().format(startDate)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("-"),
                    ),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2040),
                          );
                          if (d != null) setState(() => endDate = d);
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(DateFormat.yMMMd().format(endDate)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      if (nameController.text.isNotEmpty &&
                          goalController.text.isNotEmpty) {
                        DatabaseService(
                          uid: FirebaseAuth.instance.currentUser?.uid,
                        ).addSprintWithGoal(
                          widget.project.id,
                          nameController.text,
                          startDate,
                          endDate,
                          goalController.text.trim(),
                          goalDescriptionController.text.trim(),
                        );
                        Navigator.pop(context);
                        ToastService.show(
                          title: "Sprint Created",
                          message:
                              "Sprint with goal has been created successfully",
                          type: NotificationType.success,
                        );
                      } else {
                        ToastService.show(
                          title: "Missing Information",
                          message: "Please fill in Sprint Name and Goal",
                          type: NotificationType.warning,
                        );
                      }
                    },
                    child: const Text(
                      "Create",
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
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: StreamBuilder<List<Sprint>>(
        stream: DatabaseService(
          uid: FirebaseAuth.instance.currentUser?.uid,
        ).getSprints(widget.project.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No sprints."));
          }
          final sprints = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sprints.length,
            itemBuilder: (context, index) {
              final sprint = sprints[index];
              final now = DateTime.now();
              final isActive =
                  sprint.startDate.isBefore(now) && sprint.endDate.isAfter(now);
              final isUpcoming = sprint.startDate.isAfter(now);
              final isCompleted = sprint.endDate.isBefore(now);

              return Card(
                elevation: isActive ? 4 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isActive ? Colors.blue : Colors.grey.shade300,
                    width: isActive ? 2 : 1,
                  ),
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: isActive
                      ? Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.blue,
                            size: 20,
                          ),
                        )
                      : null,
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          sprint.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.blue : Colors.black,
                          ),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "ACTIVE",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    "${DateFormat.MMMd().format(sprint.startDate)} - ${DateFormat.MMMd().format(sprint.endDate)}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!widget.isLocked && !isActive && !isCompleted)
                        IconButton(
                          icon: Icon(Icons.arrow_upward, size: 18),
                          onPressed: () {
                            // Increase priority (lower number = higher priority)
                            DatabaseService().updateSprintPriority(
                              sprint.id,
                              sprint.priority - 1,
                            );
                          },
                          tooltip: "Increase Priority",
                        ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    if (!widget.isLocked) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SprintDetailsScreen(
                            project: widget.project,
                            sprint: sprint,
                          ),
                        ),
                      );
                    } else {
                      ToastService.show(
                        title: "Project Locked",
                        message: "This project is read-only.",
                        type: NotificationType.info,
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.isLocked
          ? null
          : FloatingActionButton(
              heroTag: "add_sprint_fab",
              backgroundColor: const Color(0xFF1F2937),
              onPressed: _showAddSprintDialog,
              child: const Icon(Icons.add),
            ),
    );
  }
}
