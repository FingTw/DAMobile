import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled3/models/project_model.dart';
import 'package:untitled3/models/user_story_model.dart';
import 'package:untitled3/models/sprint_model.dart';
import 'package:untitled3/data/repositories/sprint_repository.dart';
import 'package:untitled3/data/repositories/user_story_repository.dart';
import 'package:untitled3/screens/sprint_details_screen.dart';
import 'package:untitled3/screens/member_management_screen.dart';
import 'package:untitled3/screens/user_story_detail_screen.dart';
import 'package:untitled3/screens/definition_of_done_screen.dart';
import 'package:untitled3/services/toast_service.dart';
import 'package:untitled3/widgets/custom_notification_widget.dart';
import 'package:untitled3/models/project_task_model.dart';
import 'package:untitled3/services/database_service.dart';

import '../services/database_service.dart';

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
  String get currentRole => widget.project.members[currentUserId] ?? 'Dev';
  bool get isPO =>
      currentRole == 'PO' || widget.project.ownerId == currentUserId;
  bool get isSM => currentRole == 'SM';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _isLocked = widget.project.isLocked;
    _isPastDeadline =
        widget.project.deadline != null &&
        widget.project.deadline!.isBefore(DateTime.now());
  }

  void _updateLockState() {
    DatabaseService().getProjectById(widget.project.id).then((updatedProject) {
      if (mounted && updatedProject != null) {
        setState(() {
          _isLocked = updatedProject.isLocked;
        });
      }
    });
  }

  void _toggleProjectLock() async {
    await DatabaseService().toggleProjectLock(widget.project.id, !_isLocked);
    setState(() {
      _isLocked = !_isLocked;
    });
    ToastService.show(
      title: _isLocked ? "Project Locked" : "Project Unlocked",
      message: _isLocked
          ? "Only viewing is allowed."
          : "Work can continue normally.",
      type: NotificationType.info,
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa dự án"),
        content: const Text(
          "Bạn có chắc chắn muốn xóa dự án này? Hành động này không thể hoàn tác.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseService().deleteProject(widget.project.id);
              if (mounted) {
                Navigator.pop(context); // Đóng dialog
                Navigator.pop(context); // Quay lại danh sách dự án
                ToastService.show(
                  title: "Đã xóa dự án",
                  message: "Dự án đã được loại bỏ vĩnh viễn.",
                  type: NotificationType.warning,
                );
              }
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
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
            icon: const Icon(Icons.people_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MemberManagementScreen(project: widget.project),
              ),
            ),
          ),
          if (isPO) // Only PO/Owner can manage DoD
            IconButton(
              icon: const Icon(Icons.verified, color: Color(0xFF2563EB)),
              tooltip: 'Definition of Done',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DefinitionOfDoneScreen(project: widget.project),
                ),
              ),
            ),
          if (isPO) // Only PO/Owner has project settings
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'lock') _toggleProjectLock();
                if (value == 'delete') _showDeleteConfirmationDialog();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'lock',
                  child: Row(
                    children: [
                      Icon(_isLocked ? Icons.lock_open : Icons.lock, size: 20),
                      const SizedBox(width: 8),
                      Text(_isLocked ? 'Mở khóa dự án' : 'Khóa dự án'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text('Xóa dự án', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: "Tóm tắt"),
            Tab(text: "Backlog"),
            Tab(text: "Sprints"),
            Tab(text: "Meetings"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SummaryTab(
            project: widget.project,
            isLocked: _isLocked,
            isPO: isPO,
            isSM: isSM,
            isPastDeadline: _isPastDeadline,
          ),
          BacklogTab(project: widget.project, isLocked: _isLocked, isPO: isPO),
          SprintsTab(
            project: widget.project,
            isLocked: _isLocked,
            isPO: isPO,
            isSM: isSM,
          ),
          _buildMeetingsTab(),
        ],
      ),
    );
  }

  Widget _buildMeetingsTab() {
    return const Center(child: Text("Meetings feature is coming soon!"));
  }
}

// ---------------------------------------------------------------------------
// SUMMARY TAB
// ---------------------------------------------------------------------------
class SummaryTab extends StatelessWidget {
  final Project project;
  final bool isLocked;
  final bool isPO;
  final bool isSM;
  final bool isPastDeadline;
  const SummaryTab({
    super.key,
    required this.project,
    required this.isLocked,
    required this.isPO,
    required this.isSM,
    required this.isPastDeadline,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<List<Sprint>>(
            stream: SprintRepository().getSprints(project.id),
            builder: (context, sprintSnapshot) {
              if (!sprintSnapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final sprints = sprintSnapshot.data!;
              final activeSprint = sprints.firstWhere(
                (s) =>
                    s.status == SprintStatus.inProgress, // Find ACTIVE sprint
                orElse: () => Sprint(
                  id: 'dummy',
                  name: '',
                  startDate: DateTime.now(),
                  endDate: DateTime.now(),
                ),
              );

              if (activeSprint.id == 'dummy') {
                return Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        "Không có Sprint nào đang chạy",
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return StreamBuilder<List<ProjectTask>>(
                stream: DatabaseService().getProjectTasks(activeSprint.id),
                builder: (context, taskSnapshot) {
                  if (!taskSnapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final tasks = taskSnapshot.data!;

                  int done = tasks
                      .where(
                        (t) =>
                            t.status == ProjectTaskStatus.done ||
                            t.status == ProjectTaskStatus.verified,
                      )
                      .length;
                  int inProgress = tasks
                      .where((t) => t.status == ProjectTaskStatus.inProgress)
                      .length;
                  int total = tasks.length;

                  return Column(
                    children: [
                      if (activeSprint.goal.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade600,
                                Colors.blue.shade400,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.flag,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Mục tiêu Sprint: ${activeSprint.name}",
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activeSprint.goal,
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

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
                            label: "active tasks",
                            hasSparkle: false,
                          ),
                          _buildStatCard(
                            icon: Icons.add,
                            iconColor: const Color(0xFF8B5CF6),
                            bgColor: const Color(0xFFEDE9FE),
                            count: "$total total",
                            label: "tasks in sprint",
                            hasSparkle: false,
                          ),
                          _buildStatCard(
                            icon: Icons.calendar_today,
                            iconColor: const Color(0xFFEF4444),
                            bgColor: const Color(0xFFFEE2E2),
                            count: DateFormat.MMMd().format(
                              activeSprint.endDate,
                            ),
                            label: "Sprint End Date",
                            hasSparkle: false,
                          ),
                        ],
                      ),

                      // HERE IS THE NEW SECTION
                      _buildActiveTasksList(tasks),

                      const SizedBox(height: 24),
                      _buildOverallStatusChart(tasks),
                      const SizedBox(height: 24),
                      _buildBurndownChart(activeSprint, tasks),
                      const SizedBox(height: 24),
                      Text(
                        "Số liệu thống kê",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.3,
                        children: [
                          _buildStatCard(
                            icon: Icons.check_circle,
                            iconColor: const Color(0xFF10B981),
                            bgColor: const Color(0xFFECFDF5),
                            count: tasks
                                .where((t) => t.isDoDComplete)
                                .length
                                .toString(),
                            label: "Tasks đạt DoD",
                            hasSparkle: false,
                          ),
                          _buildStatCard(
                            icon: Icons.warning,
                            iconColor: const Color(0xFFF59E0B),
                            bgColor: const Color(0xFFFFFBEB),
                            count: tasks
                                .where((t) => t.isOverdue)
                                .length
                                .toString(),
                            label: "Tasks quá hạn",
                            hasSparkle: false,
                          ),
                          _buildVelocityCard(sprints),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildBlockersSection(activeSprint.id),
                      const SizedBox(height: 24),
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

  Widget _buildActiveTasksList(List<ProjectTask> tasks) {
    final activeTasks = tasks
        .where((t) => t.status == ProjectTaskStatus.inProgress)
        .toList();

    if (activeTasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flash_on,
                color: Colors.blue.shade700,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Công việc đang thực hiện",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activeTasks.length,
          itemBuilder: (context, index) {
            final task = activeTasks[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (task.dueDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.orange.shade800,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd/MM').format(task.dueDate!),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVelocityCard(List<Sprint> sprints) {
    final completedSprints = sprints
        .where((s) => s.status == SprintStatus.completed)
        .toList();
    if (completedSprints.isEmpty) {
      return _buildStatCard(
        icon: Icons.speed,
        iconColor: Colors.grey,
        bgColor: Colors.grey.shade100,
        count: "0",
        label: "Vận tốc TB",
        hasSparkle: false,
      );
    }

    // This is a simplified velocity - in a real app, we'd sum story points of DONE stories in those sprints
    // For now, let's assume a placeholder or calculate if we had points data here.
    // Since we don't have all stories of all sprints in this context easily,
    // we'll show the number of completed sprints as a proxy or a "Coming Soon" metric.
    return _buildStatCard(
      icon: Icons.speed,
      iconColor: Colors.purple,
      bgColor: Colors.purple.shade50,
      count: "${completedSprints.length} Sprints",
      label: "Đã hoàn thành",
      hasSparkle: true,
    );
  }

  Widget _buildBlockersSection(String sprintId) {
    return StreamBuilder<List<String>>(
      stream: DatabaseService().getSprintBlockers(sprintId),
      builder: (context, snapshot) {
        final blockers = snapshot.data ?? [];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: blockers.isNotEmpty
                ? Border.all(color: Colors.red.shade200, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.report_problem,
                    color: blockers.isNotEmpty ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Trở ngại & Chặn (Blockers)",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: blockers.isNotEmpty
                          ? Colors.red.shade700
                          : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (blockers.isEmpty)
                Text(
                  "Hiện tại không có trở ngại nào được báo cáo.",
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                )
              else
                ...blockers.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            b,
                            style: GoogleFonts.inter(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverallStatusChart(List<ProjectTask> tasks) {
    int todo = tasks.where((t) => t.status == ProjectTaskStatus.todo).length;
    int inProgress = tasks
        .where((t) => t.status == ProjectTaskStatus.inProgress)
        .length;
    int done = tasks
        .where(
          (t) =>
              t.status == ProjectTaskStatus.done ||
              t.status == ProjectTaskStatus.verified,
        )
        .length;
    int total = tasks.length;

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              "Tổng quan về trạng thái",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Chưa có task nào trong sprint này",
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ],
        ),
      );
    }

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

  Widget _buildBurndownChart(Sprint sprint, List<ProjectTask> tasks) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    final totalTasks = tasks.length;
    final doneTasks = tasks
        .where(
          (t) =>
              t.status == ProjectTaskStatus.done ||
              t.status == ProjectTaskStatus.verified,
        )
        .length;
    final remainingTasks = totalTasks - doneTasks;

    final sprintDuration = sprint.endDate.difference(sprint.startDate).inDays;
    if (sprintDuration <= 0) return const SizedBox.shrink();

    // Calculate progress fraction
    final now = DateTime.now();
    final elapsedDays = now.difference(sprint.startDate).inDays;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Burn-down Chart",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Tiến độ hoàn thành Sprint",
                    style: GoogleFonts.inter(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${((doneTasks / totalTasks) * 100).toInt()}% Done",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (sprintDuration / 4).clamp(1, 14).toDouble(),
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "D${value.toInt()}",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (totalTasks / 4).clamp(1, 100).toDouble(),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: sprintDuration.toDouble(),
                minY: 0,
                maxY: totalTasks.toDouble(),
                lineBarsData: [
                  // Ideal Burn-down Line
                  LineChartBarData(
                    spots: [
                      FlSpot(0, totalTasks.toDouble()),
                      FlSpot(sprintDuration.toDouble(), 0),
                    ],
                    isCurved: false,
                    color: Colors.grey.withOpacity(0.3),
                    barWidth: 2,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                  ),
                  // Actual Burn-down Line (simplified)
                  LineChartBarData(
                    spots: [
                      FlSpot(0, totalTasks.toDouble()),
                      if (elapsedDays > 0)
                        FlSpot(
                          elapsedDays.toDouble().clamp(
                            0,
                            sprintDuration.toDouble(),
                          ),
                          remainingTasks.toDouble(),
                        ),
                    ],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChartLegendItem(
                Colors.grey.withOpacity(0.5),
                "Lý tưởng",
                true,
              ),
              const SizedBox(width: 24),
              _buildChartLegendItem(Colors.blue, "Thực tế", false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegendItem(Color color, String label, bool isDashed) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: isDashed ? null : color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: isDashed
              ? Row(
                  children: List.generate(
                    3,
                    (i) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        color: color,
                      ),
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
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
  final bool isPO;
  const BacklogTab({
    super.key,
    required this.project,
    required this.isLocked,
    required this.isPO,
  });

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
              stream: SprintRepository().getSprints(widget.project.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final sprints = snapshot.data!;
                if (sprints.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: sprints.map((sprint) {
                    return StreamBuilder<List<UserStory>>(
                      stream: UserStoryRepository().getStoriesForSprint(
                        widget.project.id,
                        sprint.id,
                      ),
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
              stream: UserStoryRepository().getBacklog(widget.project.id),
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
      floatingActionButton: (widget.isLocked || !widget.isPO)
          ? null
          : FloatingActionButton(
              heroTag: "add_story_fab",
              backgroundColor: const Color(0xFF1F2937),
              onPressed: _showAddStoryDialog,
              child: const Icon(Icons.add),
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
      ],
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
                  stream: SprintRepository().getSprints(widget.project.id),
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
                            await UserStoryRepository().addStoryToSprint(
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
                    UserStoryRepository().addUserStory(
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
  final bool isPO;
  final bool isSM;
  const SprintsTab({
    super.key,
    required this.project,
    required this.isLocked,
    required this.isPO,
    required this.isSM,
  });

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
                        SprintRepository().addSprintWithGoal(
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
        stream: SprintRepository().getSprints(widget.project.id),
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
              // Check active based on status, NOT date
              final hasActiveSprint = sprints.any(
                (s) => s.status == SprintStatus.inProgress,
              );
              final isActive = sprint.status == SprintStatus.inProgress;
              final isCompleted = sprint.status == SprintStatus.completed;
              final isUpcoming = sprint.status == SprintStatus.upcoming;

              return Card(
                elevation: isActive ? 4 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isActive ? Colors.green : Colors.grey.shade300,
                    width: isActive ? 2 : 1,
                  ),
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: isActive
                      ? Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons
                                .play_circle_fill, // Biểu tượng Play cho Sprint đang chạy
                            color: Colors.green,
                            size: 24,
                          ),
                        )
                      : (isCompleted
                            ? Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.radio_button_unchecked,
                                  color: Colors.blue.shade300,
                                  size: 20,
                                ),
                              )),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          sprint.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.green[700] : Colors.black,
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
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "ĐANG CHẠY",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      if (isUpcoming)
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
                            "SẮP TỚI",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${DateFormat.MMMd().format(sprint.startDate)} - ${DateFormat.MMMd().format(sprint.endDate)}",
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      if (sprint.goal.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            "Mục tiêu: ${sprint.goal}",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isUpcoming && !widget.isLocked)
                        IconButton(
                          icon: Icon(
                            Icons.play_circle_outline,
                            color: hasActiveSprint
                                ? Colors.grey[300]
                                : Colors.blue,
                            size: 28,
                          ),
                          tooltip: hasActiveSprint
                              ? "Hoàn thành Sprint hiện tại trước"
                              : "Bắt đầu Sprint",
                          onPressed: () {
                            if (!widget.isPO && !widget.isSM) {
                              ToastService.show(
                                title: "Không có quyền",
                                message:
                                    "Chỉ PO hoặc SM mới có thể bắt đầu Sprint.",
                                type: NotificationType.warning,
                              );
                              return;
                            }
                            if (hasActiveSprint) {
                              ToastService.show(
                                title: "Không thể bắt đầu",
                                message:
                                    "Đang có một Sprint khác đang chạy. Hãy hoàn thành nó trước.",
                                type: NotificationType.warning,
                              );
                            } else {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Bắt đầu Sprint?"),
                                  content: Text(
                                    "Bắt đầu thực hiện '${sprint.name}' ngay bây giờ?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("Hủy"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        DatabaseService().updateSprintStatus(
                                          sprint.id,
                                          SprintStatus.inProgress,
                                        );
                                        Navigator.pop(ctx);
                                        ToastService.show(
                                          title: "Sprint đã bắt đầu",
                                          message:
                                              "Chúc team làm việc hiệu quả!",
                                          type: NotificationType.success,
                                        );
                                      },
                                      child: const Text("Bắt đầu"),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),

                      const SizedBox(width: 8),
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
      floatingActionButton: (widget.isLocked || !widget.isPO)
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
